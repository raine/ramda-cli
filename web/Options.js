import React, { Component } from 'react'

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
        </div>
      </div>
    )
  }
}

export default Options
