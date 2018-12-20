require! {path: Path}
require! polka
require! 'serve-static'
require! opn
require! querystring
require! 'body-parser'
debug = require 'debug' <| 'ramda-cli:server'

var-args-to-string = (args) ->
    args.map -> if /\s/.test(it) then "'#it'" else it
        .join ' '

TIMEOUT = 500
timer = null
start-timer = (cb) ->
    debug "starting timer"
    timer := set-timeout cb, TIMEOUT
clear-timer = ->
    debug "clearing timer"
    clear-timeout timer

export start = (log-error, raw-stdin-buf, opts, on-complete) ->
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
            # sending only varargs to browser right now
            qs = querystring.stringify input: var-args-to-string opts._
            opn "http://localhost:#{app.server.address().port}?#qs", { wait: false }
    return app.server
