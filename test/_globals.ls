require! ramda: {use-with, identity, if-else}
rm-ws = (.replace /\s/g, '')
strip-ws = if-else (~= null), identity, rm-ws

global.assert = require \chai .assert
global.deep-eq = (a, b) --> a `assert.deepEqual` b
global.eq = assert.strict-equal
global.strip-eq = use-with assert.strict-equal, strip-ws, strip-ws
global.ok = assert.ok
