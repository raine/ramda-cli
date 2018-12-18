import React from 'react'
import { render } from 'react-dom'
import stripAnsi from 'strip-ansi'
import { pure } from 'recompose'

import style from './styles/Output.scss'

const Output = ({ output }) => (
  <div className={style.output}>
    <pre>{stripAnsi(output.join(''))}</pre>
  </div>
)

export default pure(Output)
