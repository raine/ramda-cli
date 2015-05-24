#!/usr/bin/env lsc

require! {livescript, vm, JSONStream, path, 'stream-reduce', split2}
require! through2: through
require! stream: {PassThrough}
require! ramda: {apply, is-nil, append, flip, type, replace, merge, map, join, for-each, split, head}: R
require! util: {inspect}
require! './argv'
debug = require 'debug' <| 'ramda-cli:main'

process.env.'NODE_PATH' = path.join process.env.HOME, 'node_modules'
require 'module' .Module._init-paths!

lines = split '\n'
remove-extra-newlines = (str) ->
    if /\n$/ == str then str.replace /\n*$/, '\n' else str

wrap-in-parens = (str) -> "(#str)"

compile-and-eval = (code) ->
    compiled = livescript.compile code, {+bare, -header}
    debug (inspect compiled), 'compiled code'
    sandbox = {R, require} <<< R
    sandbox.treis = -> apply (require 'treis'), &
    ctx = vm.create-context sandbox
    vm.run-in-context compiled, ctx

concat-stream   = -> stream-reduce flip(append), []
unconcat-stream = -> through.obj (chunk,, next) ->
    switch type chunk
    | \Array    => for-each this~push, chunk
    | otherwise => this.push chunk
    next!

raw-output-stream = -> through.obj (chunk,, next) ->
    switch type chunk
    | \Array    => for-each (~> this.push "#it\n"), chunk
    | otherwise => this.push remove-extra-newlines chunk.to-string!
    next!

inspect-stream = -> through.obj (chunk,, next) ->
    this.push (inspect chunk, colors: true) + '\n'
    next!

debug-stream = (debug, str) ->
    unless debug.enabled then return PassThrough {+object-mode}
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

map-stream = (func) -> through.obj (chunk,, next) ->
    val = func chunk
    this.push val unless is-nil val
    next!

table-output-stream = ->
    require! './format-table'
    through.obj (chunk,, next) ->
        this.push "#{format-table chunk}\n"
        next!

csv-opts-by-type = (type) ->
    opts = headers: true
    switch type
    | \csv => opts
    | \tsv => opts <<< delimiter: '\t'

output-type-to-stream = (type, compact-json) ->
    switch type
    | \pretty       => inspect-stream!
    | \raw          => raw-output-stream!
    | <[ csv tsv ]> => require 'fast-csv' .create-write-stream csv-opts-by-type type
    | \table        => table-output-stream!
    | otherwise     => json-stringify-stream compact-json

input-type-to-stream = (type) ->
    switch type
    | \raw          => split2!
    | <[ csv tsv ]> => (require 'fast-csv') csv-opts-by-type type
    | otherwise     => JSONStream.parse!

main = (process-argv, stdin, stdout, stderr) ->
    debug {argv: process-argv}
    log-error = (+ '\n') >> stderr~write
    die       = log-error >> -> process.exit 1

    try opts = argv.parse process-argv
    catch e then return die [argv.help!, e.message] * '\n\n'
    debug opts

    if opts.help    then return die argv.help!
    if opts.version then return die <| require '../package.json' .version

    if opts.file
        try fun = require path.resolve opts.file
        catch {stack, code}
            return switch code
            | \MODULE_NOT_FOUND  => die head lines stack
            | otherwise          => die stack

        unless typeof fun is 'function'
            return die "Error: #{opts.file} does not export a function"
    else
        code = join ' >> ', map wrap-in-parens, opts._
        debug (inspect code), 'input code'
        if not code then return die argv.help!

        try fun = compile-and-eval code
        catch {message}
            return die "Error: #{message}"

        debug (inspect fun), 'evaluated to'
        unless typeof fun is 'function'
            return die "Error: evaluated into type of #{type fun} instead of Function"

    if opts.input-type in <[ csv tsv ]>
        opts.slurp = true

    if opts.output-type in <[ csv tsv ]>
        opts.unslurp = true

    input-parser     = input-type-to-stream opts.input-type
    output-formatter = output-type-to-stream opts.output-type, opts.compact

    stdin
        .pipe debug-stream debug, \stdin
        .pipe input-parser
        .pipe pass-through-unless opts.slurp, concat-stream!
        .pipe map-stream fun
        .pipe pass-through-unless opts.unslurp, unconcat-stream!
        .pipe output-formatter
        .pipe debug-stream debug, \stdout
        .pipe stdout

module.exports = main
