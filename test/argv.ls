argv = require '../src/argv'

make-argv = -> [,,] ++ it.split(' ')
parse = make-argv >> argv.parse

describe 'argv.parse' (,) ->
    describe '-p, --pretty' (,) ->
        it 'is an alias for --output-type pretty' ->
            parse '-p' .output-type `eq` \pretty

    describe '-r, --raw-output' (,) ->
        it 'is an alias for --output-type raw' ->
            parse '-r' .output-type `eq` \raw

    describe '-o, --output-type' (,) ->
        it 'should throw an error with bad value' ->
            assert.throws (-> parse '-o lol'),
                'Output type should be one of: pretty, raw, csv, tsv'

    describe '-i, --input-type' (,) ->
        it 'should throw an error with bad value' ->
            assert.throws (-> parse '-i lol'),
                'Input type should be one of: raw'
