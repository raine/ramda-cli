#!/usr/bin/env lsc

require! LiveScript
require! vm
require! 'concat-stream'
require! ramda: {pipe}: R
require! util: {inspect}
debug = require 'debug' <| 'ramda-cli'

die = console~error >> -> process.exit 1
code = process.argv.2
debug (inspect code), 'input code'
unless code then die 'usage: ramda [function]'

compile-and-eval = (code) ->
    compiled = LiveScript.compile code, {+bare, -header}
    debug (inspect compiled), 'compiled code'
    sandbox = {R}
    sandbox <<< require 'ramda'
    ctx = vm.create-context sandbox
    vm.run-in-context compiled, ctx

fn = try compile-and-eval code
catch err then die "error: #{err.message}"

debug (inspect fn), 'evaluated to'
unless typeof fn is 'function' then die 'error: code did not evaluate into a function'

process.stdin.pipe concat-stream do
    pipe JSON.parse, fn, (JSON~stringify _, null, 4), console.log 
