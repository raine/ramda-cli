import React from 'react'
import * as R from 'ramda'
import debounce from 'lodash.debounce'
import throttle from 'lodash.throttle'
import Output from './Output'
import Editor from './Editor'
import initDebug from 'debug'
import concat from './concat'

import style from './styles/App.scss'

const debug = initDebug('ramda-cli:web:App')
const decoder = new TextDecoder('utf-8')
const decode = decoder.decode.bind(decoder)

class App extends React.Component {
  constructor(props) {
    super(props)
    this.worker = new Worker('./worker.js')
    this.worker.addEventListener('message', this.onWorkerMessage.bind(this))
    this.worker.addEventListener('error', console.error)
    this.outputRef = React.createRef()
    this.onInputChange = this.onInputChange.bind(this)
    this.evalInput = debounce(this.evalInput.bind(this), 400)
    this.setDocumentTitle = this.setDocumentTitle.bind(this)
    this.resumeOrPauseStream = this.resumeOrPauseStream.bind(this)
    this.throttledResumeOrPauseStream = throttle(
      this.resumeOrPauseStream,
      500,
      { trailing: false }
    )
    this.output = Uint8Array.of()
    this.state = {
      input: props.input,
      lines: [],
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
      this.output = firstChunk
        ? chunk
        : concat(Uint8Array, [this.output, chunk])

      this.setState((state, props) => ({
        lines: decode(this.output).split('\n'),
        opts,
        error
      }))
    }
  }

  componentDidUpdate() {
    this.resumeOrPauseStream()
  }

  componentWillUnmount() {
    window.removeEventListener('blur', this.setDocumentTitle)
    this.worker.terminate()
  }

  onInputChange(input) {
    this.setState({ input }, this.evalInput)
  }

  setDocumentTitle() {
    const { input } = this.state
    document.title = `ramda ${input !== '' ? input : 'identity'}`
  }

  evalInput() {
    let { input } = this.state
    if (input == null) input = 'identity'
    input = input.trim()

    this.worker.postMessage({
      event: 'EVAL_INPUT',
      input
    })
  }

  resumeOrPauseStream() {
    this.worker.postMessage({
      event: this.shouldLoadMore() ? 'RESUME' : 'PAUSE'
    })
  }

  shouldLoadMore() {
    if (this.outputRef.current) {
      const {
        maxLinesForHeight,
        visibleStopIndex,
        visibleLines
      } = this.outputRef.current

      const lines = this.state.lines.length
      return (
        lines < maxLinesForHeight * 4 ||
        lines - visibleStopIndex < visibleLines * 4
      )
    } else {
      return false
    }
  }

  render() {
    const { lines, opts, error } = this.state

    return (
      <div className={style.app}>
        <Editor
          value={this.state.input}
          onChange={(value) => {
            this.onInputChange(value)
          }}
          placeholder="identity"
        />
        <Output
          ref={this.outputRef}
          lines={lines}
          outputType={opts.outputType}
          isError={error}
          onItemsRendered={this.throttledResumeOrPauseStream}
        />
      </div>
    )
  }
}

export default App
