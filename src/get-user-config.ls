require! {path: Path}
require! <[ ./config ]>
require! './utils': {is-browser}

str-contains = (x, xs) ~> (xs.index-of x) >= 0

get-user-config = ->
    unless is-browser!
        config-file-path = config.get-existing-config-file!
        if config-file-path?.match /\.ls$/ then require! livescript
        try require config.BASE_PATH
        catch e
            unless (e.code is 'MODULE_NOT_FOUND' and str-contains (Path.join '.config', 'ramda-cli'), e.message)
                throw e

module.exports = get-user-config
