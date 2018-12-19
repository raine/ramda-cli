import React from 'react'
import { Controlled as CodeMirror } from 'react-codemirror2'

import 'codemirror/lib/codemirror.css'
import 'codemirror/theme/material.css'
// import 'codemirror/theme/midnight.css'
// import 'codemirror/theme/monokai.css'
// import 'codemirror/theme/pastel-on-dark.css'
// import 'codemirror/theme/seti.css'
// import 'codemirror/theme/shadowfox.css'
// import 'codemirror/theme/tomorrow-night-eighties.css'
import 'codemirror/mode/shell/shell'
import 'codemirror/addon/display/placeholder'
import style from './styles/Editor.scss'

const Editor = ({ value, onChange, placeholder }) => (
  <div className={style.editor}>
    <div className={style.prefix}>stdin | ramda</div>
    <CodeMirror
      className={style.codemirror}
      value={value}
      options={{
        mode: 'shell',
        theme: 'material',
        viewportMargin: Infinity,
        autofocus: true,
        placeholder
      }}

      onBeforeChange={(editor, data, value) => {
        onChange(value)
      }}
    />
  </div>
)

export default Editor
