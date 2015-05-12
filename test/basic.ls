require! '../main'
require! stream
require! sinon
require! 'concat-stream'
require! ramda: {repeat, join}
{called-with} = sinon.assert

run-main = (code, input, cb) ->
    stdin  = new stream.PassThrough!
    stdout = new stream.PassThrough {+object-mode}
        ..pipe concat-stream -> cb it, null
    stderr = new stream.PassThrough!
        .on \data, (data) -> cb null, data.to-string!

    main [,,code], stdin, stdout, stderr
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

describe 'errors' (,) ->
    sandbox = null

    before-each ->
        sandbox := sinon.sandbox.create!
        sandbox.stub process, \exit

    after-each ->
        sandbox.restore!

    describe 'with code that does not evaluate to a function' (,) ->
        it 'outputs an error' (done) ->
            output, errput <-! run-main '1', '[1,2,3]'
            eq errput, 'error: evaluated into type of Number instead of Function\n'
            done!

        it 'exits with 1' (done) ->
            <-! run-main '1', '[1,2,3]'
            <-! set-immediate
            called-with process.exit, 1
            done!
