import React, { Component } from 'react'
import style from './styles/LoadingIndicator'
import { CSSTransition } from 'react-transition-group'

const ENTER_DURATION = 250
const EXIT_DURATION = 500

class LoadingIndicator extends Component {
  constructor(props) {
    super(props)

    this.state = {
      text: props.text
    }
  }

  // The reason text is in state instead of props is that fade out animation
  // would not work if text is updated to null before animation ends. By using
  // state for text, we can clear text with a delay when the text prop is updated.
  componentDidUpdate(prevProps) {
    if (this.props.text === null && prevProps.text !== null) {
      setTimeout(() => {
        this.setState({ text: null })
      }, EXIT_DURATION + 100)
    } else if (this.props.text !== null && prevProps.text === null) {
      this.setState({ text: this.props.text })
    }
  }

  render() {
    return (
      <CSSTransition
        in={this.props.show}
        timeout={{
          enter: ENTER_DURATION,
          exit: EXIT_DURATION
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
        <div className={style.loadingIndicator}>
          <div className={style.text}>{this.state.text}</div>
          <div className={style.ball} />
        </div>
      </CSSTransition>
    )
  }
}

export default LoadingIndicator
