require! '../src/main'
require! stream
require! sinon
require! 'concat-stream'
require! ramda: {repeat, join, flip, split, head}
{called-with} = sinon.assert

stringify = JSON.stringify _, null, 2
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
    stub-process-exit!

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

describe '--compact' (,) ->
    it 'prints compact json output' (done) ->
        args     = <[ identity -c ]>
        input    = """
        [
          1,
          2,
          3
        ]
        """
        expected = '[1,2,3]\n'
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'prints newline separated compact objects' (done) ->
        args  = <[ identity -c ]>
        input = """
        {
          "foo": "bar"
        }
        {
          "foo": "bar"
        }
        """
        expected = """
        {"foo":"bar"}
        {"foo":"bar"}\n
        """

        output <-! run-main args, input
        output `eq` expected
        done!

describe '--slurp' (,) ->
    it 'reads lists into a list of lists' (done) ->
        args     = <[ identity -s ]>
        input    = '[1,2,3] [1,2,3]'
        expected = '[[1,2,3],[1,2,3]]'
        output <-! run-main args, input
        output `strip-eq` expected
        done!

    it 'reads objects into list of objects' (done) ->
        args     = <[ identity -s ]>
        input    = '{"foo":"bar"}\n{"foo":"bar"}'
        expected = '[{"foo":"bar"},{"foo":"bar"}]'
        output <-! run-main args, input
        output `strip-eq` expected
        done!

    it 'reads number in to a list of numbers' (done) ->
        args     = <[ identity -s ]>
        input    = '1\n2\n3\n'
        expected = '[1,2,3]'
        output <-! run-main args, input
        output `strip-eq` expected
        done!

    it 'reads strings in to a list of strings' (done) ->
        args     = <[ identity -s ]>
        input    = '"foo"\n"bar"'
        expected = '["foo", "bar"]'
        output <-! run-main args, input
        output `strip-eq` expected
        done!

describe '--inspect' (,) ->
    it 'pretty prints objects' (done) ->
        args     = <[ identity -i ]>
        input    = '{"foo":"bar"}{"foo":"bar"}'
        expected = """
        { foo: \u001b[32m'bar'\u001b[39m }
        { foo: \u001b[32m'bar'\u001b[39m }\n
        """
        output <-! run-main args, input
        output `eq` expected
        done!

describe '--unslurp' (,) ->
    it 'prints list of strings separated by newline' (done) ->
        args     = <[ identity -S ]>
        input    = '["foo", "bar"]'
        expected = """
        "foo"
        "bar"\n
        """
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'prints list of numbers separated by newline' (done) ->
        args     = <[ identity -S ]>
        input    = '[1,2,3]'
        expected = '1\n2\n3\n'
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'prints list of objects as separate objects' (done) ->
        args     = <[ identity -S ]>
        input    = '[{"foo":"bar"},{"foo":"bar"}]'
        expected = """
        {
          "foo": "bar"
        }
        {
          "foo": "bar"
        }\n
        """
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'reverses --slurp' (done) ->
        args     = <[ identity -sS ]>
        input    = '["foo", "bar"]\n["hello", "world"]'
        output <-! run-main args, input
        output `strip-eq` input
        done!

    it 'does nothing if list is already separate objects' (done) ->
        args     = <[ identity -S ]>
        input    = '{"foo":"bar"}\n{"foo":"bar"}\n'
        expected = '{"foo":"bar"}{"foo":"bar"}'
        output <-! run-main args, input
        output `strip-eq` expected
        done!

describe '--raw-output' (,) ->
    it 'prints strings without quotes separated by newline' (done) ->
        args     = <[ identity -r ]>
        input    = '"foo"\n"bar"'
        expected = """
        foo
        bar\n
        """
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'prints list of numbers separated by newline' (done) ->
        args     = <[ identity -r ]>
        input    = '1\n2\n3\n'
        expected = '1\n2\n3\n'
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'should remove extra newlines from end' (done) ->
        args     = ['(+ "\\n\\n")', '-r']
        input    = '"foo"'
        expected = 'foo\n'
        output <-! run-main args, input
        output `eq` expected
        done!

describe '--help' (,) ->
    stub-process-exit!

    it 'shows help' (done) ->
        output, errput <-! run-main ['identity', '-h'], '[1,2,3]'
        'Usage: ramda [options] [function]' `eq` head lines errput
        done!

function stub-process-exit
    sandbox = null

    before-each ->
        sandbox := sinon.sandbox.create!
        sandbox.stub process, \exit

    after-each ->
        sandbox.restore!

    return sandbox
