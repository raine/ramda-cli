require! path: Path
require! 'is-there'
require! './utils': {HOME}

export BASE_PATH = Path.join HOME, \.config, \ramda-cli
export get-existing-config-file = ->
    exts = <[ .js .ls ]>
    for ext in exts
        p = BASE_PATH + ext
        return p if is-there p

export edit = (cb) ->
    require! editor

    if get-existing-config-file! then editor that, cb
    else cb new Error do
        """
        No config file, create one at #BASE_PATH.{js,ls}
        """
