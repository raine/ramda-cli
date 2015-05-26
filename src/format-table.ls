require! ramda: {keys, props, map, to-pairs, apply, create-map-entry, type, merge}
require! 'cli-table': Table

obj-to-objs = to-pairs >> map apply create-map-entry
STYLE = head: <[ cyan bold ]>

format-list = (list, opts) ->
    switch type list.0
    | \Object => format-list-of-objs list, opts
    | otherwise
        table = new Table opts
        list.for-each ->
            switch type it
            | \Array    =>  it
            | otherwise => [it]
            |> table.push
        table.to-string!

format-list-of-objs = (objs, opts) ->
    head  = keys objs.0
    table = new Table merge opts, head: head
    rows  = map (props head), objs
    rows.for-each -> table.push it
    table.to-string!

format-obj = (obj, opts) ->
    table = new Table opts
    obj-to-objs obj
      .for-each -> table.push it
    table.to-string!

format-primitive-etc = (x, opts) ->
    table = new Table opts
    table.push [x]
    table.to-string!

module.exports = (x, style={}) ->
    opts = style: merge STYLE, style
    switch type x
    | \Array    => format-list
    | \Object   => format-obj
    | otherwise => format-primitive-etc
    |> (<| x, opts)
