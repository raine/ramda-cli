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
