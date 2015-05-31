require! '../helpers': {run, MAIN, stub-process-exit}
main = require \rewire <| '../../src/main'
{called-with} = sinon.assert

describe '--configure' (,) ->
    stub-process-exit!

    it 'shows an error if config.edit fails' (done) ->
        main.__set__ \config, edit: (cb) ->
            cb new Error 'edit-config failed'

        output, errput <- run main, <[ -C ]>, ''
        errput `eq` 'Error: edit-config failed\n'
        <-! set-immediate
        called-with process.exit, 1
        done!

    it 'shows no output if config.edit succeeds' (done) ->
        main.__set__ \config, edit: (cb) -> cb 0
        run main, <[ -C ]>, '', ->
        called-with process.exit, 0
        done!
