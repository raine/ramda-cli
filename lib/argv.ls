VERSION = require '../package.json' .version

optionator = require 'optionator' <| do
    prepend: 'Usage: ramda [options] [function]'
    append: "Version #VERSION"
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
        * option      : \help
          alias       : \h
          type        : \Boolean
          description : 'displays help'
    ]

export parse         = optionator.parse
export generate-help = optionator.generate-help
