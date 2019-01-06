require! {vm, path: Path, fs}
require! <[ ./get-user-config ./config ]>
require! ramda: {apply, map, join, is-empty, split, tap, pipe, identity, reverse, from-pairs, path, reduce, assoc-path, adjust, to-pairs}: R
require! util: {inspect}
require! './utils': {is-browser}
require! camelize

debug = require 'debug' <| 'ramda-cli:compile-fun'
debug.enabled = true if is-browser!

# naive fix to get `match` work despite being a keyword in LS
fix-match = ->
    "#it".replace /\bmatch\b/g, (m, i, str) ->
        if str[i-1] is not \. then \R.match else m

relative-to-cwd = (p) -> Path.join process.cwd!, p
wrap-in = (a, b, str) --> "#a#str#b"
wrap-in-parens = wrap-in \(, \)
wrap-in-pipe = wrap-in \pipe(, \)
lines   = split '\n'
words   = split ' '
unlines = join '\n'
unwords = join ' '
rename-keys-by = (fn, obj) -->
    to-pairs obj
    |> map (adjust fn, 0)
    |> from-pairs

construct-pipe = pipe do
    map wrap-in-parens
    join ','
    wrap-in-pipe

pick-dot-paths = (paths, obj) -->
    reduce do
        (res, p) ->
            val = path p, obj
            if val? then assoc-path p, val, res else res
        {},
        (map (split '.'), paths)

make-sandbox = (opts, imports) ->
    imports-obj = imports
      |> (.map -> [it.alias, it.exports])
      |> from-pairs

    helpers =
        flat           : -> apply (require 'flat'), &
        read-file      : (file-path) -> relative-to-cwd file-path |> fs.read-file-sync _, 'utf8'
        id             : R.identity
        lines          : lines
        words          : words
        unlines        : unlines
        unwords        : unwords
        then           : (fn, promise) --> promise.then(fn)
        pick-dot-paths : pick-dot-paths
        rename-keys-by : rename-keys-by

    helpers._then = helpers.then
    user-config = get-user-config!

    {
        R,
        require,
        console,
        process,
        ...R,
        ...user-config,
        ...helpers,
        ...imports-obj
    }

compile-livescript = (code) ->
    require! livescript
    livescript.compile code, {+bare, -header}

evaluate = (opts, sandbox, code) ->
    vm.run-in-new-context code, sandbox

select-compiler = (opts) ->
    | opts.js   => identity
    | otherwise => compile-livescript

compile-with-opts = (code, opts) ->
    code |> select-compiler opts

compile-and-eval = (code, opts, imports) ->
    sandbox = make-sandbox opts, imports
    compile-with-opts code, opts
    |> tap -> debug "#it", 'compiled code'
    |> evaluate opts, sandbox, _

get-alias-for-installed = (opts-import, installed) ->
  imported = opts-import.find -> it.package-spec is installed.spec
  imported.alias or camelize installed.name

npm-install = (opts) ->>
    if opts.import.length
        require! 'runtime-npm-install': {npm-install-async}
        npm-install-result = await npm-install-async do
            opts.import.map((.packageSpec))
            config.BASE_PATH
        npm-install-result
            |> map ->
                name: it.name
                version: it.json.version
                alias: get-alias-for-installed opts.import, it
                exports: require it.path
    else []

compile-fun = (opts) ->>
    imports = await npm-install opts
    imports.for-each ->
        debug "#{it.name}@#{it.version} installed as #{it.alias}"
    if is-empty opts._ then opts._ = <[ identity ]>
    fns = (if opts.transduce then reverse else identity) opts._
    piped-inline-functions = construct-pipe switch
        | opts.js   => fns
        | otherwise => map fix-match, fns
    debug (inspect piped-inline-functions), 'input code'
    compile-and-eval piped-inline-functions, opts, imports

module.exports = compile-fun
