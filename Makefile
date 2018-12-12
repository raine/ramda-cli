.PHONY: test

SRC = $(shell find src -name "*.ls" -type f | sort)
LIB = $(patsubst src/%.ls, lib/%.js, $(SRC))

MOCHA = ./node_modules/.bin/mocha
LSC = ./node_modules/.bin/lsc
DOCKER = docker run -v ${PWD}:/usr/src/app -w /usr/src/app -it --rm node:4.0.0
NAME = $(shell node -e "console.log(require('./package.json').name)")
REPORTER ?= spec
GREP ?= ".*"
MOCHA_ARGS = --grep $(GREP)
MOCHA_WATCH = $(MOCHA) $(MOCHA_ARGS) --reporter min --watch

default: all

lib:
	mkdir -p lib/

lib/%.js: src/%.ls lib
	$(LSC) -c -o "$(@D)" "$<"

all: compile

compile: $(LIB) package.json

install: clean all
	npm install -g .

reinstall: clean
	$(MAKE) uninstall
	$(MAKE) install

uninstall:
	npm uninstall -g ${NAME}

dev-install: package.json
	npm install .

clean:
	rm -rf lib

publish: all test
	git push --tags origin HEAD:master
	npm publish

test:
	@$(MOCHA) $(MOCHA_ARGS) --reporter $(REPORTER) test/unit/*.ls

test-w:
	@$(MOCHA_WATCH) test/unit/*.ls

test-func: compile
	@$(MOCHA) $(MOCHA_ARGS) --reporter $(REPORTER) test/functional/*.ls --timeout 30000

test-func-w: compile
	@$(MOCHA_WATCH) test/functional/*.ls --timeout 10000

docker-test-func:
	@$(DOCKER) make test-func

docker-test-func-w:
	@$(DOCKER) make test-func-w
