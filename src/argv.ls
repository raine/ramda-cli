VERSION = require '../package.json' .version

optionator = require 'optionator' <| do
    prepend: 'Usage: ramda [options] [function] ...'
    append:
        """
        README: https://github.com/raine/ramda-cli

        Version #VERSION
        """
    options: [
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
          description : 'unwraps a list before output so that each item is stringified separately'

        * option      : \output-type
          alias       : \o
          type        : \String
          enum        : <[ pretty csv tsv raw ]>
          description : 'format output sent to stdout'

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
    args

export generate-help = ->
    optionator.generate-help!
        .replace /One of: (.+)  (.*)$/m, (m, vals, desc) ->
            "#desc (one of: #{vals.trim!.to-lower-case!})"
