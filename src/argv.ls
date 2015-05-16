VERSION = require '../package.json' .version

optionator = require 'optionator' <| do
    prepend: 'Usage: ramda [options] [function]'
    append:
        """
        README: https://github.com/raine/ramda-cli

        Version #VERSION
        """
    options: [
        * option      : \compact
          alias       : \c
          type        : \Boolean
          description : 'compact output'

        * option      : \inspect
          alias       : \i
          type        : \Boolean
          description : 'pretty-printed output with colors'

        * option      : \slurp
          alias       : \s
          type        : \Boolean
          description : 'read JSON objects from stdin as one big list'

        * option      : \unslurp
          alias       : \S
          type        : \Boolean
          description : 'unwraps a list before output so that each item is stringified separately'

        * option      : \raw-output
          alias       : \r
          type        : \Boolean
          description : 'raw output'

        * option      : \output-type
          alias       : \o
          type        : \String
          enum        : <[ csv tsv ]>
          description : 'output type'

        * option      : \help
          alias       : \h
          type        : \Boolean
          description : 'displays help'
    ]

export parse         = optionator.parse
export generate-help = optionator.generate-help
