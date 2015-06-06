require! '../../src/format-table'
require! 'strip-ansi'
format = strip-ansi << format-table

describe 'format-table' (,) ->
    describe 'options' (,) ->
        it 'accepts {compact: Boolean}' ->
            objs =
                * name: 'Afghanistan', code: 'AF'
                * name: 'Åland Islands', code: 'AX'
                * name: 'Albania', code: 'AL'

            (format objs, compact: true) `eq` do
                """
                ┌───────────────┬──────┐
                │ name          │ code │
                ├───────────────┼──────┤
                │ Afghanistan   │ AF   │
                │ Åland Islands │ AX   │
                │ Albania       │ AL   │
                └───────────────┴──────┘
                """

    it 'formats a list of objects with first object\'s keys as header' ->
        objs =
            * name: 'Afghanistan', code: 'AF'
            * name: 'Åland Islands', code: 'AX'
            * name: 'Albania', code: 'AL'

        (format objs) `eq` do
            """
            ┌───────────────┬──────┐
            │ name          │ code │
            ├───────────────┼──────┤
            │ Afghanistan   │ AF   │
            ├───────────────┼──────┤
            │ Åland Islands │ AX   │
            ├───────────────┼──────┤
            │ Albania       │ AL   │
            └───────────────┴──────┘
            """

    it 'flattens a list of objects' ->
        objs =
            * a: {b: \foo}, c: [1,2,3]
            * a: {b: \bar}, c: [3,2,1]

        (format objs) `eq` do
            """
            ┌─────┬─────┬─────┬─────┐
            │ a.b │ c.0 │ c.1 │ c.2 │
            ├─────┼─────┼─────┼─────┤
            │ foo │ 1   │ 2   │ 3   │
            ├─────┼─────┼─────┼─────┤
            │ bar │ 3   │ 2   │ 1   │
            └─────┴─────┴─────┴─────┘
            """

    it 'formats a list of strings' ->
        list = <[ foo bar xyz ]>
        (format list) `eq` do
            """
            ┌─────┐
            │ foo │
            ├─────┤
            │ bar │
            ├─────┤
            │ xyz │
            └─────┘
            """

    it 'formats a list of lists' ->
        list = [ <[ foo bar ]> <[ hello world ]> ]
        (format list) `eq` do
            """
            ┌───────┬───────┐
            │ foo   │ bar   │
            ├───────┼───────┤
            │ hello │ world │
            └───────┴───────┘
            """

    it 'formats a vertical table' ->
        obj = name: 'Afghanistan', code: 'AF'
        (format obj) `eq` do
            """
            ┌──────┬─────────────┐
            │ name │ Afghanistan │
            ├──────┼─────────────┤
            │ code │ AF          │
            └──────┴─────────────┘
            """

    it 'formats a string' ->
        (format 'foo') `eq` do
            """
            ┌─────┐
            │ foo │
            └─────┘
            """

    it 'formats a number' ->
        (format 1) `eq` do
            """
            ┌───┐
            │ 1 │
            └───┘
            """

    it 'formats a function' ->
        (format (->)) `eq` do
            """
            ┌───────────────┐
            │ function (){} │
            └───────────────┘
            """

    it 'formats a boolean' ->
        (format true) `eq` do
            """
            ┌──────┐
            │ true │
            └──────┘
            """
