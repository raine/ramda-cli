strip-ws = (.replace /\s/g, '')
require! ramda: {use-with, identity}

global.assert = require \chai .assert
global.deep-eq = (a, b) --> a `assert.deepEqual` b
global.eq = assert.strict-equal
global.strip-eq = use-with assert.strict-equal, strip-ws, strip-ws
global.ok = assert.ok
