LIGO_COMPILER?=ligo
# ^ Override this variable when you run make command by make <COMMAND> ligo_compiler=<LIGO_EXECUTABLE>
# ^ Otherwise use default one
# Example to use Docker-provided Ligo compiler:
# make compile LIGO_COMPILER='docker run --rm -v "$(PWD)":"$(PWD)" -w "$(PWD)" ligolang/ligo:stable'
PROJECTROOT_OPT=--project-root .
protocol_opt?=
JSON_OPT?=--michelson-format json
tsc=npx tsc
help:
	@echo  'Usage:'
	@echo  '  all             - Remove generated Michelson files, recompile smart contracts and lauch all tests'
	@echo  '  clean           - Remove generated Michelson files'
	@echo  '  compile         - Compiles smart contract Factory'
	@echo  '  test            - Run integration tests (written in Ligo)'
	@echo  '  deploy          - Deploy smart contracts advisor & indice (typescript using Taquito)'
	@echo  ''

all: clean compile test

.PHONY: all compile test deploy clean
compile: fa2_nft.tz factory marketplace_nft.tz

factory: factory.tz factory.json

factory.tz: src/main.mligo
	@echo "Compiling smart contract to Michelson"
	@mkdir -p compiled
	@$(LIGO_COMPILER) compile contract $^ -e main $(protocol_opt) $(PROJECTROOT_OPT) > compiled/$@

factory.json: src/main.mligo
	@echo "Compiling smart contract to Michelson in JSON format"
	@mkdir -p compiled
	@$(LIGO_COMPILER) compile contract $^ $(JSON_OPT) -e main $(protocol_opt) $(PROJECTROOT_OPT) > compiled/$@

fa2_nft.tz: src/generic_fa2/core/instance/NFT.mligo
	@echo "Compiling smart contract FA2 to Michelson"
	@mkdir -p src/generic_fa2/compiled
	@$(LIGO_COMPILER) compile contract $^ -e main $(protocol_opt) $(PROJECTROOT_OPT) > src/generic_fa2/compiled/$@

marketplace_nft.tz: src/marketplace/main.mligo
	@echo "Compiling smart contract Marketplace to Michelson"
	@mkdir -p src/marketplace/compiled
	@$(LIGO_COMPILER) compile contract $^ -e main $(protocol_opt) $(PROJECTROOT_OPT) > src/marketplace/compiled/$@

clean: clean_contracts clean_fa2 clean_marketplace

clean_contracts:
	@echo "Removing Michelson files"
	@rm -f compiled/*.tz compiled/*.json

clean_fa2:
	@echo "Removing FA2 Michelson file"
	@rm -f src/generic_fa2/compiled/*.tz

clean_marketplace:
	@echo "Removing Marketplace Michelson file"
	@rm -f src/marketplace/compiled/*.tz


test: test_ligo test_marketplace

test_ligo: test/test.mligo
	@echo "Running integration tests"
	@$(LIGO_COMPILER) run test $^ $(protocol_opt) $(PROJECTROOT_OPT)

test_marketplace: test/test_marketplace.mligo
	@echo "Running integration tests (marketplace)"
	@$(LIGO_COMPILER) run test $^ $(protocol_opt) $(PROJECTROOT_OPT)

deploy: node_modules deploy.js

deploy.js:
	@if [ ! -f ./deploy/metadata.json ]; then cp deploy/metadata.json.dist deploy/metadata.json ; fi
	@echo "Running deploy script\n"
	@cd deploy && npm start

node_modules:
	@echo "Installing deploy script dependencies"
	@cd deploy && npm install
	@echo ""
