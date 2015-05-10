# ramda-cli

An experimental command-line tool for processing JSON with
[Ramda](http://ramdajs.com).

Takes advantage of [LiveScript](http://livescript.net) to provide a nice and
terse interface for writing pipelines.

```sh
npm install -g ramda-cli
```


## usage

```sh
cat data.json | ramda [code]
```

`code` should be a snippet of LiveScript that evaluates into a function.

All Ramda's functions are available. See http://ramdajs.com/docs/ for the
full list.

## examples

```sh
echo 1 | ramda 'add 1' # 2
```

```sh
echo [1,2,3] | ramda 'sum' # 6
```

```sh
curl -s http://raine.github.io/ramda-json-docs/latest.json | \
  ramda '(pluck \name) . filter where {category: \Logic}'
[
    "and",
    "both",
    "complement",
    "cond",
    ...
]
```

## debugging

You can turn on the debug logging with `export DEBUG=*`.

```
ramda-cli 'R.sum' +0ms input code
ramda-cli 'R.sum;' +14ms compiled code
ramda-cli [Function: f1] +4ms evaluated
```
