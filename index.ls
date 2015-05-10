#!/usr/bin/env lsc

require! LiveScript
require! vm
require! 'concat-stream'
require! ramda: {pipe}
require! util: {inspect}
debug = require 'debug' <| 'ramda-cli'

die = (err-or-str) ->
    console.error err-or-str
    process.exit 1

code = process.argv.2
debug (inspect code), 'input code'
unless code then die "usage: ramda [code]"

compiled = LiveScript.compile code, {+bare, -header}
debug (inspect compiled), 'compiled code'
sandbox = {}
sandbox <<< require 'ramda'
ctx = vm.create-context sandbox
fn = vm.run-in-context compiled, ctx
debug (inspect fn), 'evaluated'

process.stdin.pipe concat-stream do
    pipe JSON.parse, fn, (JSON~stringify _, null, 4), console.log 
