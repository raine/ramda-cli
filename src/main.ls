#!/usr/bin/env lsc

require! treis
require! livescript
require! vm
require! through2: through
require! stream: {PassThrough}
require! 'stream-reduce'
require! ramda: {type, apply, is-nil, append, flip, type, replace, merge}: R
require! util: {inspect}
require! JSONStream
require! 'fast-csv': csv
require! './argv'
debug = require 'debug' <| 'ramda-cli:main'

ensure-single-newline = replace /\n*$/, '\n'

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
    this.push ensure-single-newline chunk.to-string!
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

csv-opts-by-type = (type) ->
    opts = headers: true
    switch type
    | \csv => opts
    | \tsv => opts <<< delimiter: '\t'

output-type-to-stream = csv-opts-by-type >> csv.create-write-stream

main = (process-argv, stdin, stdout, stderr) ->
    debug {argv: process-argv}
    log-error = (+ '\n') >> stderr~write
    die       = log-error >> -> process.exit 1

    try opts = argv.parse process-argv
    catch e then return die [argv.generate-help!, e.message] * '\n\n'

    code = opts._.0
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

    output-formatter = switch
    | opts.inspect      => inspect-stream!
    | opts.raw-output   => raw-output-stream!
    | opts.output-type? => output-type-to-stream opts.output-type
    | otherwise         => json-stringify-stream opts.compact

    stdin
        .pipe JSONStream.parse!
        .pipe pass-through-unless opts.slurp, concat-stream!
        .pipe map-stream fun
        .pipe pass-through-unless opts.unslurp, unconcat-stream!
        .pipe output-formatter
        .pipe debug-stream debug, object-mode: true
        .pipe stdout

module.exports = main
