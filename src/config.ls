require! path
require! './utils': {HOME}

export BASE_PATH = path.join HOME, \.config, \ramda-cli
export edit = (cb) ->
    require! <[ is-there editor ]>

    get-existing-config-file = ->
        exts = <[ .js .ls ]>
        for ext in exts
            p = BASE_PATH + ext
            return p if is-there p

    if get-existing-config-file! then editor that, cb
    else cb new Error do
        """
        No config file, create one at #BASE_PATH.{js,ls}
        """
