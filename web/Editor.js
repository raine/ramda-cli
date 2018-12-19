import React from 'react'
import { Controlled as CodeMirror } from 'react-codemirror2'

import 'codemirror/lib/codemirror.css'
import 'codemirror/theme/material.css'
import 'codemirror/mode/shell/shell'
import style from './styles/Editor.scss'

const Editor = ({ value, onChange }) => (
  <div>
    <CodeMirror
      value={value}
      options={{
        mode: 'shell',
        theme: 'material',
        viewportMargin: Infinity,
        autofocus: true
      }}
      onBeforeChange={(editor, data, value) => {
        onChange(value)
      }}
    />
  </div>
)

export default Editor
