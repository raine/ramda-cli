#!/usr/bin/env lsc
require! {vm, JSONStream, path: Path, split2, fs, camelize}
require! <[ ./argv ./config ]>
require! './compile-fun'
require! through2: through
require! stream: {PassThrough}
require! ramda: {apply, is-nil, append, flip, type, replace, merge, map, join, for-each, split, head, pick-by, tap, pipe, concat, take, identity, is-empty, reverse, invoker, from-pairs, merge-all, path, reduce, obj-of, assoc-path, adjust, to-pairs}: R
require! util: {inspect}
require! './utils': {HOME, lines, words}
require! './stream': {process-input-stream, get-stream-as-promise}
debug = require 'debug' <| 'ramda-cli:main'
Module = require 'module' .Module

# caveat: require will still prioritize ramda-cli's own node_modules
process.env.'NODE_PATH' = join ':', [
    Path.join(process.cwd(), 'node_modules')
    Path.join(HOME, 'node_modules') ]

Module._init-paths!

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
