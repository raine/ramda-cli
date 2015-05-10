# ramda-cli

An experimental command-line tool for processing JSON with
[Ramda](http://ramdajs.com).

Takes advantage of [LiveScript](http://livescript.net) to provide a nice and
terse interface for writing pipelines.

```sh
npm install -g ramda-cli
```

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
