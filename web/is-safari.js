const isSafari =
  typeof navigator !== 'undefined' &&
  /Version\/[\d\.]+.*Safari/.test(navigator.userAgent)

export default isSafari
