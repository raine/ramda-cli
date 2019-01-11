require! 'runtime-npm-install': {npm-install-async, get-pkgs-to-be-installed}
require! <[ ./config ]>
require! 'term-color': {gray}
require! camelize
debug = require 'debug' <| 'ramda-cli:npm-install'

get-alias-for-installed = (opts-import, installed) ->
  imported = opts-import.find -> it.package-spec is installed.spec
  imported.alias or camelize installed.name

get-uninstalled = (packages) ->>
    get-pkgs-to-be-installed packages, config.BASE_PATH

npm-install = (packages, opts-import, stderr) ->>
    npm-install-result = await npm-install-async do
        packages,
        config.BASE_PATH

    if npm-install-result.npm-output
        stderr.write gray(npm-install-result.npm-output) + '\n'

    imports = npm-install-result.packages.map ->
        name: it.name
        version: it.json.version
        alias: get-alias-for-installed opts-import, it
        exports: require it.path

    imports.for-each ->
        debug "#{it.name}@#{it.version} installed as #{it.alias}"

    imports

module.exports = { npm-install, get-uninstalled }
