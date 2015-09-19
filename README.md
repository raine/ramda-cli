# ramda-cli [![npm version](https://badge.fury.io/js/ramda-cli.svg)](https://www.npmjs.com/package/ramda-cli)

A command-line tool for processing data with functional pipelines.

```sh
nsa> cat people.json | R \
  'filter (p) -> p.city is /Port/ or p.name is /^Dr\./' \
  'project <[ name city mac ]>' \
  -o table --compact
┌──────────────────┬─────────────────┬───────────────────┐
│ name             │ city            │ mac               │
├──────────────────┼─────────────────┼───────────────────┤
│ Dr. Araceli Lang │ Yvettemouth     │ 9e:ea:28:41:2a:50 │
│ Terrell Boyle    │ Port Reaganfort │ c5:32:09:5a:f7:15 │
│ Libby Renner     │ Port Reneeside  │ 9c:63:13:31:c4:ac │
└──────────────────┴─────────────────┴───────────────────┘
```

Brings together [Ramda's][ramda] curried, data-last API and
[LiveScript's][livescript] terse and powerful syntax.

With a variety of supported input/output types and the ability [pull any
module from npm](#using-packages-from-npm), ramda-cli is a potent tool for
many kinds of data manipulation in command-line environment.

- [Examples](#examples)
- [Configuration](#configuration)
- [JavaScript support](#javascript-support)
- [Cookbook][cookbook]
- [Tutorial: Using ramda-cli to process and display data from GitHub API][tutorial]
- [Essential LiveScript for ramda-cli][essential-livescript]

## install

```sh
npm install -g ramda-cli
```

## synopsis

```sh
cat data.json | R [function] ...
```

The idea is to [compose][1] functions into a pipeline of operations that when
applied to given data, produces the desired output.

By default, the function is applied to a stream of JSON data read from stdin,
and the output data is sent to standard out as stringified JSON.

Technically, `function` should be a snippet of LiveScript (or JavaScript with
`--js`) that evaluates into a function.

If multiple `function` arguments are supplied, they are composed into a
pipeline in order from left to right, as with
[`R.pipe`](http://ramdajs.com/docs/#pipe).

All Ramda's functions are available directly in the scope. See
http://ramdajs.com/docs/ for a full list.

## options

```
Usage: R [options] [function] ...

  -f, --file         read a function from a js/ls file instead of args; useful for
                     larger scripts
  -c, --compact      compact output for JSON and tables
  -s, --slurp        read JSON objects from stdin as one big list
  -S, --unslurp      unwraps a list before output so that each item is formatted and
                     printed separately
  -i, --input-type   read input from stdin as (one of: raw, csv, tsv)
  -o, --output-type  format output sent to stdout (one of: pretty, raw, csv, tsv, table)
  -p, --pretty       pretty-printed output with colors, alias to -o pretty
  -r, --raw-input    alias for --input-type raw
  -R, --raw-output   alias for --output-type raw
  -C, --configure    edit config in $EDITOR
  -n, --no-stdin     don't read input from stdin
      --js           use javascript instead of livescript
  -v, --verbose      print debugging information (use -vv for even more)
      --version      print version
  -h, --help         displays help
```

## output types

Aside from JSON, few other types of output are supported:

##### `-o pretty`

Print pretty output.

##### `-o raw`

With raw output type when a string value is produced, the result will be
written to stdout as is without any formatting.

##### `-o csv` and `-o tsv`

CSV or TSV output type can be used when pipeline evaluates to an array of
objects, an array of arrays or when stdin consists of a stream of bare
objects. First object's keys will determine the headers.

##### `-o table`

Print ~any shape of data as a table. If used with a list of objects, uses the
first object's keys as headers. See an example below.

## examples

```sh
# Add 1 to each value in a list
echo [1,2,3] | R 'map add 1'
[
  2,
  3,
  4
]

# Add 1 to each value with inline ES6 lambda and take product of all
echo [1,2,3] | R --js 'map(x => x + 1)' product
24
```

> Ramda functions used:
> [`map`](http://ramdajs.com/docs/#map),
> [`product`](http://ramdajs.com/docs/#product)

##### Get a list of people whose first name starts with "B"

```sh
cat people.json | R 'pluck \name' 'filter (name) -> name.0 is \B)' -o raw
Brando Jacobson
Betsy Bayer
Beverly Gleichner
Beryl Lindgren
```

> Ramda functions used:
> [`pluck`](http://ramdajs.com/docs/#pluck),
> [`filter`](http://ramdajs.com/docs/#filter)  
> Data: [people.json](https://gist.githubusercontent.com/raine/cd11686e0b8a4a43bbf6/raw/people.json)

##### List versions of npm module with dates formatted with [`node-timeago`](https://github.com/ecto/node-timeago)

It looks for `ecto/node-timeago` installed to `$HOME/node_modules`.

```sh
npm view ramda --json | R \
  'prop \time' 'to-pairs' \
  'map -> version: it.0, time: require("timeago")(it.1)' \
  -o tsv | column -t -s $'\t'
...
0.12.0    2 months ago
0.13.0    2 months ago
0.14.0    12 days ago
```

##### Search twitter for people who tweeted about ramda and pretty print [the result](https://raw.githubusercontent.com/raine/ramda-cli/media/twarc-ramda.png)

```sh
twarc.py --search '#ramda' | R --slurp -p 'map path [\user, \screen_name]' uniq
```

> Ramda functions used:
> [`map`](http://ramdajs.com/docs/#map),
> [`path`](http://ramdajs.com/docs/#path)


##### Pull response status data from Graphite and visualize

HTTP status codes per minute for last hour:

```sh
graphite -t "summarize(stats_counts.status_codes.*, '1min', 'sum', false)" -f '-1h' -o json | \
  R 'map evolve datapoints: (map head) >> require \sparkline' \
    'sort-by prop \target' -o table
```

[![graphite-http-codes](https://raw.githubusercontent.com/raine/ramda-cli/media/graphite-http-codes-thumb.png)](https://raw.githubusercontent.com/raine/ramda-cli/media/graphite-http-codes.png)

> Ramda functions used:
> [`evolve`](http://ramdajs.com/docs/#evolve),
> [`sortBy`](http://ramdajs.com/docs/#sortBy)

##### Use `--slurp` to read multiple JSON objects into a single list before any operations

```sh
$ cat <<EOF > text
"foo bar"
"test lol"
"hello world"
EOF
$ cat text | R --compact --slurp identity
["foo bar","test lol","hello world"]
```

##### Solution to the [credit card JSON to CSV challenge](https://gist.github.com/jorin-vogel/2e43ffa981a97bc17259) using `--output-type csv`

```bash
#!/usr/bin/env bash

data_url=https://gist.githubusercontent.com/jorin-vogel/7f19ce95a9a842956358/raw/e319340c2f6691f9cc8d8cc57ed532b5093e3619/data.json
curl $data_url | R \
  'filter where creditcard: (!= null)' `# filter out those who don't have credit card` \
  'project [\name, \creditcard]'       `# pick name and creditcard fields from all objects` \
  -o csv > `date "+%Y%m%d"`.csv        `# print output as csv to a file named as the current date` 
```

##### Print a table with `--output-type table`

```sh
cat countries.json | R 'take 3' -o table
┌───────────────┬──────┐
│ name          │ code │
├───────────────┼──────┤
│ Afghanistan   │ AF   │
├───────────────┼──────┤
│ Åland Islands │ AX   │
├───────────────┼──────┤
│ Albania       │ AL   │
└───────────────┴──────┘
```

> Ramda functions used:
> [`take`](http://ramdajs.com/docs/#take)  
> Data: [countries.json](https://gist.github.com/raine/4756f6fc803a32663b3f)

##### List a project's dependencies in a table

```sh
npm ls --json | R 'prop \dependencies' 'map-obj prop \version' -o table --compact
┌───────────────┬────────┐
│ JSONStream    │ 1.0.4  │
│ treis         │ 2.3.9  │
│ ramda         │ 0.14.0 │
│ livescript    │ 1.4.0  │
│ cli-table     │ 0.3.1  │
└───────────────┴────────┘
```

> Ramda functions used:
> [`filter`](http://ramdajs.com/docs/#filter),
> [`where`](http://ramdajs.com/docs/#where),
> [`project`](http://ramdajs.com/docs/#project),
> [`mapObj`](http://ramdajs.com/docs/#mapObj),
> [`prop`](http://ramdajs.com/docs/#prop)

##### Generate HTML with hyperscript

With [`hyperscript`][hyperscript] installed to `$HOME/node_modules` and
[config](#config-file) that exports it as `h`.

```js
exports.h = require('hyperscript')
```

```sh
$ cat <<EOF > shopping.txt
milk
cheese
peanuts
EOF
$ cat shopping.txt | R \
  -rR --slurp           `# read raw input into a list` \
  'map (h \li.item, _)' `# apply <li class="item"> into each item` \
  'h \ul#list, _'       `# wrap list inside <ul id="list">` \
  '.outer-HTML'         `# finally, grab the HTML`
```

```html
<ul id="list">
  <li class="item">milk</li>
  <li class="item">cheese</li>
  <li class="item">peanuts</li>
</ul>
```

Reason for underscores (e.g. `h \ul, _`) is that hyperscript API is not
curried (and can't be because it's variadic). We need to explicitly state
that this function is waiting for one more argument.

##### Load function from a file with the `--file` option

```sh
$ cat shout.js
var R = require('ramda');
module.exports = R.pipe(R.toUpper, R.add(R.__, '!'));
$ echo -n 'hello world' | R -i raw --file shout.js
"HELLO WORLD!"
```

For more examples, see the [Cookbook][cookbook].

## functions

All of [Ramda's functions][ramda-docs] are available, and also:

| function         | signature           | description                                    |
| ---------------- | ------------------- | ---------------------------------------------- |
| `id`             | `a → a`             | Alias to `R.identity`                          |
| [`treis`][treis] | `treis(name?, fn)`  | Observe functions' input and output values     |
| [`flat`][flat]   | `* → Object`        | Flatten a deep structure into a shallow object |
| `readFile`       | `filePath → String` | Read a file as string                          |
| `lines`          | `String → [String]` | Split a string into lines                      |
| `words`          | `String → [String]` | Split a string into words                      |
| `unlines`        | `[String] → String` | Join a list of lines into a string             |
| `unwords`        | `[String] → String` | Join a list of words into a string             |

## configuration

### config file

Path: `$HOME/.config/ramda-cli.{js,ls}`

The purpose of a global config file is to carry functions you might find
useful to have around. The functions it exports in an object are made
available.

For example,

```sh
$ cat <<EOF > ~/.config/ramda-cli.js
> exports.date = (val) => new Date(val);
> exports.timeago = require('timeago');
> exports.debug = (val) => {
>   console.log('debug:', val);
>   return val;
> };
> EOF
$ echo 1442667243000 | R date debug timeago
debug: Sat Sep 19 2015 12:54:03 GMT+0000 (UTC)
"12 minutes ago"
```

### default options

To make some options be passed by default, it is best to use a shell alias.
For example, to always interpret functions as JavaScript:

```sh
$ alias R="ramda --js"
$ echo 1 | R '(x) => x + 1'
2
```

## using packages from npm

Packages installed to `$HOME/node_modules` can used with `require()`.

```sh
$ date -u +"%Y-%m-%dT%H:%M:%SZ" | R -r 'require \timeago'
less than a minute ago
```

## debugging

You can turn on the debug output with `-v, --verbose` flag.

```sh
ramda-cli 'R.sum' +0ms input code
ramda-cli 'R.sum;' +14ms compiled code
ramda-cli [Function: f1] +4ms evaluated to
```

[`treis`][treis] is available for debugging individual functions in the
pipeline. Wrap a function with `treis` to decorate it with debugging
capabilities. It will make the function print its input and output values.

<img width="370" height="99" src="https://raw.githubusercontent.com/raine/ramda-cli/media/treis-face.png" />

## why livescript?

> [LiveScript][livescript] is a language which compiles to JavaScript. It has
a straightforward mapping to JavaScript and allows you to write expressive
code devoid of repetitive boilerplate.

- Function composition operators `.`, `<<`, `>>`
- Implicit access `(.length)`
- Operators as functions `(+ 1)`

See also: [Essential LiveScript for ramda-cli][essential-livescript]

## javascript support

With the release of node v4 came the ES6 arrow function syntax without a
compilation penalty. This makes JS more attractive choice for ramda-cli, so
now there is `--js` flag.

```sh
echo '[1,2,3]' | R --js 'map(x => x + 1)'
[
  2,
  3,
  4
]
```

--

[![wercker status](https://app.wercker.com/status/92dbf35ece249fade3e8198181d93ec1/s/master "wercker status")](https://app.wercker.com/project/bykey/92dbf35ece249fade3e8198181d93ec1)

[flat]: https://github.com/hughsk/flat
[1]: http://en.wikipedia.org/wiki/Function_composition_%28computer_science%29
[livescript]: http://livescript.net
[treis]: https://github.com/raine/treis
[hyperscript]: https://github.com/dominictarr/hyperscript
[ramda]: http://ramdajs.com
[ramda-docs]: http://ramdajs.com/docs/
[tutorial]: https://gistlog.co/raine/d12d0ec3e72b2945510b
[essential-livescript]: https://gistlog.co/raine/6486b985c767954781b1
[cookbook]: https://github.com/raine/ramda-cli/wiki/Cookbook
