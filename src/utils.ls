require! ramda: {split, join, take}: R

export lines   = split '\n'
export words   = split ' '
export unlines = join '\n'
export unwords = join ' '

export HOME = process.env[if process.platform is 'win32' then \USERPROFILE else \HOME]

export is-thenable = (x) -> x and typeof x.then is 'function'

export is-browser = ->
    typeof importScripts is 'function' ||
    typeof window is not 'undefined' && typeof window.document is not 'undefined'

export take-lines = (n, str) -->
    lines str |> take n |> unlines

export remove-extra-newlines = (str) ->
    if /\n$/ == str then str.replace /\n*$/, '\n' else str
