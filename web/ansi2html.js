const Convert = require('ansi-to-html')

export default function ansi2html(str, options) {
  const convert = new Convert(options)
  return { __html: convert.toHtml(str) }
}
