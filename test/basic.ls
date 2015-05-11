require! '../main'
require! stream
require! 'concat-stream'
require! ramda: {repeat, join}

run-main = (code, input, cb) ->
    stdin  = new stream.PassThrough!
    stdout = new stream.PassThrough {+object-mode}
        ..pipe concat-stream cb

    main [,,code], stdin, stdout
    stdin.write input
    stdin.end!

describe 'basic' (,) ->
    it 'outputs an incremented number' (done) ->
        output <-! run-main 'add 1', '1\n'
        eq output, '2\n'
        done!

    it 'outputs a sum of a list' (done) ->
        output <-! run-main 'sum', '[1,2,3]'
        eq output, '6\n'
        done!

    it 'outputs an indented json' (done) ->
        output <-! run-main 'identity', '[1,2,3]'
        eq output, '[\n  1,\n  2,\n  3\n]\n'
        done!

    it 'reads multiple json objects' (done) ->
        output <-! run-main 'identity', join ' ', repeat (JSON.stringify foo: \bar), 2
        strip-eq output, """{"foo":"bar"}{"foo":"bar"}"""
        done!
