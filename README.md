# ramda-cli [![npm version](https://badge.fury.io/js/ramda-cli.svg)](https://www.npmjs.com/package/ramda-cli)

A command-line tool for processing JSON with functional pipelines.

Takes advantage of [Ramda's](http://ramdajs.com) curried, data-last API and
[LiveScript's](http://livescript.net) nice and terse syntax.

```sh
npm install -g ramda-cli
```

## usage

```sh
$ cat data.json | ramda [function]
```

The idea is to [compose][1] functions into a pipeline of operations that when
applied to given data, produces the desired output.

Technically, `[function]` should be a snippet of LiveScript that evaluates
into a function.

The function is applied to a stream of JSON data read from stdin, and the
output data is sent to standard out as stringified JSON.

All Ramda's functions are available directly in the scope. See
http://ramdajs.com/docs/ for a full list.

## options

```
Usage: ramda [options] [function]

  -c, --compact     compact output
  -i, --inspect     pretty-printed output with colors
  -s, --slurp       read JSON objects from stdin as one big list
  -S, --unslurp     unwraps a list before output so that each item is
                    stringified separately
  -r, --raw-output  raw output
  -h, --help        displays help
```

## examples

[`R.add`](http://ramdajs.com/docs/#add) partially applied with `2` is applied
to `1` from stdin:

```sh
$ echo 1 | ramda 'add 2' # 3
```

```sh
$ echo [1,2,3] | ramda 'sum' # 6
```

Reformat and check validity of JSON with [`R.identity`](http://ramdajs.com/docs/#identity):

```sh
$ cat data.json | ramda identity
```

```sh
$ curl -s http://raine.github.io/ramda-json-docs/latest.json | \
  ramda '(pluck \name) . filter where-eq {category: \Logic}'
[
    "and",
    "both",
    "complement",
    "cond",
    ...
]
```

Parentheses can be used like in JavaScript, if necessary:

```sh
$ echo [1,2,3,4,5] | ramda 'pipe(map(multiply(2)), filter(gt(__, 4)))'
```

You can also use use unix pipes:

```sh
$ alias R=ramda
$ echo [[1,2,3],[4,5,6]] | R unnest | R sum # 21
$ cat latest.json | R 'pluck \name' | R 'take 7' | R 'map to-upper >> (+ \!)' | R 'join " "'
"__! ADD! ADJUST! ALWAYS! APERTURE! APPLY! ARITY!"
```

Read *Line Delimited JSON* and filter by properties by returning `undefined`
for some objects:

```sh
$ cat bunyan-logfile | ramda 'if-else((where-eq level: 40), identity, always void)'
```

Use `--slurp` to read multiple JSON objects into a single list before any
operations:

```sh
$ cat text
"foo bar"
"test lol"
"hello world"
$ cat text | ramda -c --slurp identity
["foo bar","test lol","hello world"]

$ echo "1\n2\n3\n" | ramda -c --slurp 'map multiply 2'
[2,4,6]
```

Use `--unslurp` to output a list's items separately:

```sh
$ echo '["hello", "world"]' | ramda --unslurp identity
"hello"
"world"
```

Use `--raw-output` to print strings without JSON formatting:

```sh
$ echo '"foo"\n"bar"' | ramda to-upper --raw-output
FOO
BAR
```

## debugging

You can turn on the debug logging with `export DEBUG=ramda-cli:*`.

```sh
ramda-cli 'R.sum' +0ms input code
ramda-cli 'R.sum;' +14ms compiled code
ramda-cli [Function: f1] +4ms evaluated to
```

[`treis`](https://github.com/raine/treis) is available for debugging
individual functions in the pipeline:

<img width="370" height="99" src="https://raw.githubusercontent.com/raine/ramda-cli/media/treis-face.png" />

## why LiveScript?

> [LiveScript](http://livescript.net) is a fork of Coco and an indirect
descendant of CoffeeScript, with which it has much compatibility.

- Function composition operators `.`, `<<`, `>>`
- Pipes for nested function calls `|>`
- Partial application with `_`
- It's awesome.

--

[![wercker status](https://app.wercker.com/status/92dbf35ece249fade3e8198181d93ec1/s "wercker status")](https://app.wercker.com/project/bykey/92dbf35ece249fade3e8198181d93ec1)


[1]: http://en.wikipedia.org/wiki/Function_composition_%28computer_science%29
