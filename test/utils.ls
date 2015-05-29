require! sinon
require! stream
require! 'concat-stream'
require! ramda: {apply}

export MAIN = '../src/main'

export run = (main, args, input, cb) ->
    stdin  = new stream.PassThrough!
    stdout = new stream.PassThrough {+object-mode}
        ..pipe concat-stream encoding: \string, -> cb it, null
    stderr = new stream.PassThrough!
        .on \data, (data) -> cb null, data.to-string!

    main ([,,] ++ args), stdin, stdout, stderr
    stdin.write input if input
    stdin.end!

export run-main = (...args) ->
    apply run, [require MAIN] ++ args

export stub-process-exit = ->
    sandbox = null

    before-each ->
        sandbox := sinon.sandbox.create!
        sandbox.stub process, \exit

    after-each ->
        sandbox.restore!
