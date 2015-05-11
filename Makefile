.PHONY: test

MOCHA = ./node_modules/.bin/mocha
NAME = $(shell node -e "console.log(require('./package.json').name)")
REPORTER ?= spec
GREP ?= ".*"
MOCHA_ARGS = --grep $(GREP)

install:
	npm install -g .

reinstall:
	$(MAKE) uninstall
	$(MAKE) install

uninstall:
	npm uninstall -g ${NAME}

dev-install: package.json
	npm install .

publish: test
	git push --tags origin HEAD:master
	npm publish

test:
	@$(MOCHA) $(MOCHA_ARGS) --reporter $(REPORTER)

test-w:
	@$(MOCHA) $(MOCHA_ARGS) --reporter min --watch
