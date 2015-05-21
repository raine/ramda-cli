OUTPUT_TYPES     = <[ pretty raw csv tsv ]>
INPUT_TYPES      = <[ raw csv tsv ]>
format-enum-list = (.join ', ') >> ('one of: ' +)

optionator = require 'optionator' <| do
    prepend: 'Usage: ramda [options] [function] ...'
    append:
        """
        If multiple functions are given as strings, they are composed into a
        pipeline in order from left to right, similarly to R.pipe.

        Example: cat data.json | ramda 'pluck \\name' 'take 5'

        README: https://github.com/raine/ramda-cli
        """
    options: [
        * option      : \file
          alias       : \f
          type        : \String
          description : 'read a function from a js/ls file instead of args; useful for larger scripts'

        * option      : \compact
          alias       : \c
          type        : \Boolean
          description : 'compact JSON output'

        * option      : \slurp
          alias       : \s
          type        : \Boolean
          description : 'read JSON objects from stdin as one big list'

        * option      : \unslurp
          alias       : \S
          type        : \Boolean
          description : 'unwraps a list before output so that each item is formatted and printed separately'

        * option      : \input-type
          alias       : \i
          type        : \String
          description : "read input from stdin as (#{format-enum-list INPUT_TYPES})"

        * option      : \output-type
          alias       : \o
          type        : \String
          description : "format output sent to stdout (#{format-enum-list OUTPUT_TYPES})"

        * option      : \pretty
          alias       : \p
          type        : \Boolean
          description : 'pretty-printed output with colors, alias to -o pretty'

        * option      : \raw-output
          alias       : \r
          type        : \Boolean
          description : 'raw output, alias to -o raw'

        * option      : \help
          alias       : \h
          type        : \Boolean
          description : 'displays help'
    ]

export parse = (argv) ->
    args = optionator.parse argv
    if args.pretty     then args.output-type = \pretty
    if args.raw-output then args.output-type = \raw

    if args.output-type? and args.output-type not in OUTPUT_TYPES
        throw new Error "Output type should be #{format-enum-list OUTPUT_TYPES}"

    if args.input-type? and args.input-type not in INPUT_TYPES
        throw new Error "Input type should be #{format-enum-list INPUT_TYPES}"

    args

export generate-help = optionator.generate-help
