import React from 'react'
import * as R from 'ramda'
import debounce from 'lodash.debounce'
import throttle from 'lodash.throttle'
import { lines, unlines } from '../lib/utils'
import stringArgv from 'string-argv'
import Output from './Output'
import Editor from './Editor'
import initDebug from 'debug'
import http from 'stream-http'
import { parse, help } from '../lib/argv'

import style from './styles/App.scss'

const debug = initDebug('ramda-cli:web:App')
const removeCommentedLines = R.pipe(
  lines,
  R.reject((x) => /^#/.test(x)),
  unlines
)

const decoder = new TextDecoder('utf-8')
const decode = decoder.decode.bind(decoder)

class App extends React.Component {
  constructor(props) {
    super(props)
    this.worker = new Worker('./worker.js')
    this.worker.addEventListener('message', this.onWorkerMessage.bind(this))
    this.worker.addEventListener('error', console.error)
    this.onInputChange = this.onInputChange.bind(this)
    this.evalInput = debounce(this.evalInput.bind(this), 400)
    this.onEvalInputError = this.onEvalInputError.bind(this)
    this.setDocumentTitle = this.setDocumentTitle.bind(this)
    this.outputNearEnd = throttle(this.outputNearEnd.bind(this), 500, {
      trailing: false
    })

    this.state = {
      input: props.input,
      output: [],
      opts: {},
      error: false
    }
    window.addEventListener('blur', this.setDocumentTitle, false)
    this.evalInput()
  }

  onWorkerMessage({ data }) {
    const { event } = data
    debug('worker message', data)
    if (event === 'EVAL_OUTPUT_CHUNK') {
      const { chunk, error, firstChunk, opts } = data
      // Resetting the output only after receiving the first chunk of the
      // next evaluation result avoids subtle but annoying flicker of the
      // output text.
      this.setState((state, props) => ({
        output: firstChunk
          ? [decode(chunk)]
          : state.output.concat(decode(chunk)),
        opts,
        error
      }))
    }
  }

  componentWillUnmount() {
    window.removeEventListener('blur', this.setDocumentTitle)
    this.worker.terminate()
  }

  onInputChange(input) {
    this.setState({ input }, this.evalInput)
  }

  onEvalInputError(err) {
    this.setState({
      output: [err.message],
      error: true
    })
  }

  setDocumentTitle() {
    const { input } = this.state
    document.title = `ramda ${input !== '' ? input : 'identity'}`
  }

  evalInput() {
    let { input } = this.state
    let opts
    if (input == null) input = 'identity'
    input = input.trim()
    const argv = stringArgv(removeCommentedLines(input), 'node', 'dummy.js')
    try {
      opts = parse(argv)
    } catch (err) {
      this.onEvalInputError(err)
      return
    }

    if (opts.help) {
      this.setState({
        output: [help()],
        opts,
        error: false
      })
      return
    }

    this.worker.postMessage({
      event: 'EVAL_INPUT',
      input,
      opts
    })
  }

  outputNearEnd() {
    this.worker.postMessage({
      event: 'READ_MORE'
    })
  }

  render() {
    const { output, opts, error } = this.state
    return (
      <div className={style.app}>
        <Editor
          value={this.state.input}
          onChange={(value) => {
            this.onInputChange(value)
          }}
          placeholder="identity"
        />
        {output && (
          <Output
            output={output.join('')}
            outputType={opts.outputType}
            isError={error}
            nearEnd={this.outputNearEnd}
          />
        )}
      </div>
    )
  }
}

export default App
