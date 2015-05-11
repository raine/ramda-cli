#!/usr/bin/env lsc

require! LiveScript
require! vm
require! 'through2-map': map-stream
require! ramda: {pipe}: R
require! util: {inspect}
require! JSONStream
debug = require 'debug' <| 'ramda-cli'

die = console~error >> -> process.exit 1

compile-and-eval = (code) ->
    compiled = LiveScript.compile code, {+bare, -header}
    debug (inspect compiled), 'compiled code'
    sandbox = {R} <<< R
    ctx = vm.create-context sandbox
    vm.run-in-context compiled, ctx

main = (argv, stdin, stdout) ->
    code = argv.2
    debug (inspect code), 'input code'
    unless code then die 'usage: ramda [function]'

    fun = try compile-and-eval code
    catch {msg} then die "error: #{msg}"

    debug (inspect fun), 'evaluated to'
    unless typeof fun is 'function' then die 'error: code did not evaluate into a function'

    stdin
        .pipe JSONStream.parse!
        .pipe map-stream.obj fun
        .pipe JSONStream.stringify false,,, 2
        .on \end -> stdout.write '\n'
        .pipe stdout

module.exports = main
