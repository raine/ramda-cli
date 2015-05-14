#!/usr/bin/env lsc

require! treis
require! livescript
require! vm
require! through2
require! stream: {PassThrough}
require! 'stream-reduce'
require! ramda: {type, apply, is-nil, append, flip, type, replace}: R
require! util: {inspect}
require! JSONStream
require! './argv'
debug = require 'debug' <| 'ramda-cli:main'

ensure-single-newline = replace /\n*$/, '\n'

compile-and-eval = (code) ->
    compiled = livescript.compile code, {+bare, -header}
    debug (inspect compiled), 'compiled code'
    sandbox = {R, treis} <<< R
    ctx = vm.create-context sandbox
    vm.run-in-context compiled, ctx

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

    concat-stream   = stream-reduce flip(append), []
    unconcat-stream = through2.obj (chunk,, next) ->
        switch type chunk
        | \Array    => chunk.for-each ~> this.push it
        | otherwise => this.push chunk
        next!

    raw-output-stream = through2.obj (chunk,, next) ->
        this.push ensure-single-newline chunk.to-string!
        next!

    inspect-stream = through2.obj (chunk,, next) ->
        this.push (inspect chunk, colors: true) + '\n'
        next!

    json-stringify-stream = apply JSONStream.stringify,
        (if opts.compact then [false] else ['', '\n', '\n', 2])

    map-stream = (func) -> through2.obj (chunk,, next) ->
        val = func chunk
        this.push val unless is-nil val
        next!

    output-formatter = switch
    | opts.inspect    => inspect-stream
    | opts.raw-output => raw-output-stream
    | otherwise       => json-stringify-stream

    pass-through-unless = (val, stream) ->
        switch | val       => stream
               | otherwise => PassThrough object-mode: true

    stdin
        .pipe JSONStream.parse!
        .pipe pass-through-unless opts.slurp, concat-stream
        .pipe map-stream fun
        .pipe pass-through-unless opts.unslurp, unconcat-stream
        .pipe output-formatter
        .pipe stdout

module.exports = main
