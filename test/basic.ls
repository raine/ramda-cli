require! '../main'
require! stream
require! sinon
require! 'concat-stream'
require! ramda: {repeat, join, flip, split, head}
{called-with} = sinon.assert

stringify = JSON.stringify _, 2
unwords   = join ' '
lines     = split '\n'
repeat-n  = flip repeat
repeat-obj-as-str = (obj, times) ->
    unwords repeat-n times, stringify obj

run-main = (args, input, cb) ->
    stdin  = new stream.PassThrough!
    stdout = new stream.PassThrough {+object-mode}
        ..pipe concat-stream -> cb it, null
    stderr = new stream.PassThrough!
        .on \data, (data) -> cb null, data.to-string!

    main ([,,] ++ args), stdin, stdout, stderr
    stdin.write input
    stdin.end!

describe 'basic' (,) ->
    it 'outputs an incremented number' (done) ->
        output <-! run-main 'add 1', '1\n'
        output `eq` '2\n'
        done!

    it 'outputs a sum of a list' (done) ->
        output <-! run-main 'sum', '[1,2,3]'
        output `eq` '6\n'
        done!

    it 'outputs an indented json' (done) ->
        output <-! run-main 'identity', '[1,2,3]'
        output `eq` '[\n  1,\n  2,\n  3\n]\n'
        done!

    it 'reads multiple json objects' (done) ->
        output <-! run-main 'identity', repeat-obj-as-str foo: \bar, 2
        output `strip-eq` """{"foo":"bar"}{"foo":"bar"}"""
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
            errput `eq` 'error: evaluated into type of Number instead of Function\n'
            done!

        it 'exits with 1' (done) ->
            <-! run-main '1', '[1,2,3]'
            <-! set-immediate
            called-with process.exit, 1
            done!

describe '--compact -c' (,) ->
    it 'prints compact json output' (done) ->
        output, errput <-! run-main ['identity', '-c'], stringify foo: \bar
        output `strip-eq` """{"foo":"bar"}\n"""
        done!

    it 'prints compact json output f' (done) ->
        output, errput <-! run-main ['identity', '-c'], repeat-obj-as-str foo: \bar, 2
        """
        {"foo":"bar"}
        {"foo":"bar"}\n
        """ `eq` output
        done!

describe '--help' (,) ->
    sandbox = null

    before-each ->
        sandbox := sinon.sandbox.create!
        sandbox.stub process, \exit

    after-each ->
        sandbox.restore!

    it 'shows help' (done) ->
        output, errput <-! run-main ['identity', '-h'], '[1,2,3]'
        "Usage: ramda [options] [function]" `eq` head lines errput
        done!
