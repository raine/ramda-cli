import * as R from 'ramda'
import http from 'stream-http'
import { parse, help } from '../lib/argv'
import { lines, unlines } from '../lib/utils'
import stringArgv from 'string-argv'

const debug = require('debug')('ramda-cli:web:worker')
debug.enabled = true
debug('worker initialized')

const encoder = new TextEncoder('utf-8')
const encode = encoder.encode.bind(encoder)

const removeCommentedLines = R.pipe(
  lines,
  R.reject((x) => /^#/.test(x)),
  unlines
)

let evalHttpReq
let gotFirstChunk = false
let stream
let cleanup

const onEvalInput = ({ input }) => {
  gotFirstChunk = false
  if (evalHttpReq) {
    evalHttpReq.abort()
    cleanup()
  }

  const argv = stringArgv(removeCommentedLines(input), 'node', 'dummy.js')

  try {
    opts = parse(argv)
  } catch (err) {
    self.postMessage({
      event: 'EVAL_OUTPUT_CHUNK',
      chunk: encode(err.stack),
      opts,
      firstChunk: true,
      error: true
    })
    return
  }

  if (opts.help) {
    self.postMessage({
      event: 'EVAL_OUTPUT_CHUNK',
      chunk: encode(help()),
      opts,
      firstChunk: true,
      error: false
    })
    return
  }

  evalHttpReq = http.request(
    {
      method: 'POST',
      path: '/eval',
      mode: 'prefer-streaming',
      headers: {
        'Content-Type': 'text/plain',
        'Content-Length': Buffer.byteLength(input)
      }
    },
    (res) => {
      const onStreamData = (chunk) => {
        debug('stream data')
        self.postMessage({
          event: 'EVAL_OUTPUT_CHUNK',
          chunk,
          opts,
          firstChunk: !gotFirstChunk,
          error: res.statusCode !== 200
        })
        stream.pause()
        gotFirstChunk = true
      }

      const onStreamEnd = () => {
        debug('stream end')
      }

      cleanup = () => {
        stream.removeListener('data', onStreamData)
        stream.removeListener('end', onStreamEnd)
      }

      stream = res
      stream.on('data', onStreamData)
      stream.on('end', onStreamEnd)
    }
  )

  evalHttpReq.write(input)
  evalHttpReq.end()
}

const onPause = () => {
  if (stream) stream.pause()
}

const onResume = () => {
  if (stream) stream.resume()
}

self.onmessage = ({ data }) => {
  debug('message', data)
  const { event } = data
  if (event === 'EVAL_INPUT') onEvalInput(data)
  if (event === 'PAUSE') onPause()
  if (event === 'RESUME') onResume()
}
