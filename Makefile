.PHONY: hooks example test docs

example e:
	odin run example.odin -file

hooks h:
	@make -f .hooks/Makefile

test t:
	@cd 0.4 && make t

docs d:
	@cd 0.4 && make d
	@rm -rf docs/0.4
	@mkdir -p docs/0.4
	@cp -r 0.4/docs/book/* docs/0.4
