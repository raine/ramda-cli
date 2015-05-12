VERSION = require '../package.json' .version

optionator = require 'optionator' <| do
    prepend: 'Usage: ramda [options] [code]'
    append: "Version #VERSION"
    options: [
        * option      : \compact
          alias       : \c
          type        : \Boolean
          description : 'compact output'
        * option      : \help
          alias       : \h
          type        : \Boolean
          description : 'displays help'
    ]

export parse         = optionator.parse
export generate-help = optionator.generate-help
