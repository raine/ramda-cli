argv = require '../src/argv'

make-argv = -> [,,] ++ it.split(' ')
parse = make-argv >> argv.parse

describe 'argv.parse' (,) ->
    describe '-p, --pretty' (,) ->
        it 'is an alias for --output-type pretty' ->
            parse '-p' .output-type `eq` \pretty

        it 'overrides -r' ->
            parse '-p -r' .output-type `eq` \pretty

    describe '-r, --raw-input' (,) ->
        it 'is an alias for --input-type raw' ->
            args = parse '-r'
            args.input-type  `eq` \raw

    describe '-R, --raw-output' (,) ->
        it 'is an alias for --output-type raw' ->
            args = parse '-R'
            args.output-type `eq` \raw

    describe '-o, --output-type' (,) ->
        it 'should throw an error with bad value' ->
            assert.throws (-> parse '-o lol'),
                'Output type should be one of: pretty, raw, csv, tsv'

    describe '-i, --input-type' (,) ->
        it 'should throw an error with bad value' ->
            assert.throws (-> parse '-i lol'),
                'Input type should be one of: raw'

    it 'wraps function expressions in parentheses' ->
         args = argv.parse [,, 'identity', '-> it']
         args._.1 `eq` '(-> it)'

    it 'reads ".0" as string' ->
         args = argv.parse [,, '.0', '.foo']
         args._.0 `eq` '(.0)'
