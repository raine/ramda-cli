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
        <div className={style.loadingIndicator}/>
      </CSSTransition>
    )
  }
}

export default LoadingIndicator
