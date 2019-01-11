import React, { Component } from 'react'
import HelpBall from './HelpBall'
import LoadingIndicator from './LoadingIndicator'

import style from './styles/Options.scss'

class Options extends Component {
  constructor(props) {
    super(props)
  }

  onOptionChange(option, value) {
    this.props.onChange({
      [option]: value
    })
  }

  render() {
    return (
      <div className={style.options}>
        <div className={style.checkbox}>
          <input
            checked={this.props.options.autorun}
            type="checkbox"
            id="autorun"
            onChange={(ev) => {
              this.onOptionChange('autorun', ev.target.checked)
            }}
          />
          <label htmlFor="autorun">autorun</label>
          <HelpBall text="Use ⌘/Ctrl+Enter to run without autorun" />
        </div>
        <LoadingIndicator
          show={this.props.loading}
          text={this.props.loadingText}
        />
      </div>
    )
  }
}

export default Options
