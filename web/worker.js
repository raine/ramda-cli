import compileFun from '../lib/compile-fun'
import { Readable } from 'readable-stream'
import http from 'stream-http'
import { processInputStream, concatStream } from '../lib/stream'
import stringToStream from 'string-to-stream'
import concat from './concat'

let stdin = Uint8Array.of()

const window = { localStorage: { debug: '*' } }
const debug = require('debug')('ramda-cli:web:worker')
debug.enabled = true
debug('worker initialized')

const stdinHttpReq = http.get('/stdin', (res) => {
  res.on('data', (chunk) => {
    debug('got stdin chunk')
    stdin = concat(Uint8Array, [ stdin, chunk ])
  })
})

const onEvalInputError = (err) => {
  self.postMessage({
    event: 'EVAL_ERROR',
    err: err.stack || err.message || err
  })
}

const onEvalInput = ({ opts }) => {
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
  const stream = processInputStream(
    onEvalInputError,
    opts,
    fun,
    inputStream
  )
  stream.pipe(concatStream()).on('data', (chunk) => {
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
