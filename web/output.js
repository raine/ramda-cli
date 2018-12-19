import React from 'react'
import { render } from 'react-dom'
import stripAnsi from 'strip-ansi'
import { pure } from 'recompose'
import ansi2html from './ansi2html'

import style from './styles/Output.scss'

const Output = ({ output, outputType }) => (
  <div className={style.output}>
    {['pretty', 'table'].includes(outputType) ? (
      <pre
        dangerouslySetInnerHTML={ansi2html(output, {
          escapeXML: true,
          fg: '#afafaf',
          bg: '#0a0a0a'
        })}
      />
    ) : (
      <pre>{output}</pre>
    )}
  </div>
)

export default pure(Output)
