# Format argv to a sensible multi-line string for browser's input field
argv-to-string = (argv) ->
    argv.map (arg) -> if /\s|"/.test(arg) then "'#arg'" else arg
        .reduce (acc, cur, idx, arr) ->
            is-last = idx === arr.length - 1
            if cur.match /^'/
                # cur is a function argument wrapped with single quotes like
                # 'take 100' and we want it on its own line
                after = if is-last then "" else "\n"
                acc.concat "#{cur}#{after}"
            else
                # cur is probably a flag like -o or table and we want to join
                # them in a single line, if they are one after another
                next = arr[idx+1]
                after =
                    if next and next.match /^'/ then "\n"
                    else if is-last then ""
                    else " "
                acc.concat "#{cur}#{after}"
        , []
        .join ''

module.exports = argv-to-string
