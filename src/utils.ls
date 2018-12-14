export HOME = process.env[if process.platform is 'win32' then \USERPROFILE else \HOME]

export is-browser = ->
    typeof window !== 'undefined' && typeof window.document !== 'undefined'
