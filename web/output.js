import React from 'react'
import { render } from 'react-dom'
import stripAnsi from 'strip-ansi'

const Output = ({ output }) => (
  <div>
    <pre>{stripAnsi(output.join(''))}</pre>
  </div>
)

export default Output
