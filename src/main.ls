#!/usr/bin/env lsc
require! {vm, JSONStream, path, split2, fs, camelize}
require! <[ ./argv ./config ]>
require! through2: through
require! stream: {PassThrough}
require! ramda: {apply, is-nil, append, flip, type, replace, merge, map, join, for-each, split, head, pick-by, tap, pipe, concat, take, identity, is-empty, reverse, invoker, from-pairs}: R
require! util: {inspect}
require! './utils': {HOME}
debug = require 'debug' <| 'ramda-cli:main'
Module = require 'module' .Module

# caveat: require will still prioritize ramda-cli's own node_modules
process.env.'NODE_PATH' = join ':', [
    path.join(process.cwd(), 'node_modules')
    path.join(HOME, 'node_modules') ]

Module._init-paths!

# naive fix to get `match` work despite being a keyword in LS
fix-match = ->
    "#it".replace /\bmatch\b/g, (m, i, str) ->
        if str[i-1] is not \. then \R.match else m

lines   = split '\n'
words   = split ' '
unlines = join '\n'
unwords = join ' '

remove-extra-newlines = (str) ->
    if /\n$/ == str then str.replace /\n*$/, '\n' else str

is-thenable = (x) -> x and typeof x.then is 'function'
str-contains = (x, xs) ~> (xs.index-of x) >= 0
wrap-in = (a, b, str) --> "#a#str#b"
wrap-in-parens = wrap-in \(, \)
wrap-in-pipe = wrap-in \pipe(, \)
relative-to-cwd = path.join process.cwd!, _
construct-pipe = pipe do
    map wrap-in-parens
    join ','
    wrap-in-pipe

take-lines = (n, str) -->
    lines str |> take n |> unlines

make-sandbox = (opts) ->
    imports = opts.import or []
        |> map split('=')
        |> map ([alias, pkg]) ->
            pkg = pkg or alias
            debug "requiring #pkg", require.resolve pkg
            [camelize(alias), require pkg]
        |> from-pairs

    helpers =
        flat      : -> apply (require 'flat'), &
        read-file : relative-to-cwd >> fs.read-file-sync _, 'utf8'
        id        : R.identity
        lines     : lines
        words     : words
        unlines   : unlines
        unwords   : unwords
        then      : (fn, promise) --> promise.then(fn)

    helpers._then = helpers.then

    config-file-path = config.get-existing-config-file!
    if config-file-path?.match /\.ls$/ then require! livescript
    try user-config = require config.BASE_PATH
    catch e
        unless (e.code is 'MODULE_NOT_FOUND' and str-contains (path.join '.config', 'ramda-cli'), e.message)
            throw e

    {R, require} <<< R <<< user-config <<< helpers <<< imports

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

reduce-stream = (fn, acc) -> through.obj do
    (chunk,, next) ->
        acc := fn acc, chunk
        next!
    (next) ->
        this.push acc
        next!

concat-stream   = -> reduce-stream flip(append), []
unconcat-stream = -> through.obj (chunk,, next) ->
    switch type chunk
    | \Array    => for-each this~push, chunk
    | otherwise => this.push chunk
    next!

raw-output-stream = (compact) -> through.obj (chunk,, next) ->
    end = unless compact then "\n" else ''
    switch type chunk
    | \Array    => for-each (~> this.push "#it#end"), chunk
    | otherwise => this.push remove-extra-newlines "#chunk#end"
    next!

inspect-stream = (depth) -> through.obj (chunk,, next) ->
    this.push (inspect chunk, colors: true, depth: depth) + '\n'
    next!

debug-stream = (debug, opts, str) ->
    unless debug.enabled and opts.very-verbose
        return PassThrough {+object-mode}

    through.obj (chunk,, next) ->
        debug {"#str": chunk.to-string!}
        this.push chunk
        next!

json-stringify-stream = (compact) ->
    indent = if not compact then 2 else void
    through.obj (data,, next) ->
        json = JSON.stringify data, null, indent
        this.push json + '\n'
        next!

pass-through-unless = (val, stream) ->
    switch | val       => stream
           | otherwise => PassThrough object-mode: true

map-stream = (func, on-error) -> through.obj (chunk,, next) ->
    push = (x) ~>
        # pushing a null would end the stream
        this.push x unless is-nil x
        next!
    val = try func chunk
    catch then on-error e
    if is-thenable val then val.then push
    else push val

table-output-stream = (compact) ->
    require! './format-table'
    opts = {compact}
    through.obj (chunk,, next) ->
        this.push "#{format-table chunk, opts}\n"
        next!

csv-opts-by-type = (type) ->
    opts = headers: true
    switch type
    | \csv => opts
    | \tsv => opts <<< delimiter: '\t'

opts-to-output-stream = (opts) ->
    switch opts.output-type
    | \pretty       => inspect-stream opts.pretty-depth
    | \raw          => raw-output-stream opts.compact
    | <[ csv tsv ]> => require 'fast-csv' .create-write-stream csv-opts-by-type opts.output-type
    | \table        => table-output-stream opts.compact
    | otherwise     => json-stringify-stream opts.compact

opts-to-input-stream = (opts) ->
    switch opts.input-type
    | \raw          => split2!
    | <[ csv tsv ]> => (require 'fast-csv') csv-opts-by-type opts.input-type
    | otherwise     => JSONStream.parse opts.json-path

blank-obj-stream = ->
    PassThrough {+object-mode}
        ..end {}

main = (process-argv, stdin, stdout, stderr) ->
    stdout.on \error ->
        if it.code is 'EPIPE' then process.exit 0

    debug {argv: process-argv}
    log-error = (+ '\n') >> stderr~write
    die       = log-error >> -> process.exit 1

    try opts = argv.parse process-argv
    catch e then return die [argv.help!, e.message] * '\n\n'
    debug pick-by (is not false), opts

    if opts.help    then return die argv.help!
    if opts.version then return die <| require '../package.json' .version
    if opts.configure
        return config.edit (err) ->
            if err != 0 or err then die err
            else process.exit 0

    if opts.file
        try fun = require path.resolve opts.file
        catch {stack, code}
            return switch code
            | \MODULE_NOT_FOUND  => die head lines stack
            | otherwise          => die stack

        unless typeof fun is 'function'
            return die "Error: #{opts.file} does not export a function"

        if fun.opts then opts <<< argv.parse [,,] ++ words fun.opts
    else
        if is-empty opts._ then return die argv.help!
        fns = (if opts.transduce then reverse else identity) opts._
        piped-inline-functions = construct-pipe switch
            | opts.js   => fns
            | otherwise => map fix-match, fns

        debug (inspect piped-inline-functions), 'input code'
        try fun = compile-and-eval piped-inline-functions, opts
        catch {message} then return die "Error: #{message}"

    if opts.input-type  in <[ csv tsv ]> then opts.slurp   = true
    if opts.output-type in <[ csv tsv ]> then opts.unslurp = true

    input-parser = opts-to-input-stream opts
    output-formatter = opts-to-output-stream opts

    stdin-parser = ->
        stdin
        .pipe debug-stream debug, opts, \stdin
        .pipe input-parser .on \error -> die it
        .pipe pass-through-unless opts.slurp, concat-stream!

    mapper =
        if opts.transduce then (require 'transduce-stream') fun, {+object-mode}
        else map-stream fun, -> die (take-lines 3, it.stack)

    (if opts.stdin then stdin-parser! else blank-obj-stream!)
        .pipe mapper
        .pipe pass-through-unless opts.unslurp, unconcat-stream!
        .pipe output-formatter
        .pipe debug-stream debug, opts, \stdout
        .pipe stdout

module.exports = main
