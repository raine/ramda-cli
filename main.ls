#!/usr/bin/env lsc

require! LiveScript
require! vm
require! 'through2-map': map-stream
require! ramda: {pipe, type}: R
require! util: {inspect}
require! JSONStream
debug = require 'debug' <| 'ramda-cli'

compile-and-eval = (code) ->
    compiled = LiveScript.compile code, {+bare, -header}
    debug (inspect compiled), 'compiled code'
    sandbox = {R} <<< R
    ctx = vm.create-context sandbox
    vm.run-in-context compiled, ctx

main = (argv, stdin, stdout, stderr) ->
    log-error = (+ '\n') >> stderr~write
    die = log-error >> -> process.exit 1

    code = argv.2
    debug (inspect code), 'input code'
    unless code then die 'usage: ramda [function]'

    try fun = compile-and-eval code
    catch {message}
        return die "error: #{message}"

    debug (inspect fun), 'evaluated to'
    unless typeof fun is 'function'
        return die "error: evaluated into type of #{type fun} instead of Function"

    stdin
        .pipe JSONStream.parse!
        .pipe map-stream.obj fun
        .pipe JSONStream.stringify false,,, 2
        .on \end -> stdout.write '\n'
        .pipe stdout

module.exports = main
