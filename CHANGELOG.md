# CHANGELOG

## 5.0.0 - UNRELEASED

- Changed: `--import` parameter changes:
    - Installs referenced npm modules transparently as needed, no `npm
      install` required from user.
    - Syntax for defining an alias changed:
      Instead of `--import R=ramda`, use `--import ramda:R`.

## 4.0.0 - 2019-01-02

- Added: Interactive mode! Use with `--interactive`.
- Changed: Alias `-I` points to `--interactive` instead of `--import`.
- Changed: If no functions are given as arguments, uses `identity` function
    instead of showing `--help` output.
- Changed: When using JSON output type, functions are stringified instead of
    printed as `undefined`.
- Changed: `undefined` values are properly passed through the pipeline.
- Changed: In `--raw-output`, values of type object will be formatted with
    `JSON.stringify()` instead of `toString()`, meaning that objects won't
    appear as `[object Object]` in the output.

## 3.1.0 - 2018-02-21

- Added: `--csv-delimiter` option.

## 3.0.0 - 2018-02-21

- Changed: Add line change at end when using `--output-type csv`.

## 2.0.0 - 2017-12-03

- Changed: Updated ramda to `0.25.0`.

## 1.7.0 - 2017-06-07

- Added: `--[no-]headers` flag.

## 1.6.0 - 2017-03-24

- Added: `console` and `process` made available in evaluation context.

## 1.5.0 - 2017-03-23

- Added: `pickDotPaths` and `renameKeysBy` functions made available in
  evaluation context.
