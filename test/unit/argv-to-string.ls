argv-to-string = require '../../src/argv-to-string'

describe 'argv-to-string' (,) ->
    it 'args on single line' (,) ->
        argv = ['-o', 'table', '--compact']
        argv-to-string(argv) `eq` "-o table --compact"

    it 'wraps an item with space in single quotes' (,) ->
        argv = ['take 1']
        argv-to-string(argv) `eq` "'take 1'"

    it 'wraps an item with double quote in single quotes' (,) ->
        argv = ['prop("foo")']
        argv-to-string(argv) `eq` """'prop("foo")'"""

    it 'puts var args with single quotes on their own line' (,) ->
        argv = [
            'filter -> true'
            'take 10'
            'map pick ["name", "mac"]'
        ]
        argv-to-string(argv) `eq` """
        'filter -> true'
        'take 10'
        'map pick ["name", "mac"]'
        """

    it 'formats consecutive parameter on single line at start' (,) ->
        argv = [
            '-o',
            'table',
            '--compact',
            'filter -> true'
            'take 10'
            'map pick ["name", "mac"]'
        ]
        argv-to-string(argv) `eq` """
        -o table --compact
        'filter -> true'
        'take 10'
        'map pick ["name", "mac"]'
        """

    it 'formats consecutive parameter on single line at end' (,) ->
        argv = [
            'filter -> true'
            'take 10'
            'map pick ["name", "mac"]'
            '-o',
            'table',
            '--compact'
        ]
        argv-to-string(argv) `eq` """
        'filter -> true'
        'take 10'
        'map pick ["name", "mac"]'
        -o table --compact
        """

    it 'formats consecutive parameter on single line in middle' (,) ->
        argv = [
            'filter -> true'
            'take 10'
            '--output-type'
            'csv'
            'map pick ["name", "mac"]'
        ]
        argv-to-string(argv) `eq` """
        'filter -> true'
        'take 10'
        --output-type csv
        'map pick ["name", "mac"]'
        """
