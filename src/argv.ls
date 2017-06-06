require! minimist
require! camelize
require! ramda: {map, split, match: match-str, pipe, replace, from-pairs, if-else, identity}

OUTPUT_TYPES     = <[ pretty raw csv tsv table ]>
INPUT_TYPES      = <[ raw csv tsv ]>
format-enum-list = (.join ', ') >> ('one of: ' +)

HELP =
    """
    Usage: ramda [options] [function] ...

      -f, --file          read a function from a js/ls file instead of args; useful for
                          larger scripts
      -c, --compact       compact output for JSON and tables
      -s, --slurp         read JSON objects from stdin as one big list
      -S, --unslurp       unwraps a list before output so that each item is formatted and
                          printed separately
      -t, --transduce     use pipeline as a transducer to transform stdin
      -P, --json-path     parse stream with JSONPath expression
      -i, --input-type    read input from stdin as (#{format-enum-list INPUT_TYPES})
      -o, --output-type   format output sent to stdout (#{format-enum-list OUTPUT_TYPES})
      -p, --pretty        pretty-printed output with colors, alias to -o pretty
      -D, --pretty-depth  set how deep objects are pretty printed
      -r, --raw-input     alias for --input-type raw
      -R, --raw-output    alias for --output-type raw
      -n, --no-stdin      don't read input from stdin
          --[no-]headers  csv/tsv has a header row
          --js            use javascript instead of livescript
      -I, --import        require module as a variable
      -C, --configure     edit config in $EDITOR
      -v, --verbose       print debugging information (use -vv for even more)
          --version       print version
      -h, --help          displays help

    If multiple functions are given as strings, they are composed into a
    pipeline in order from left to right, similarly to R.pipe.

    Examples:

      curl -Ls http://bit.do/countries-json | ramda 'take 5' 'pluck \\name' --pretty
      curl -Ls http://bit.do/countries-json | ramda 'find where-eq code: \\FI'
      curl -Ls http://bit.do/countries-json | ramda --js 'filter(c => test(/land$/, c.name))'
      seq 10 | ramda --raw-input --slurp 'map parse-int' sum
      npm install moment && date +%s | ramda -r --import m=moment 'm.unix'


    README: https://github.com/raine/ramda-cli
    """

parse-aliases = pipe do
    match-str /-[a-z], --[a-z\-]+/ig
    map replace(/\B-/g, '') >> split ', '
    from-pairs

wrap-in-parens     = (str) -> "(#str)"
starts-with        = (str) -> (?index-of(str) is 0)
wrap-function      = if-else (starts-with '->'), wrap-in-parens, identity
wrap-number-lookup = if-else (.match /^.\d+$/), wrap-in-parens, identity

export parse = (argv) ->
    # HACKS:
    # - wrap '-> it' style lambdas in parens, minimist thinks they're options
    # - wrap implicit number lookups '.0' in parens, minimist thinks they're numbers
    argv = map (wrap-number-lookup << wrap-function), argv.slice 2
    args = camelize minimist argv,
        string: <[ file input-type output-type json-path ]>
        boolean: <[ compact slurp unslurp pretty verbose version raw-input raw-output configure no-stdin js transduce headers ]>
        alias: parse-aliases HELP
        default: {+stdin, +headers}

    args._ = args.''; delete args.''

    if args.raw-input  then args.input-type  = \raw
    if args.raw-output then args.output-type = \raw
    if args.pretty     then args.output-type = \pretty

    if args.output-type? and args.output-type not in OUTPUT_TYPES
        throw new Error "Output type should be #{format-enum-list OUTPUT_TYPES}"

    if args.input-type? and args.input-type not in INPUT_TYPES
        throw new Error "Input type should be #{format-enum-list INPUT_TYPES}"

    if '-vv' in argv then args.very-verbose = true
    if '-n'  in argv then args.stdin = false

    args.import = typeof args.import == \string and [args.import] or args.import

    args

export help = -> HELP
