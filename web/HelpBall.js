import React, { Component } from 'react'
import style from './styles/HelpBall'
import Tooltip from 'reactstrap/es/Tooltip'

import './styles/tooltip'

class HelpBall extends Component {
  constructor(props) {
    super(props)
    this.state = { showTooltip: false }
    this.toggle = this.toggle.bind(this)
  }

  toggle() {
    this.setState((state, props) => ({
      showTooltip: !state.showTooltip
    }))
  }

  render() {
    return (
      <React.Fragment>
        <div className={style.helpBall} id="help-ball" />
        <Tooltip
          placement="auto"
          isOpen={this.state.showTooltip}
          target="help-ball"
          toggle={this.toggle}
          delay={{ show: 100, hide: 0 }}
        >
          {this.props.text}
        </Tooltip>
      </React.Fragment>
    )
  }
}

export default HelpBall
