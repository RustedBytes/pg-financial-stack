.PHONY: resolve test test-all smoke security concurrency install-order bench validate clean
PG ?= pg18

resolve:
	just resolve
test:
	just test $(PG)
test-all:
	just test-all
smoke:
	just smoke $(PG)
security:
	just test-security $(PG)
concurrency:
	just test-concurrency $(PG)
install-order:
	just test-install-order $(PG)
bench:
	just bench $(PG)
validate:
	just validate-stack
clean:
	just clean

