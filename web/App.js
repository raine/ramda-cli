import React from 'react'
import debounce from 'lodash.debounce'
import compileFun from '../lib/compile-fun'
import { parse } from '../lib/argv'
import stringArgv from 'string-argv'
import stringToStream from 'string-to-stream'
import { processInputStream, concatStream } from '../lib/stream'
import Output from './Output'
import Editor from './Editor'

import style from './styles/App.scss'

const die = (msg) => console.error(msg)

class App extends React.Component {
  constructor(props) {
    super(props)
    this.onInputChange = this.onInputChange.bind(this)
    this.evalInput = debounce(this.evalInput.bind(this), 400)
    this.state = {
      input: props.input,
      output: [],
      opts: {}
    }
    this.evalInput()
  }

  onInputChange(input) {
    this.setState({ input }, this.evalInput)
  }

  evalInput() {
    const { stdin } = this.props
    const { input } = this.state
    const trimmedInput = input.trim()
    if (trimmedInput === '') return
    const argv = stringArgv(input, 'node', 'dummy.js')
    const opts = parse(argv)
    const fun = compileFun(opts, die)
    const inputStream = stringToStream(stdin)
    const stream = processInputStream(die, opts, fun, inputStream)
    stream.pipe(concatStream()).on('data', (chunk) => {
      this.setState({
        output: chunk,
        opts
      })
    })

    window.fetch('/update-input', {
      method: 'POST',
      body: trimmedInput
    })
  }

  render() {
    const { output, opts } = this.state
    return (
      <div className={style.app}>
        <Editor
          value={this.state.input}
          onChange={(value) => {
            this.onInputChange(value)
          }}
        />
        {output && (
          <Output output={output.join('')} outputType={opts.outputType} />
        )}
      </div>
    )
  }
}

export default App
