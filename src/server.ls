require! {path: Path}
require! polka
require! 'serve-static'
require! opn
require! ramda: {without, pipe, join, map}: R
require! querystring
require! 'body-parser'
debug = require 'debug' <| 'ramda-cli:server'

var-args-to-string = pipe do
    map -> if /\s|"/.test(it) then "'#it'" else it
    join ' '

TIMEOUT = 1000
timer = null
start-timer = (cb) ->
    debug "starting timer"
    timer := set-timeout cb, TIMEOUT
clear-timer = ->
    debug "clearing timer"
    clear-timeout timer

export start = (log-error, raw-stdin-buf, process-argv, on-complete) ->
    input = null
    app = polka!
        .use serve-static (Path.join __dirname, '..', 'web-dist'), {'index': ['index.html']}
        .get '/stdin', (req, res) ->
            res.write-head 200, 'Content-Type': 'text/plain'
            res.end raw-stdin-buf
        .post '/update-input', body-parser.text!, (req, res) ->
            debug "received input"
            input := req.body
            res.write-head 200, 'Content-Type': 'text/plain'
            res.end 'OK'
        .get '/alive-check', (req, res) ->
            debug "alive check start"
            if timer then clear-timer!
            req.on 'close', -> start-timer -> on-complete input
        .listen 63958, '127.0.0.1', (err) ->
            debug "listening at port #{app.server.address().port}"
            argv = process-argv .slice 2
                |> without ["--interactive"]
            qs = querystring.stringify input: var-args-to-string argv
            opn "http://localhost:#{app.server.address().port}?#qs", { wait: false }
    return app.server
