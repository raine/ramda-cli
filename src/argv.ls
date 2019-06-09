require! minimist
require! camelize
require! ramda: {map, split, match: match-str, pipe, replace, from-pairs, if-else, identity}

OUTPUT_TYPES     = <[ json pretty raw csv tsv table ]>
INPUT_TYPES      = <[ json raw csv tsv ]>
format-enum-list = (.join ', ') >> ('one of: ' +)

HELP =
    """
    Usage: ramda [options] [function] ...

      -I, --interactive    run interactively in browser
      -f, --file           read a function from a js/ls file instead of args; useful for
                           larger scripts
      -c, --compact        compact output for JSON and tables
      -s, --slurp          read JSON objects from stdin as one big list
      -S, --unslurp        unwraps a list before output so that each item is formatted and
                           printed separately
      -t, --transduce      use pipeline as a transducer to transform stdin
      -P, --json-path      parse stream with JSONPath expression
      -i, --input-type     read input from stdin as (#{format-enum-list INPUT_TYPES})
      -o, --output-type    format output sent to stdout (#{format-enum-list OUTPUT_TYPES})
      -p, --pretty         pretty-printed output with colors, alias to -o pretty
      -D, --pretty-depth   set how deep objects are pretty printed
      -r, --raw-input      alias for --input-type raw
      -R, --raw-output     alias for --output-type raw
      -n, --no-stdin       don't read input from stdin
          --[no-]headers   csv/tsv has a header row
          --csv-delimiter  custom csv delimiter character
          --js             use javascript instead of livescript
          --import         import a module from npm
      -C, --configure      edit config in $EDITOR
      -v, --verbose        print debugging information (use -vv for even more)
          --version        print version
      -h, --help           displays help

    If multiple functions are given as strings, they are composed into a
    pipeline in order from left to right, similarly to R.pipe.

    Examples:

      curl -Ls http://bit.do/countries-json | ramda 'take 5' 'pluck \\name' --pretty
      curl -Ls http://bit.do/countries-json | ramda 'find where-eq code: \\FI'
      curl -Ls http://bit.do/countries-json | ramda --js 'filter(c => test(/land$/, c.name))'
      seq 10 | ramda --raw-input --slurp 'map parse-int' sum
      date +%s | ramda -r --import moment:m 'm.unix'


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

parse-raw-import = (str) ->
    [package-spec, alias] = str.split ':'
    {package-spec, alias}

parse-imports = (argv-import) ->
    imports-raw-arr = if typeof argv-import == 'string' then [argv-import] else argv-import
    imports-raw-arr.map parse-raw-import

export parse = (argv) ->
    # HACKS:
    # - wrap '-> it' style lambdas in parens, minimist thinks they're options
    # - wrap implicit number lookups '.0' in parens, minimist thinks they're numbers
    argv = map (wrap-number-lookup << wrap-function), argv.slice 2
    opts = camelize minimist argv,
        string: <[ file input-type output-type json-path csv-delimiter ]>
        boolean: <[ compact slurp unslurp pretty verbose version raw-input raw-output configure no-stdin js transduce headers interactive ]>
        alias: parse-aliases HELP
        default: {
            +stdin,
            +headers,
            'csv-delimiter': \,
            'import': [],
            'input-type': 'json'
            'output-type': 'json'
        }

    opts._ = opts.''; delete opts.''

    if opts.raw-input  then opts.input-type  = \raw
    if opts.raw-output then opts.output-type = \raw
    if opts.pretty     then opts.output-type = \pretty

    if opts.output-type? and opts.output-type not in OUTPUT_TYPES
        throw new Error "Output type should be #{format-enum-list OUTPUT_TYPES}"

    if opts.input-type? and opts.input-type not in INPUT_TYPES
        throw new Error "Input type should be #{format-enum-list INPUT_TYPES}"

    if '-vv' in argv then opts.very-verbose = true
    if '-n'  in argv then opts.stdin = false

    opts.import = parse-imports opts.import

    if opts.input-type  in <[ csv tsv ]> then opts.slurp   = true
    if opts.output-type in <[ csv tsv ]> then opts.unslurp = true

    opts

export help = -> HELP
