require! minimist
require! camelize
require! ramda: {map, split, match: match-str, pipe, replace, from-pairs, if-else, identity}

OUTPUT_TYPES     = <[ pretty raw csv tsv table ]>
INPUT_TYPES      = <[ raw csv tsv ]>
format-enum-list = (.join ', ') >> ('one of: ' +)

HELP =
    """
    Usage: ramda [options] [function] ...

      -f, --file         read a function from a js/ls file instead of args; useful for
                         larger scripts
      -c, --compact      compact output for JSON and tables
      -s, --slurp        read JSON objects from stdin as one big list
      -S, --unslurp      unwraps a list before output so that each item is formatted and
                         printed separately
      -i, --input-type   read input from stdin as (#{format-enum-list INPUT_TYPES})
      -o, --output-type  format output sent to stdout (#{format-enum-list OUTPUT_TYPES})
      -p, --pretty       pretty-printed output with colors, alias to -o pretty
      -r, --raw          use raw input and output
      -v, --verbose      print debugging information
          --version      print version
      -h, --help         displays help

    If multiple functions are given as strings, they are composed into a
    pipeline in order from left to right, similarly to R.pipe.

    Example: cat data.json | ramda 'pluck \\name' 'take 5'

    README: https://github.com/raine/ramda-cli
    """

parse-aliases = pipe do
    match-str /-[a-z], --[a-z\-]+/ig
    map replace(/\B-/g, '') >> split ', '
    from-pairs

wrap-in-parens = (str) -> "(#str)"
starts-with    = (str) -> (?index-of(str) is 0)
wrap-functions = map if-else (starts-with '->'), wrap-in-parens, identity

export parse = (argv) ->
    # need to wrap args like '-> it' with parens, otherwise minimist reads
    # them as options
    argv = wrap-functions argv.slice 2
    args = camelize minimist argv,
        string: <[ file input-type output-type ]>
        boolean: <[ compact slurp unslurp pretty verbose version raw ]>
        alias: parse-aliases HELP

    args._ = args.''; delete args.''
    if args.raw    then args.output-type = args.input-type = \raw
    if args.pretty then args.output-type = \pretty

    if args.output-type? and args.output-type not in OUTPUT_TYPES
        throw new Error "Output type should be #{format-enum-list OUTPUT_TYPES}"

    if args.input-type? and args.input-type not in INPUT_TYPES
        throw new Error "Input type should be #{format-enum-list INPUT_TYPES}"

    args

export help = -> HELP
