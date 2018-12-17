require! {path: Path}
require! polka
require! 'serve-static'
require! opn
require! querystring

var-args-to-string = (args) ->
    args.map -> if /\s/.test(it) then "'#it'" else it
        .join ' '

export start = (log-error, raw-stdin-buf, opts) ->
    app = polka!
        .use serve-static (Path.join __dirname, '..', 'dist'), {'index': ['index.html']}
        .get '/stdin', (req, res) ->
            res.write-head 200, 'Content-Type': 'text/plain'
            res.end raw-stdin-buf
        .listen 63958, (err) ->
            log-error "listening at port #{app.server.address().port}"
            qs = querystring.stringify input: var-args-to-string opts._
            opn "http://localhost:#{app.server.address().port}?#qs", { wait: false }
