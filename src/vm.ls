export run-in-new-context = (code, ctx) ->
    new Function(
        'return function (code, ctx) { with(ctx) { return eval(code) } }'
    )().call(ctx, code, ctx)
