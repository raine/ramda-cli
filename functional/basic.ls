require! path
require! shelljs: {rm, exec, mkdir}: shelljs
shelljs.config.silent = true

HOME = process.env.HOME

describe 'with stdin and function' (,) ->
    it 'applies (add 5) to 5 from stdin' (done) ->
        code, output <- exec 'echo 5 | ./bin/ramda "add 5"'
        output `eq` '10\n'
        done!

describe '--configure' (,) ->
    before -> mkdir '-p', "#HOME/.config/"

    it 'shows an error if config file does not exist' (done) ->
        rm "#HOME/.config/ramda-cli.ls"
        code, output <- exec './bin/ramda -C'
        output `eq` """
        Error: No config file, create one at #HOME/.config/ramda-cli.{js,ls}\n
        """
        done!

    it 'starts editor if config file exists' (done) ->
        <- exec 'cat test/data/config-with-require.ls > $HOME/.config/ramda-cli.ls'
        code, output <- exec 'VISUAL=echo ./bin/ramda -C'
        output `eq` "#HOME/.config/ramda-cli.ls\n"
        done!

describe 'global config' (,) ->
    it 'uses a function from from config file' (done) ->
        <- exec 'npm install ramda --prefix $HOME'
        <- exec 'cat test/data/config-with-require.ls > $HOME/.config/ramda-cli.ls'
        code, output <- exec 'echo foo | ./bin/ramda -rR shout'
        output `eq` 'FOO!\n'
        done!
