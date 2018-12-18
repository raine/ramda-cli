import React from 'react'
import debounce from 'lodash.debounce'
import compileFun from '../lib/compile-fun'
import { parse } from '../lib/argv'
import stringArgv from 'string-argv'
import { processInputStream, concatStream } from '../lib/stream'
import Output from './Output'

import style from './styles/App.scss'

const die = (msg) => console.error(msg)

class App extends React.Component {
  constructor(props) {
    super(props)
    this.onInputChange = this.onInputChange.bind(this)
    this.evalInput = debounce(this.evalInput.bind(this), 400)
    this.state = { input: props.input, output: [] }
    this.evalInput()
  }

  onInputChange(ev) {
    const val = ev.target.value
    this.setState({ input: val }, this.evalInput)
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
    stream
      .pipe(concatStream())
      .on('data', (chunk) => {
        this.setState({ output: chunk })
      })

    window.fetch('/update-input', {
      method: 'POST',
      body: trimmedInput
    })
  }

  render() {
    return (
      <div className={style.app}>
        <div className={style.inputWrapper}>
          <input
            type="text"
            value={this.state.input}
            onChange={(ev) => {
              ev.persist()
              this.onInputChange(ev)
            }}
          />
        </div>
        <Output output={this.state.output} />
      </div>
    )
  }
}
