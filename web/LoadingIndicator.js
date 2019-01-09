import React, { Component } from 'react'
import style from './styles/LoadingIndicator'
import { CSSTransition } from 'react-transition-group'

class LoadingIndicator extends Component {
  constructor(props) {
    super(props)
  }

  render() {
    return (
      <CSSTransition
        in={this.props.show}
        timeout={{
          enter: 250,
          exit: 500
        }}
        enter
        appear
        classNames={{
          enter: style.enter,
          enterDone: style.enterDone,
          exit: style.exit,
          exitDone: style.exitDone
        }}
      >
        <svg className={style.loadingIndicator}>
          <circle cx="0.5em" cy="0.5em" r="0.5em" />
        </svg>
      </CSSTransition>
    )
  }
}

export default LoadingIndicator
