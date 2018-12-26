require! ramda: {is-nil, append, flip, type, for-each, reduce}: R
require! stream: {PassThrough, pipeline}
require! through2: through
require! {JSONStream, split2}
require! util: {inspect}
require! './utils': {is-thenable, take-lines, remove-extra-newlines, is-browser}

debug = require 'debug' <| 'ramda-cli:stream'
debug.enabled = true if is-browser!

reduce-stream = (fn, acc) -> through.obj do
    (chunk,, next) ->
        acc := fn acc, chunk
        next!
    (next) ->
        this.push acc
        next!

export concat-stream = -> reduce-stream flip(append), []

unconcat-stream = -> through.obj (chunk,, next) ->
    switch type chunk
    | \Array    => for-each this~push, chunk
    | otherwise => this.push chunk
    next!

map-stream = (fun) -> through.obj (chunk,, next) ->
    push = (x) ~>
        # pushing a null would end the stream
        this.push x unless x is null
        next!
    try
        val = fun chunk
    catch
        return next e
    if is-thenable val then val.then push
    else push val

json-stringify-stream = (compact) ->
    indent = if not compact then 2 else void
    through.obj (data,, next) ->
        json = switch type data
        | \Function => data.to-string!
        | otherwise => JSON.stringify data, null, indent
        this.push json + '\n'
        next!

debug-stream = (debug, opts, str) ->
    through.obj (chunk,, next) ->
        if debug.enabled and opts.very-verbose
            debug inspect(chunk), str
        this.push chunk
        next!

append-buffer =
    (buf1, buf2) -> Buffer.concat([ buf1, buf2 ])

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

raw-output-stringify = ->
    if type(it) is 'Object' then JSON.stringify it
    else it.to-string!

raw-output-stream = (compact) -> through.obj (chunk,, next) ->
    end = unless compact then "\n" else ''
    switch type chunk
    | \Array    => for-each (~> this.push "#{raw-output-stringify it}#end"), chunk
    | otherwise => this.push remove-extra-newlines "#{raw-output-stringify chunk}#end"
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

make-stdin-parser = (on-error, opts, stdin) ->
    input-parser = opts-to-input-parser-stream opts
    s = stdin
        .pipe debug-stream debug, opts, \stdin
        .pipe input-parser .on \error -> on-error it
        .pipe debug-stream debug, opts, "after input-parser"

    if opts.slurp
        s := s.pipe concat-stream!

    return s

make-input-stream = (on-error, opts, stdin) ->
    if opts.stdin then make-stdin-parser on-error, opts, stdin
    else               blank-obj-stream!

make-map-stream = (opts, fun) ->
    if opts.transduce then (require 'transduce-stream') fun, {+object-mode}
    else map-stream fun

export get-stream-as-promise = (stream) ->
    new Promise (resolve, reject) ->
        res = null
        stream
            .pipe reduce-stream append-buffer, Buffer.alloc-unsafe 0
            .on 'data', (chunk) -> res := chunk
            .on 'end', -> resolve res

export process-input-stream = (on-error, opts, fun, input-stream, output-stream) ->
    s = make-input-stream on-error, opts, input-stream
        .pipe make-map-stream opts, fun
            .on 'error', on-error
        .pipe debug-stream debug, opts, "after map-stream"

    if opts.unslurp
        s := s.pipe unconcat-stream!

    s := s
        .pipe opts-to-output-stream opts
        .pipe debug-stream debug, opts, \stdout

    if output-stream
       s.pipe output-stream

    return s
