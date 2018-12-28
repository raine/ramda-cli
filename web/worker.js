import compileFun from '../lib/compile-fun'
import { Readable } from 'readable-stream'
import http from 'stream-http'
import { processInputStream, concatStream } from '../lib/stream'
import isSafari from './is-safari'
import stringToStream from 'string-to-stream'
import concat from './concat'

const debug = require('debug')('ramda-cli:web:worker')
debug.enabled = true
debug('worker initialized')

let evalHttpReq
let gotFirstChunk = false
let stream

const onEvalInput = ({ input, opts }) => {
  if (evalHttpReq) evalHttpReq.abort()
  gotFirstChunk = false
  const evalHttpReq = http.request(
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
      stream = res
      stream.on('readable', () => {
        debug('stream readable')
        if (!gotFirstChunk) {
          chunk = stream.read(65536)
        }
      })

      stream.on('data', (chunk) => {
        debug('stream data', chunk)
        self.postMessage({
          event: 'EVAL_OUTPUT_CHUNK',
          chunk,
          opts,
          firstChunk: !gotFirstChunk,
          error: res.statusCode !== 200
        })
        gotFirstChunk = true
      })

      stream.on('end', () => {
        debug('stream end')
      })
    }
  )

  evalHttpReq.write(input)
  evalHttpReq.end()
}

const onReadMore = () => {
  if (stream) stream.read(65536)
}

self.onmessage = ({ data }) => {
  debug('message', data)
  const { event } = data
  if (event === 'EVAL_INPUT') onEvalInput(data)
  if (event === 'READ_MORE') onReadMore()
}
