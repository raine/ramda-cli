import React from 'react'
import { render } from 'react-dom'
import querystring from 'querystring'
import App from './App'

import './styles/reboot.css'
import './styles/main.css'

const getStdin = () =>
  window
    .fetch('/stdin')
    .then((res) => res.text())

const doRender = (props) =>
  render(<App {...props} />, document.getElementById('root'))

const { input } = querystring.parse(window.location.href.split('?')[1])

doRender({ stdin: null, input })

getStdin().then((str) => {
  doRender({ stdin: str })
})

const aliveCheck = () => {
  window.ALIVE_CHECK = window
    .fetch('/alive-check')
    .catch((err) => {
      console.error(err)
      setTimeout(aliveCheck, 100)
    })
}

if (!window.ALIVE_CHECK) aliveCheck()
