require! ramda: {keys, props, map, to-pairs, apply, create-map-entry, type}
require! 'cli-table': Table

obj-to-objs = to-pairs >> map apply create-map-entry
STYLE = head: <[ cyan bold ]>

format-list = (list) ->
    switch type list.0
    | \Object => format-list-of-objs list
    | otherwise 
        table = new Table
        list.for-each -> 
            switch type it
            | \Array    =>  it
            | otherwise => [it]
            |> table.push
        table.to-string!

format-list-of-objs = (objs) ->
    head  = keys objs.0
    table = new Table head: head, style: STYLE
    rows  = map (props head), objs
    rows.for-each -> table.push it
    table.to-string!

format-obj = (obj) ->
    table = new Table style: STYLE
    obj-to-objs obj
      .for-each -> table.push it
    table.to-string!

format-primitive-etc = ->
    table = new Table
    table.push [it]
    table.to-string!

module.exports = ->
    switch type it
    | \Array    => format-list it
    | \Object   => format-obj it
    | otherwise => format-primitive-etc it
