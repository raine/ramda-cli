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
        ..pipe concat-stream encoding: \string, -> cb it, null
    stderr = new stream.PassThrough!
        .on \data, (data) -> cb null, data.to-string!

    main ([,,] ++ args), stdin, stdout, stderr
    stdin.write input if input
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

describe 'multiple functions as arguments' (,) ->
    it 'composes multiple function arguments from left to right' (done) ->
        args     = ['replace "foo", "bar"', 'to-upper']
        input    = '"foo"'
        expected = '"BAR"\n'
        output <-! run-main args, input
        output `eq` expected
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

describe '--input-type raw' (,) ->
    it 'reads raw strings through stdin' (done) ->
        args     = <[ -i raw identity ]>
        input    = 'foo'
        expected = '"foo"\n'
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'works together with -o raw as expected' (done) ->
        args  = <[ -i raw -o raw identity ]>
        input = """
        foo
        bar
        xyz
        """
        expected = """
        foo
        bar
        xyz
        """
        output <-! run-main args, input
        output `eq` expected
        done!

describe '--input-type csv' (,) ->
    it 'reads csv with headers into a list of objects' (done) ->
        args  = <[ -i csv identity ]>
        input = """
        name,code
        Afghanistan,AF
        Åland Islands,AX
        Albania,AL
        """
        expected = """
        [ { "name": "Afghanistan", "code": "AF" },
          { "name": "Åland Islands", "code": "AX" },
          { "name": "Albania", "code": "AL" } ]
        """
        output <-! run-main args, input
        output `strip-eq` expected
        done!

describe '--input-type tsv' (,) ->
    it 'reads tsv with headers into a list of objects' (done) ->
        args  = <[ -i tsv identity ]>
        input = """
        name\tcode
        Afghanistan\tAF
        Åland Islands\tAX
        Albania\tAL
        """
        expected = """
        [ { "name": "Afghanistan", "code": "AF" },
          { "name": "Åland Islands", "code": "AX" },
          { "name": "Albania", "code": "AL" } ]
        """
        output <-! run-main args, input
        output `strip-eq` expected
        done!

describe '--output-type raw' (,) ->
    it 'prints a string without quotes and without newline in the end' (done) ->
        args     = <[ identity -o raw ]>
        input    = '"foo"'
        expected = 'foo'
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'prints a stream of strings concatenated' (done) ->
        args     = <[ identity -o raw ]>
        input    = '"foo"\n"bar"'
        expected = 'foobar'
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'prints a stream of numbers concatenated' (done) ->
        args     = <[ identity -o raw ]>
        input    = '1\n2\n3\n'
        expected = '123'
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'removes extra newlines from end' (done) ->
        args     = ['(+ "\\n\\n")', '-o', 'raw']
        input    = '"foo"'
        expected = 'foo\n'
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'requires actual newlines in the data if those are needed in output' (done) ->
        args     = ['(+ "\\n")', '-o', 'raw']
        input    = '"foo"\n"bar"'
        expected = 'foo\nbar\n'
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'prints a list\'s items separately' (done) ->
        args     = <[ identity -o raw ]>
        input    = '["foo", "bar", "xyz"]'
        expected = """
        foo
        bar
        xyz\n
        """
        output <-! run-main args, input
        output `eq` expected
        done!

describe '--output-type pretty' (,) ->
    it 'pretty prints objects' (done) ->
        args     = <[ identity -o pretty ]>
        input    = '{"foo":"bar"}{"foo":"bar"}'
        expected = """
        { foo: \u001b[32m'bar'\u001b[39m }
        { foo: \u001b[32m'bar'\u001b[39m }\n
        """
        output <-! run-main args, input
        output `eq` expected
        done!

describe '--output-type csv' (,) ->
    it 'prints a list of objects as CSV with headers' (done) ->
        args  = <[ identity -o csv ]>
        input = """
        [ { "name": "Afghanistan", "code": "AF" },
          { "name": "Åland Islands", "code": "AX" },
          { "name": "Albania", "code": "AL" } ]
        """
        expected = """
        name,code
        Afghanistan,AF
        Åland Islands,AX
        Albania,AL
        """
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'prints a stream of bare objects as CSV' (done) ->
        args  = <[ identity -o csv ]>
        input = """
        { "name": "Afghanistan", "code": "AF" }
        { "name": "Åland Islands", "code": "AX" }
        { "name": "Albania", "code": "AL" }
        """
        expected = """
        name,code
        Afghanistan,AF
        Åland Islands,AX
        Albania,AL
        """
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'prints array of arrays as CSV' (done) ->
        args  = <[ identity -o csv ]>
        input = """
        [ ["foo", "bar"], ["hello", "world"] ]
        """
        expected = """
        foo,bar
        hello,world
        """
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'prints a stream of bare arrays but needs --slurp too' (done) ->
        args     = <[ identity -o csv --slurp ]>
        input    = '["foo", "bar"]\n["hello", "world"]'
        expected = """
        foo,bar
        hello,world
        """
        output <-! run-main args, input
        output `eq` expected
        done!

describe '--output-type tsv' (,) ->
    it 'prints a list of objects as TSV with headers' (done) ->
        args  = <[ identity -o tsv ]>
        input = """
        [ { "name": "Afghanistan", "code": "AF" },
          { "name": "Åland Islands", "code": "AX" },
          { "name": "Albania", "code": "AL" } ]
        """
        expected = """
        name\tcode
        Afghanistan\tAF
        Åland Islands\tAX
        Albania\tAL
        """
        output <-! run-main args, input
        output `eq` expected
        done!

describe '--file' (,) ->
    stub-process-exit!

    it 'reads function from a LiveScript file' (done) ->
        args     = <[ -i raw -o raw -f test/data/shout.ls ]>
        input    = 'foo'
        expected = 'FOO!'
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'reads function from a JavaScript file' (done) ->
        args     = <[ -i raw -o raw -f test/data/capitalize.js ]>
        input    = 'hello'
        expected = 'Hello'
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'produces an error if file does not exist' (done) ->
        args = <[ -f does/not/exist ]>
        output, errput <-! run-main args, ''
        assert.match (head lines errput), /Error: Cannot find module .*does\/not\/exist/
        done!

    it 'produces an error if file does not export a function' (done) ->
        args = <[ -f test/data/dummy.ls ]>
        output, errput <-! run-main args, ''
        errput `eq` 'error: test/data/dummy.ls does not export a function\n'
        done!

describe '--help' (,) ->
    stub-process-exit!

    it 'shows help' (done) ->
        output, errput <-! run-main <[ identity -h ]>, '[1,2,3]'
        'Usage: ramda [options] [function] ...' `eq` head lines errput
        done!

describe '--version' (,) ->
    stub-process-exit!

    it 'shows version' (done) ->
        output, errput <-! run-main <[ --version ]>, null
        (require '../package.json' .version) `eq` head lines errput
        done!

function stub-process-exit
    sandbox = null

    before-each ->
        sandbox := sinon.sandbox.create!
        sandbox.stub process, \exit

    after-each ->
        sandbox.restore!

    return sandbox
