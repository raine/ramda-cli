require! {path: Path}
require! polka
require! 'serve-static'
require! opn

export start = (log-error, raw-stdin-buf, process-argv) ->
    app = polka!
        .use serve-static (Path.join __dirname, '..', 'dist'), {'index': ['index.html']}
        .get '/stdin', (req, res) ->
            res.write-head 200, 'Content-Type': 'text/plain'
            res.end raw-stdin-buf
        .get '/argv', (req, res) ->
            res.write-head 200, 'Content-Type': 'application/json'
            res.end JSON.stringify process-argv.slice 2
        .listen 63958, (err) ->
            log-error "listening at port #{app.server.address().port}"
            opn "http://localhost:#{app.server.address().port}", { wait: false }
