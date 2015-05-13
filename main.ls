#!/usr/bin/env lsc

require! treis
require! LiveScript
require! vm
require! through2
require! ramda: {pipe, type, apply, is-nil}: R
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
    if not code or opts.help then return die argv.generate-help!

    try fun = compile-and-eval code
    catch {message}
        return die "error: #{message}"

    debug (inspect fun), 'evaluated to'
    unless typeof fun is 'function'
        return die "error: evaluated into type of #{type fun} instead of Function"

    stdin
        .pipe JSONStream.parse!
        .pipe through2.obj (chunk, encoding, next) ->
            val = fun chunk
            this.push val unless is-nil val
            next!
        .pipe apply JSONStream.stringify,
            (if opts.compact then [false] else [false, void, void, 2])
        .on \end -> stdout.write '\n'
        .pipe stdout

module.exports = main
