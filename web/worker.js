import compileFun from '../lib/compile-fun'
import { Readable } from 'readable-stream'
import http from 'stream-http'
import { processInputStream, concatStream } from '../lib/stream'
import isSafari from './is-safari'
import stringToStream from 'string-to-stream'
import concat from './concat'

let stdin = Uint8Array.of()
let curOpts = null

const window = { localStorage: { debug: '*' } }
const debug = require('debug')('ramda-cli:web:worker')
debug.enabled = true
debug('worker initialized')

const stdinHttpReq = http.get('/stdin', (res) => {
  res.on('data', (chunk) => {
    debug('got stdin chunk')
    stdin = concat(Uint8Array, [stdin, chunk])
    onEvalInput({ opts: curOpts })
  })
})

const serializeError = (err) =>
  err.stack ? (isSafari ? `${err.toString()}\n${err.stack}` : err.stack)
            : err

const onEvalInputError = (err) => {
  console.log(err)
  self.postMessage({
    event: 'EVAL_ERROR',
    err: serializeError(err)
  })
}

const onEvalInput = ({ opts }) => {
  if (opts === null) return
  curOpts = opts
  let fun
  try {
    fun = compileFun(opts)
  } catch (err) {
    onEvalInputError(err)
    return
  }

  const inputStream = new Readable()
  inputStream.push(stdin)
  inputStream.push(null)
  const stream = processInputStream(onEvalInputError, opts, fun, inputStream)
  stream
    .pipe(concatStream())
    .on('data', (chunk) => {
      self.postMessage({
        event: 'EVAL_OUTPUT',
        output: chunk,
        opts
      })
  })
}

self.onmessage = ({ data }) => {
  debug('message', data)
  const { event } = data
  if (event === 'EVAL_INPUT') onEvalInput(data)
}
