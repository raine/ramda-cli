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
    on-close = -> on-complete (fs.create-read-stream tmp-file-path, flags: 'r'), input
    stdin.pipe stdin-tmp-file

    app = polka!
        .use compression {
            # streamed /stdin does not work with gzip enabled for some reason
            filter: (req, res) ->
                if req.path is '/stdin' then false
                else compression.filter(req, res)
        }
        .use serve-static (Path.join __dirname, '..', 'web-dist'), {'index': ['index.html']}
        .get '/stdin', (req, res) ->
            res.write-head 200, 'Content-Type': 'application/json'
            if stdin-finished
                fs.create-read-stream tmp-file-path, flags: 'r'
                    .pipe res
            else
                read-stream = fs.create-read-stream tmp-file-path, flags: 'r'
                combined = new StreamConcat([ read-stream, stdin ])
                combined.pipe res
                req.on 'close', -> combined.destroy!
        .post '/update-input', body-parser.text!, (req, res) ->
            debug "received input"
            input := req.body
            res.write-head 200, 'Content-Type': 'text/plain'
            res.end 'OK'
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
