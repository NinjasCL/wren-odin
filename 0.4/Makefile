.PHONY: test docs

test t:
	odin test tests/ -all-packages

docs d:
	@python3 ../tools/wrendoc .
	@cd docs && mdbook build
