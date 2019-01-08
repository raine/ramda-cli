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
        timeout={1000}
        enter
        appear
        classNames="hello"
        onEnter={() => {
          console.log('lol')
          
        }}
      >
        <div>
          <svg className={style.loadingIndicator}>
            <circle cx="0.5em" cy="0.5em" r="0.5em" />
          </svg>
        </div>
      </CSSTransition>
    )
  }
}

export default LoadingIndicator
