import React from 'react'
import * as R from 'ramda'
import debounce from 'lodash.debounce'
import { parse, help } from '../lib/argv'
import { lines, unlines } from '../lib/utils'
import stringArgv from 'string-argv'
import Output from './Output'
import Editor from './Editor'
import initDebug from 'debug'

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
    this.worker = new Worker('./worker.js')
    this.worker.addEventListener('message', this.onWorkerMessage.bind(this))
    this.worker.addEventListener('error', console.error)
    this.onInputChange = this.onInputChange.bind(this)
    this.evalInput = debounce(this.evalInput.bind(this), 400)
    this.onEvalInputError = this.onEvalInputError.bind(this)
    this.setDocumentTitle = this.setDocumentTitle.bind(this)
    this.state = {
      input: props.input,
      output: [],
      opts: {},
      error: null
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
        error: null
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
    this.worker.terminate()
    window.removeEventListener('blur', this.setDocumentTitle)
  }

  onInputChange(input) {
    this.setState({ input }, this.evalInput)
  }

  onEvalInputError(err) {
    this.setState({
      output: [],
      error: err
    })
  }

  setDocumentTitle() {
    const { input } = this.state
    document.title = `ramda ${input !== '' ? input : 'identity'}`
  }

  evalInput() {
    let { input } = this.state
    let opts
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
        error: null
      })
      return
    }

    this.worker.postMessage({
      event: 'EVAL_INPUT',
      opts
    })

    window.fetch('/update-input', {
      method: 'POST',
      body: input
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
            error={error}
          />
        )}
      </div>
    )
  }
}

export default App
