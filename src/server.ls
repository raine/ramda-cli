require! {path: Path, fs}
require! polka
require! 'serve-static'
require! opn
require! ramda: {without, pipe, join, map}: R
require! stream: {finished}
require! querystring
require! 'stream-concat': StreamConcat
require! 'body-parser'
require! 'tempfile'
require! 'compression'
require! 'string-argv'
require! <[ ./argv ./compile-fun ]>
require! './stream': {process-input-stream}
debug = require 'debug' <| 'ramda-cli:server'

var-args-to-string = pipe do
    map -> if /\s|"/.test(it) then "'#it'" else it
    -> if it.length > 3 then it.join '\n' else it.join ' '

TIMEOUT = 1000
timer = null
start-timer = (cb) ->
    debug "starting timer"
    timer := set-timeout cb, TIMEOUT
clear-timer = ->
    debug "clearing timer"
    clear-timeout timer

export start = (log-error, stdin, process-argv, on-complete) ->
    stdin-finished = false
    tmp-file-path = tempfile!
    stdin-tmp-file = fs.create-write-stream tmp-file-path, flags: 'w'
    finished stdin, (err) -> stdin-finished := true
    input = null
    stdin.pipe stdin-tmp-file
    temp-file-stream = -> fs.create-read-stream tmp-file-path, flags: 'r'
    on-close = ->
        on-complete do
            if stdin-finished then temp-file-stream!
            else new StreamConcat([ temp-file-stream!, stdin ])
            input

    app = polka!
        .use compression {
            # streamed /stdin does not work with gzip enabled for some reason
            filter: (req, res) ->
                if req.path is '/eval' then false
                else compression.filter(req, res)
        }
        .use serve-static (Path.join __dirname, '..', 'web-dist'), {'index': ['index.html']}
        .post '/eval', body-parser.text!, (req, res) ->
            res.set-header 'Content-Type', 'text/plain'
            input := req.body
            debug input
            opts = argv.parse string-argv input, 'node', 'dummy.js'
            on-error = (err) ->
                res.write-head 400
                res.end err.stack
            try fun = compile-fun opts
            catch err then return on-error err
            new-stdin =
                # If --slurp is used, process-input-stream will wait for the
                # input stream to end, because you can't wrap the input in an
                # array without having it end first. In case --slurp is used
                # with indefinite input stream, we have to use only input
                # gathered so far from the temp file. Otherwise the request will
                # be pending until stdin ends.
                if opts.slurp or stdin-finished
                    temp-file-stream!
                else
                    read-stream = temp-file-stream!
                    combined = new StreamConcat([ read-stream, stdin ])
                    req.on 'close', -> combined.destroy!
                    combined
            process-input-stream do
                on-error
                opts
                fun
                new-stdin
                res
        .get '/alive-check', (req, res) ->
            debug "alive check start"
            if timer then clear-timer!
            req.on 'close', -> start-timer on-close
        .listen 63958, '127.0.0.1', (err) ->
            debug "listening at port #{app.server.address().port}"
            argv = process-argv .slice 2
                |> without ["--interactive"]
            qs = querystring.stringify input: var-args-to-string argv
            opn "http://localhost:#{app.server.address().port}?#qs", { wait: false }
    return app.server
