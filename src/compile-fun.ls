require! {vm, path: Path, fs}
require! <[ ./config ./get-user-config ]>
require! ramda: {apply, is-nil, append, flip, type, replace, merge, map, join, for-each, split, head, pick-by, tap, pipe, concat, take, identity, is-empty, reverse, invoker, from-pairs, merge-all, path, reduce, obj-of, assoc-path, adjust, to-pairs}: R
require! util: {inspect}
debug = require 'debug' <| 'ramda-cli:compile-fun'

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

make-sandbox = (opts) ->
    imports = opts.import or []
        |> map split('=')
        |> map ([alias, pkg]) ->
            pkg = pkg or alias
            debug "requiring #pkg", require.resolve pkg
            [camelize(alias), require pkg]
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

    {R, require, console, process} <<< R <<< user-config <<< helpers <<< imports

compile-livescript = (code) ->
    require! livescript
    livescript.compile code, {+bare, -header}

evaluate = (opts, code) -->
    ctx = vm.create-context make-sandbox opts
    vm.run-in-context code, ctx

select-compiler = (opts) ->
    | opts.js   => identity
    | otherwise => compile-livescript

compile-with-opts = (code, opts) ->
    code |> select-compiler opts

compile-and-eval = (code, opts) ->
    compile-with-opts code, opts
    |> tap -> debug "\n#it", 'compiled code'
    |> evaluate opts

compile-fun = (opts, die) ->
    fns = (if opts.transduce then reverse else identity) opts._
    piped-inline-functions = construct-pipe switch
        | opts.js   => fns
        | otherwise => map fix-match, fns

    debug (inspect piped-inline-functions), 'input code'
    try compile-and-eval piped-inline-functions, opts
    catch {message} then return die "Error: #{message}"

module.exports = compile-fun
