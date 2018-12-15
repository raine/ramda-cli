require! ramda: {apply, is-nil, append, flip, type, replace, merge, map, join, for-each, split, head, pick-by, tap, pipe, concat, take, identity, is-empty, reverse, invoker, from-pairs, merge-all, path, reduce, obj-of, assoc-path, adjust, to-pairs}: R
require! stream: {PassThrough}
require! through2: through
require! {JSONStream, split2}
require! util: {inspect}
require! './utils': {is-thenable, take-lines, remove-extra-newlines}

debug = require 'debug' <| 'ramda-cli:stream'

reduce-stream = (fn, acc) -> through.obj do
    (chunk,, next) ->
        acc := fn acc, chunk
        next!
    (next) ->
        this.push acc
        next!

concat-stream = -> reduce-stream flip(append), []

unconcat-stream = -> through.obj (chunk,, next) ->
    switch type chunk
    | \Array    => for-each this~push, chunk
    | otherwise => this.push chunk
    next!

map-stream = (fun, on-error) -> through.obj (chunk,, next) ->
    push = (x) ~>
        # pushing a null would end the stream
        this.push x unless is-nil x
        next!
    val = try fun chunk
    catch then on-error e
    if is-thenable val then val.then push
    else push val

json-stringify-stream = (compact) ->
    indent = if not compact then 2 else void
    through.obj (data,, next) ->
        json = JSON.stringify data, null, indent
        this.push json + '\n'
        next!

debug-stream = (debug, opts, str) ->
    unless debug.enabled and opts.very-verbose
        return PassThrough {+object-mode}

    through.obj (chunk,, next) ->
        debug {"#str": chunk.to-string!}
        this.push chunk
        next!

append-buffer =
    (buf1, buf2) -> Buffer.concat([ buf1, buf2 ])

pipeline = (input, pipe-through) ->
    reduce ((acc, s) -> acc.pipe s),
           input,
           pipe-through.filter((!= undefined))

blank-obj-stream = ->
    PassThrough {+object-mode}
        ..end {}

csv-opts = (type, delimiter, headers) ->
    opts = { headers, include-end-row-delimiter: true, delimiter }
    switch type
    | \csv => opts
    | \tsv => opts <<< delimiter: '\t'

table-output-stream = (compact) ->
    require! './format-table'
    opts = {compact}
    through.obj (chunk,, next) ->
        this.push "#{format-table chunk, opts}\n"
        next!

inspect-stream = (depth) -> through.obj (chunk,, next) ->
    this.push (inspect chunk, colors: true, depth: depth) + '\n'
    next!

raw-output-stream = (compact) -> through.obj (chunk,, next) ->
    end = unless compact then "\n" else ''
    switch type chunk
    | \Array    => for-each (~> this.push "#it#end"), chunk
    | otherwise => this.push remove-extra-newlines "#chunk#end"
    next!

opts-to-output-stream = (opts) ->
    switch opts.output-type
    | \pretty       => inspect-stream opts.pretty-depth
    | \raw          => raw-output-stream opts.compact
    | <[ csv tsv ]> => require 'fast-csv' .create-write-stream csv-opts opts.output-type, opts.csv-delimiter, opts.headers
    | \table        => table-output-stream opts.compact
    | otherwise     => json-stringify-stream opts.compact

opts-to-input-parser-stream = (opts) ->
    switch opts.input-type
    | \raw          => split2!
    | <[ csv tsv ]> => (require 'fast-csv') csv-opts opts.input-type, opts.csv-delimiter, opts.headers
    | otherwise     => JSONStream.parse opts.json-path

make-stdin-parser = (die, opts, stdin) ->
    input-parser = opts-to-input-parser-stream opts
    pipeline stdin, [
        debug-stream debug, opts, \stdin
        input-parser .on \error -> die it
        if opts.slurp then concat-stream!
    ]

make-input-stream = (die, opts, stdin) ->
    if opts.stdin then make-stdin-parser die, opts, stdin
    else               blank-obj-stream!

make-map-stream = (die, opts, fun) ->
    if opts.transduce then (require 'transduce-stream') fun, {+object-mode}
    else map-stream fun, -> die (take-lines 3, it.stack)

export get-stream-as-promise = (stream, cb) ->
    new Promise (resolve, reject) ->
        res = null
        stream
            .pipe reduce-stream append-buffer, Buffer.alloc-unsafe 0
            .on 'data', (chunk) -> res := chunk
            .on 'end', -> resolve res

export process-input-stream = (die, opts, fun, input-stream, output-stream) ->
    pipeline (make-input-stream die, opts, input-stream), [
        make-map-stream die, opts, fun
        if opts.unslurp then unconcat-stream!
        opts-to-output-stream opts
        debug-stream debug, opts, \stdout
        if output-stream then output-stream
    ]

