import React from 'react'
import * as R from 'ramda'
import debounce from 'lodash.debounce'
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

class App extends React.Component {
  constructor(props) {
    super(props)
    this.onInputChange = this.onInputChange.bind(this)
    this.evalInput = debounce(this.evalInput.bind(this), 400)
    this.onEvalInputError = this.onEvalInputError.bind(this)
    this.setDocumentTitle = this.setDocumentTitle.bind(this)
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
    if (event === 'EVAL_OUTPUT') {
      const { opts, output } = data
      this.setState({
        output,
        opts,
        error: false
      })
    }
    if (event === 'EVAL_ERROR') {
      const { err } = data
      this.setState({
        output: [],
        error: err
      })
    }
  }

  componentWillUnmount() {
    window.removeEventListener('blur', this.setDocumentTitle)
    this.evalHttpReq.abort()
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

    let gotFirstChunk = false
    if (this.evalHttpReq) this.evalHttpReq.abort()
    const req = (this.evalHttpReq = http.request(
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
        res.on('data', (chunk) => {
          // debug('got chunk')
          // Resetting the output only after receiving the first chunk of the
          // next evaluation result avoids subtle but annoying flicker of the
          // output text.
          this.setState((state, props) => ({
            output: !gotFirstChunk ? [chunk] : state.output.concat(chunk),
            opts,
            error: res.statusCode !== 200
          }))
          gotFirstChunk = true
        })
      }
    ))

    req.write(input)
    req.end()
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
          />
        )}
      </div>
    )
  }
}

export default App
