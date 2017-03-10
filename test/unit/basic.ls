require! stream
require! sinon
require! 'concat-stream'
require! 'strip-ansi'
require! '../helpers': {run-main, stub-process-exit}
require! ramda: {repeat, join, flip, split, head, for-each, intersperse}
{called-with} = sinon.assert

stringify = JSON.stringify _, null, 2
unwords   = join ' '
lines     = split '\n'
repeat-n  = flip repeat
repeat-obj-as-str = (obj, times) ->
    unwords repeat-n times, stringify obj

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

    it 'parses function expressions without parens' (done) ->
        output <-! run-main ['-> it'], '1\n'
        output `eq` '1\n'
        done!

    it 'allows implicit lookup without parens', (done) ->
        output <-! run-main ['.foo'], '{"foo":"bar"}'
        output `eq` '"bar"\n'
        done!

describe 'match function' (,) ->
    cases =
        'match /foo/'
        'match(/foo/)'
        '(match)(/foo/)'
        '(.match /foo/)'
        '.match /foo/'

    it 'is usable despite being a keyword in livescript' (done) ->
        output <-! run-main (intersperse \head, cases), '"foo"'
        output `strip-eq` '["foo"]'
        done!

describe 'eval-context' (,) ->
    it 'has require' (done) ->
        output <-! run-main ['require("../test/data/shout")'] ++ [\-rR], 'foo'
        output `eq` 'FOO!\n'
        done!

    it 'has read-file' (done) ->
        output <-! run-main <[ read-file -rR ]>, 'test/data/hello'
        output `eq` 'hello\n'
        done!

    functions = <[ treis flat lines unlines words unwords ]>
    functions |> for-each (fn) ->
        it "has #fn" (done) ->
            args     = <[ eval type -rR ]>
            expected = 'Function\n'
            output <-! run-main args, fn
            output `eq` expected
            done!

describe 'multiple functions as arguments' (,) ->
    it 'composes multiple function arguments from left to right' (done) ->
        args     = ['replace "foo", "bar"', 'to-upper']
        input    = '"foo"'
        expected = '"BAR"\n'
        output <-! run-main args, input
        output `eq` expected
        done!

describe 'promises' (,) ->
    it 'unwraps a promise' (done) ->
        args     = '(x) -> Promise.resolve(x + 1)'
        input    = '1\n'
        expected = '2\n'
        output <-! run-main args, input
        output `eq` expected
        done!

describe 'errors' (,) ->
    stub-process-exit!

    describe 'with code that does not evaluate to a function' (,) ->
        it 'outputs an error' (done) ->
            output, errput <-! run-main '1', '[1,2,3]'
            errput `eq` 'Error: First argument to _arity must be a non-negative integer no greater than ten\n'
            done!

        it 'exits with 1' (done) ->
            <-! run-main '1', '[1,2,3]'
            <-! set-immediate
            called-with process.exit, 1
            done!

    describe 'with bad json' (,) ->
        it 'shows terse error' (done) ->
            output, errput <-! run-main 'identity', 'b'
            errput `eq` 'Error: Invalid JSON (Unexpected "b" at position 0 in state STOP)\n'
            done!

    describe 'without arguments' (,) ->
        it 'shows help' (done) ->
            output, errput <-! run-main [], ''
            (head lines errput) `eq` 'Usage: ramda [options] [function] ...'
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

    it 'works together with -o raw' (done) ->
        args  = <[ -i raw -o raw identity ]>
        input = """
        foo
        bar
        xyz
        """
        expected = """
        foo
        bar
        xyz\n
        """
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'reads lines separately' (done) ->
        args  = <[ -i raw identity ]>
        input = """
        foo
        bar
        xyz
        """
        expected = """
        "foo"
        "bar"
        "xyz"\n
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
    it 'prints a string without quotes' (done) ->
        args     = <[ identity -o raw ]>
        input    = '"foo"'
        expected = 'foo\n'
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'prints a stream of strings separated by line breaks' (done) ->
        args     = <[ identity -o raw ]>
        input    = '"foo"\n"bar"\n"xyz"\n'
        expected = 'foo\nbar\nxyz\n'
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'prints a stream of numbers separated by line breaks' (done) ->
        args     = <[ identity -o raw ]>
        input    = '1\n2\n3\n'
        expected = '1\n2\n3\n'
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'prints an array of strings one by one' (done) ->
        args     = <[ identity -o raw ]>
        input    = '["foo","bar","xyz"]'
        expected = 'foo\nbar\nxyz\n'
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

    it 'prints strings without newline if --compact as supplied' (done) ->
        args     = <[ identity -o raw --compact ]>
        input    = '"foo"\n"bar"\n"xyz"\n'
        expected = 'foobarxyz'
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

describe '--pretty-depth' (,) ->
    it 'configures pretty printing of objects up to specific depth' (done) ->
        args     = <[ identity -o pretty --pretty-depth 1 ]>
        input    = '{"a":{"b":{"c":[1,2,3]}}}'
        expected = """
        { a: { b: [Object] } }\n
        """
        output <-! run-main args, input
        (strip-ansi output) `eq` expected
        done!

    it 'parses null as infinite' (done) ->
        args     = <[ identity -o pretty --pretty-depth null ]>
        input    = '{"a":{"b":{"c":[1,2,3]}}}'
        expected = """
        { a: { b: { c: [ 1, 2, 3 ] } } }\n
        """
        output <-! run-main args, input
        (strip-ansi output) `eq` expected
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

describe '--output-type table' (,) ->
    input = """
    [ { "name": "Afghanistan", "code": "AF" },
      { "name": "Åland Islands", "code": "AX" },
      { "name": "Albania", "code": "AL" } ]
    """

    it 'prints a table' (done) ->
        args  = <[ identity -o table ]>
        expected = """
        ┌───────────────┬──────┐
        │ name          │ code │
        ├───────────────┼──────┤
        │ Afghanistan   │ AF   │
        ├───────────────┼──────┤
        │ Åland Islands │ AX   │
        ├───────────────┼──────┤
        │ Albania       │ AL   │
        └───────────────┴──────┘\n
        """
        output <-! run-main args, input
        (strip-ansi output) `eq` expected
        done!

    it 'prints a compact table with -c' (done) ->
        args  = <[ identity -c -o table ]>
        expected = """
        ┌───────────────┬──────┐
        │ name          │ code │
        ├───────────────┼──────┤
        │ Afghanistan   │ AF   │
        │ Åland Islands │ AX   │
        │ Albania       │ AL   │
        └───────────────┴──────┘\n
        """
        output <-! run-main args, input
        (strip-ansi output) `eq` expected
        done!

describe '--file' (,) ->
    stub-process-exit!

    it 'reads function from a LiveScript file' (done) ->
        args     = <[ -i raw -o raw -f test/data/shout.ls ]>
        input    = 'foo'
        expected = 'FOO!\n'
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'reads function from a JavaScript file' (done) ->
        args     = <[ -i raw -o raw -f test/data/capitalize.js ]>
        input    = 'hello'
        expected = 'Hello\n'
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
        errput `eq` 'Error: test/data/dummy.ls does not export a function\n'
        done!

    it 'allows exporting options' (done) ->
        args = <[ -f test/data/slurp-sum.ls ]>
        input    = '1\n1\n1\n'
        expected = '3\n'
        output, errput <-! run-main args, input
        output `eq` expected
        done!

describe '--no-stdin' (,) ->
    it 'emits an object regardless of stdin' (done) ->
        args     = <[ -n identity ]>
        input    = '"foo"\n'
        expected = '{}\n'
        output <-! run-main args, input
        output `eq` expected
        done!

describe '--transduce' (,) ->
    it 'transduces input stream' (done) ->
        args     = <[ -t drop-repeats ]>
        input    = '1 2 2 3 4 4 5\n'
        expected = '1\n2\n3\n4\n5\n'
        output <-! run-main args, input
        output `eq` expected
        done!

    it 'reverses functions before composing' (done) ->
        args     = ['-t', 'map add 1', 'filter (> 3)']
        input    = '2 3 4\n'
        expected = '4\n5\n'
        output <-! run-main args, input
        output `eq` expected
        done!

describe '--json-path' (,) ->
    it 'unwraps a json array with *' (done) ->
        args     = <[ identity --json-path * ]>
        input    = '[1,2,3]'
        expected = '1\n2\n3\n'
        output <-! run-main args, input
        output `eq` expected
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
        (require '../../package.json' .version) `eq` head lines errput
        done!

describe '--js' (,) ->
    it 'compiles input as javascript' (done) ->
        output, errput <-! run-main ['--js', 'map(x => x + 1)'], '[1,2,3]'
        output `strip-eq` '[2,3,4]'
        done!
