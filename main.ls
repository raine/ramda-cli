#!/usr/bin/env lsc

require! treis
require! LiveScript
require! vm
require! through2
require! stream: {PassThrough}
require! 'stream-reduce'
require! ramda: {type, apply, is-nil, append, flip, type}: R
require! util: {inspect}
require! JSONStream
require! './lib/argv'
debug = require 'debug' <| 'ramda-cli'

compile-and-eval = (code) ->
    compiled = LiveScript.compile code, {+bare, -header}
    debug (inspect compiled), 'compiled code'
    sandbox = {R, treis} <<< R
    ctx = vm.create-context sandbox
    vm.run-in-context compiled, ctx

main = (process-argv, stdin, stdout, stderr) ->
    log-error = (+ '\n') >> stderr~write
    die = log-error >> -> process.exit 1

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

    json-stringify-stream = apply JSONStream.stringify,
        (if opts.compact then [false] else ['', '\n', '\n', 2])

    concat-stream = stream-reduce flip(append), []
    pass-through = PassThrough object-mode: true
    inspect-stream = through2.obj (chunk,, next) ->
        this.push (inspect chunk, colors: true) + '\n'
        next!

    raw-output-stream = through2.obj (chunk,, next) ->
        switch
        | (type chunk) is \Array => chunk.for-each (~> this.push it + '\n')
        | otherwise              => this.push chunk + '\n'
        next!

    map-stream = (func) ->
        through2.obj (chunk,, next) ->
            val = func chunk
            this.push val unless is-nil val
            next!

    output-stream = switch
    | opts.inspect    => inspect-stream
    | opts.raw-output => raw-output-stream
    | otherwise       => json-stringify-stream

    stdin
        .pipe JSONStream.parse!
        .pipe if opts.slurp then concat-stream else pass-through
        .pipe map-stream fun
        .pipe output-stream
        .pipe stdout

module.exports = main
