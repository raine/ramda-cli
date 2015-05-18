#!/usr/bin/env lsc

require! treis
require! livescript
require! vm
require! through2: through
require! stream: {PassThrough}
require! 'stream-reduce'
require! ramda: {type, apply, is-nil, append, flip, type, replace, merge, map, join}: R
require! util: {inspect}
require! JSONStream
require! 'fast-csv': csv
require! './argv'
require! path
debug = require 'debug' <| 'ramda-cli:main'

remove-extra-newlines = (str) ->
    if /\n$/ == str then str.replace /\n*$/, '\n' else str

wrap-in-parens = (str) -> "(#str)"

compile-and-eval = (code) ->
    compiled = livescript.compile code, {+bare, -header}
    debug (inspect compiled), 'compiled code'
    sandbox = {R, treis} <<< R
    ctx = vm.create-context sandbox
    vm.run-in-context compiled, ctx

concat-stream   = -> stream-reduce flip(append), []
unconcat-stream = -> through.obj (chunk,, next) ->
    switch type chunk
    | \Array    => chunk.for-each ~> this.push it
    | otherwise => this.push chunk
    next!

raw-output-stream = -> through.obj (chunk,, next) ->
    this.push remove-extra-newlines chunk.to-string!
    next!

inspect-stream = -> through.obj (chunk,, next) ->
    this.push (inspect chunk, colors: true) + '\n'
    next!

debug-stream = (debug, object-mode) ->
    (if object-mode then through~obj else through)
    <| (chunk,, next) ->
        debug {chunk: chunk.to-string!}
        this.push chunk
        next!

json-stringify-stream = (compact) ->
    indent = if not compact then 2 else void
    through.obj (data,, next) ->
        json = JSON.stringify data, null, indent
        this.push json + '\n'
        next!

pass-through-unless = (val, stream) ->
    switch | val       => stream
           | otherwise => PassThrough object-mode: true

map-stream = (func) -> through.obj (chunk,, next) ->
    val = func chunk
    this.push val unless is-nil val
    next!

raw-input-stream = -> through.obj (chunk,, next) ->
    this.push chunk.to-string!
    next!

csv-opts-by-type = (type) ->
    opts = headers: true
    switch type
    | \csv => opts
    | \tsv => opts <<< delimiter: '\t'

output-type-to-stream = (type) ->
    switch type
    | \pretty       => inspect-stream!
    | \raw          => raw-output-stream!
    | <[ csv tsv ]> => csv.create-write-stream csv-opts-by-type type

main = (process-argv, stdin, stdout, stderr) ->
    debug {argv: process-argv}
    log-error = (+ '\n') >> stderr~write
    die       = log-error >> -> process.exit 1

    try opts = argv.parse process-argv
    catch e then return die [argv.generate-help!, e.message] * '\n\n'
    debug opts

    if opts.file
        try fun = require path.resolve opts.file
        catch {message}
            return die message

        unless typeof fun is 'function'
            return die "error: #{opts.file} does not export a function"
    else
        code = join ' >> ', map wrap-in-parens, opts._
        debug (inspect code), 'input code'
        if not code or opts.help
            return die argv.generate-help!

        try fun = compile-and-eval code
        catch {message}
            return die "error: #{message}"

        debug (inspect fun), 'evaluated to'
        unless typeof fun is 'function'
            return die "error: evaluated into type of #{type fun} instead of Function"

    if opts.output-type in <[ csv tsv ]>
        opts.unslurp = true

    input-parser = switch
    | opts.input-type is \raw => raw-input-stream!
    | otherwise               => JSONStream.parse!

    output-formatter = switch
    | opts.output-type? => output-type-to-stream opts.output-type
    | otherwise         => json-stringify-stream opts.compact

    stdin
        .pipe input-parser
        .pipe pass-through-unless opts.slurp, concat-stream!
        .pipe map-stream fun
        .pipe pass-through-unless opts.unslurp, unconcat-stream!
        .pipe output-formatter
        .pipe debug-stream debug, object-mode: true
        .pipe stdout

module.exports = main
