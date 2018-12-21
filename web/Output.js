import React, { PureComponent } from 'react'
import stripAnsi from 'strip-ansi'
import { pure } from 'recompose'
import classNames from 'classnames'
import ansi2html from './ansi2html'
import isSafari from './is-safari'
import { FixedSizeList } from 'react-window'
import AutoSizer from 'react-virtualized-auto-sizer'

import style from './styles/Output.scss'

const errorOutput = (err) => (isSafari ? err.toString() : err.stack)

const hasAnsiColors = (outputType) => ['pretty', 'table'].includes(outputType)

const AnsiPre = pure(({ str, style }) => (
  <pre
    style={style}
    dangerouslySetInnerHTML={ansi2html(str, {
      escapeXML: true,
      fg: '#afafaf',
      bg: '#0a0a0a'
    })}
  />
))

class OutputRow extends PureComponent {
  render() {
    const { data, index, style: rwStyle, outputType } = this.props
    const content = data[index]
    return hasAnsiColors(outputType) ? (
      <AnsiPre style={rwStyle} str={content} />
    ) : (
      <pre style={rwStyle}>{content}</pre>
    )
  }
}

class Output extends PureComponent {
  constructor(props) {
    super(props)
  }

  render() {
    const { outputType, output, error } = this.props
    const lines = (error ? errorOutput(error) : output).split('\n')

    return (
      <div className={classNames(style.output, { [style.error]: error })}>
        <AutoSizer disableWidth={true}>
          {({ height }) => (
            <FixedSizeList
              className={style.outputList}
              height={height}
              itemData={lines}
              itemCount={lines.length}
              itemSize={24}
            >
              {(props) => <OutputRow {...props} outputType={outputType} />}
            </FixedSizeList>
          )}
        </AutoSizer>
      </div>
    )
  }
}

export default Output
