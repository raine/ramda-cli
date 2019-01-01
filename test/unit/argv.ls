argv = require '../../src/argv'

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
        it 'throws an error with bad value' ->
            assert.throws (-> parse '-o lol'),
                'Output type should be one of: pretty, raw, csv, tsv'

    describe '-i, --input-type' (,) ->
        it 'throws an error with bad value' ->
            assert.throws (-> parse '-i lol'),
                'Input type should be one of: raw'

    describe '-vv' (,) ->
        it 'is parsed as very-verbose' ->
            args = parse '-vv'
            args.very-verbose `eq` true

    describe '-n, --no-stdin' (,) ->
        it 'sets stdin to false with -n' ->
            parse '-n' .stdin `eq` false

        it 'sets stdin to false with --no-stdin' ->
            parse '--no-stdin' .stdin `eq` false

        it 'sets stdin to true with --stdin' ->
            parse '--stdin' .stdin `eq` true

        it 'is boolean' ->
            parse '-n identity' .stdin `eq` false
            parse '--no-stdin identity' .stdin `eq` false

    describe '--import', (,) ->
        it 'is always an array' ->
            parse '--import foo' .import `deep-eq` ['foo']
            parse '--import foo --import bar' .import `deep-eq` ['foo', 'bar']

    describe '-H, --[no-]headers', (,) ->
        it 'defaults to true' ->
            parse '' .headers `eq` true

        it 'sets `headers` to false' ->
            parse '--no-headers' .headers `eq` false

        it 'sets `headers` to true' ->
            parse '--headers' .headers `eq` true

    it 'wraps function expressions in parentheses' ->
         args = argv.parse [,, 'identity', '-> it']
         args._.1 `eq` '(-> it)'

    it 'reads ".0" as string' ->
         args = argv.parse [,, '.0', '.foo']
         args._.0 `eq` '(.0)'
