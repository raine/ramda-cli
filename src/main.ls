#!/usr/bin/env lsc
require! {vm, JSONStream, path: Path, split2, fs, camelize}
require! <[ ./argv ./config ]>
require! './compile-fun'
require! through2: through
require! ramda: {apply, is-nil, append, flip, type, replace, merge, map, join, for-each, split, head, pick-by, tap, pipe, concat, take, identity, is-empty, reverse, invoker, from-pairs, merge-all, path, reduce, obj-of, assoc-path, adjust, to-pairs}: R
require! util: {inspect}
require! './utils': {HOME, lines, words, take-lines}
require! './stream': {process-input-stream}
debug = require 'debug' <| 'ramda-cli:main'

main = (process-argv, stdin, stdout, stderr) ->>
    stdout.on \error ->
        if it.code is 'EPIPE' then process.exit 0

    debug {argv: process-argv}
    log-error = (+ '\n') >> stderr~write
    die = (err) ->
        msg = if err.stack then (take-lines 1, err.stack) else err
        log-error msg
        process.exit 1

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
        require! 'string-argv'
        server = await require './server' .start log-error, stdin, stderr, process-argv, (new-stdin, input) ->>
            server.close!
            # TODO: should catch here
            new-opts = argv.parse string-argv input, 'node', 'dummy.js'
            try fun = await compile-fun new-opts, stderr
            catch {message} then return die "Error: #{message}"
            # something in the server is keeping the process open despite the
            # close(), hence the manual exit. seems to work.
            process-input-stream die, new-opts, fun, new-stdin, stdout
                .on 'end', -> process.exit!
        return

    if opts.file
        try fun = require Path.resolve opts.file
        catch {stack, code}
            return switch code
            | \MODULE_NOT_FOUND => die head lines stack
            | otherwise         => die stack

        unless typeof fun is 'function'
            return die "Error: #{opts.file} does not export a function"

        if fun.opts then opts <<< argv.parse [,,] ++ words fun.opts
    else
        try fun = await compile-fun opts, stderr
        catch {message} then return die "Error: #{message}"

    process-input-stream die, opts, fun, stdin, stdout

module.exports = main
