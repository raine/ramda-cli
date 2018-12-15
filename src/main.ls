#!/usr/bin/env lsc
require! {vm, JSONStream, path: Path, split2, fs, camelize}
require! <[ ./argv ./config ]>
require! './compile-fun'
require! through2: through
require! stream: {PassThrough}
require! ramda: {apply, is-nil, append, flip, type, replace, merge, map, join, for-each, split, head, pick-by, tap, pipe, concat, take, identity, is-empty, reverse, invoker, from-pairs, merge-all, path, reduce, obj-of, assoc-path, adjust, to-pairs}: R
require! util: {inspect}
require! './utils': {HOME}
debug = require 'debug' <| 'ramda-cli:main'
Module = require 'module' .Module

# caveat: require will still prioritize ramda-cli's own node_modules
process.env.'NODE_PATH' = join ':', [
    Path.join(process.cwd(), 'node_modules')
    Path.join(HOME, 'node_modules') ]

Module._init-paths!

lines   = split '\n'
words   = split ' '
unlines = join '\n'
unwords = join ' '

remove-extra-newlines = (str) ->
    if /\n$/ == str then str.replace /\n*$/, '\n' else str

is-thenable = (x) -> x and typeof x.then is 'function'

take-lines = (n, str) -->
    lines str |> take n |> unlines

reduce-stream = (fn, acc) -> through.obj do
    (chunk,, next) ->
        acc := fn acc, chunk
        next!
    (next) ->
        this.push acc
        next!

concat-stream   = -> reduce-stream flip(append), []
unconcat-stream = -> through.obj (chunk,, next) ->
    switch type chunk
    | \Array    => for-each this~push, chunk
    | otherwise => this.push chunk
    next!

raw-output-stream = (compact) -> through.obj (chunk,, next) ->
    end = unless compact then "\n" else ''
    switch type chunk
    | \Array    => for-each (~> this.push "#it#end"), chunk
    | otherwise => this.push remove-extra-newlines "#chunk#end"
    next!

inspect-stream = (depth) -> through.obj (chunk,, next) ->
    this.push (inspect chunk, colors: true, depth: depth) + '\n'
    next!

debug-stream = (debug, opts, str) ->
    unless debug.enabled and opts.very-verbose
        return PassThrough {+object-mode}

    through.obj (chunk,, next) ->
        debug {"#str": chunk.to-string!}
        this.push chunk
        next!

json-stringify-stream = (compact) ->
    indent = if not compact then 2 else void
    through.obj (data,, next) ->
        json = JSON.stringify data, null, indent
        this.push json + '\n'
        next!

map-stream = (func, on-error) -> through.obj (chunk,, next) ->
    push = (x) ~>
        # pushing a null would end the stream
        this.push x unless is-nil x
        next!
    val = try func chunk
    catch then on-error e
    if is-thenable val then val.then push
    else push val

table-output-stream = (compact) ->
    require! './format-table'
    opts = {compact}
    through.obj (chunk,, next) ->
        this.push "#{format-table chunk, opts}\n"
        next!

csv-opts = (type, delimiter, headers) ->
    opts = { headers, include-end-row-delimiter: true, delimiter }
    switch type
    | \csv => opts
    | \tsv => opts <<< delimiter: '\t'

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

blank-obj-stream = ->
    PassThrough {+object-mode}
        ..end {}

make-stdin-parser = (die, opts, stdin) ->
    input-parser = opts-to-input-parser-stream opts
    pipeline stdin, [
        debug-stream debug, opts, \stdin
        input-parser .on \error -> die it
        if opts.slurp then concat-stream! else null
    ]

make-input-stream = (die, opts, stdin) ->
    if opts.stdin then make-stdin-parser die, opts, stdin
    else               blank-obj-stream!

make-map-stream = (die, opts, fun) ->
    if opts.transduce then (require 'transduce-stream') fun, {+object-mode}
    else map-stream fun, -> die (take-lines 3, it.stack)

append-buffer =
    (buf1, buf2) -> Buffer.concat([ buf1, buf2 ])

get-stream-as-promise = (stream, cb) ->
    new Promise (resolve, reject) ->
        res = null
        stream
            .pipe reduce-stream append-buffer, Buffer.alloc-unsafe 0
            .on 'data', (chunk) -> res := chunk
            .on 'end', -> resolve res

pipeline = (input, pipe-through) ->
    reduce ((acc, s) -> acc.pipe s),
           input,
           pipe-through.filter((!= null))

process-input-stream = (die, opts, fun, input-stream, output-stream) ->
    pipeline (make-input-stream die, opts, input-stream), [
        make-map-stream die, opts, fun
        if opts.unslurp then unconcat-stream! else null
        opts-to-output-stream opts
        debug-stream debug, opts, \stdout
        output-stream
    ]

main = (process-argv, stdin, stdout, stderr) ->>
    stdout.on \error ->
        if it.code is 'EPIPE' then process.exit 0

    debug {argv: process-argv}
    log-error = (+ '\n') >> stderr~write
    die       = log-error >> -> process.exit 1

    try opts = argv.parse process-argv
    catch e then return die [argv.help!, e.message] * '\n\n'
    debug pick-by (is not false), opts

    if opts.help    then return die argv.help!
    if opts.version then return die <| require '../package.json' .version

    if opts.configure
        config.edit (err) ->
            if err != 0 or err then die err
            else process.exit 0
        return

    if opts.interactive
        raw-stdin-buf = await get-stream-as-promise stdin
        require './server' .start log-error, raw-stdin-buf, process-argv
        return

    if opts.file
        try fun = require Path.resolve opts.file
        catch {stack, code}
            return switch code
            | \MODULE_NOT_FOUND  => die head lines stack
            | otherwise          => die stack

        unless typeof fun is 'function'
            return die "Error: #{opts.file} does not export a function"

        if fun.opts then opts <<< argv.parse [,,] ++ words fun.opts
    else
        if is-empty opts._ then return die argv.help!
        try fun = compile-fun opts
        catch {message} then return die "Error: #{message}"

    process-input-stream die, opts, fun, stdin, stdout

module.exports = main
