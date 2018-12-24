import React from 'react'
import { render } from 'react-dom'
import querystring from 'querystring'
import App from './App'
import http from 'stream-http'

import './styles/reboot.css'
import './styles/main.css'

let stdin = ''
const getStdin = () =>
  http.get('stdin', (res) => {
    res.on('data', (buf) => {
      stdin += buf.toString()
      doRender({ stdin })
    })
  })

const doRender = (props) =>
  render(<App {...props} />, document.getElementById('root'))

const { input } = querystring.parse(window.location.href.split('?')[1])

doRender({ stdin: null, input })
getStdin()

const aliveCheck = () => {
  window.ALIVE_CHECK = window.fetch('/alive-check').catch((err) => {
    console.error(err)
    setTimeout(aliveCheck, 100)
  })
}

if (!window.ALIVE_CHECK) aliveCheck()
