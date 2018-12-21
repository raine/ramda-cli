import React from 'react'
import stripAnsi from 'strip-ansi'
import { pure } from 'recompose'
import classNames from 'classnames'
import ansi2html from './ansi2html'
import isSafari from './is-safari'

import style from './styles/Output.scss'

const errorOutput = (err) =>
  isSafari ? err.toString() : err.stack

const Output = ({ output, outputType, error }) => (
  <div className={classNames(style.output, { [style.error]: error })}>
    {error && <pre>{errorOutput(error)}</pre>}
    {!error && ['pretty', 'table'].includes(outputType) ? (
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
