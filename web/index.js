import React from 'react'
import { render } from 'react-dom'
import querystring from 'querystring'
import App from './App'
import initDebug from 'debug'

import './styles/reboot.css'
import './styles/main.css'

initDebug.enable('ramda-cli:*')

const doRender = (props) =>
  render(<App {...props} />, document.getElementById('root'))

const { input } = querystring.parse(window.location.href.split('?')[1])

doRender({ stdin: null, input })

window.addEventListener('unload', () => navigator.sendBeacon('/unload'), false)
window.fetch('/ping')
