## Usage

### Pre Requisites

Before being able to run any command, you need to create a `.env` file and set a BIP-39 compatible mnemonic as an
environment variable. You can follow the example in `.env.example`. If you don't already have a mnemonic, you can use
this [website](https://iancoleman.io/bip39/) to generate one.

Then, proceed with installing dependencies:

```sh
$ pnpm install
```

### Format

Format the contracts:

```sh
$ forge fmt
```

### Compile

Compile the smart contracts with Hardhat:

```sh
$ forge compile
```

### TypeChain

Compile the smart contracts and generate TypeChain bindings:

```sh
$ pnpm typechain
```

### Test

Run the tests with Hardhat:

```sh
$ forge test
```

```sh
$ forge test --gas-report
```

forge test -vvvvv --match-path './test/foundry/CraftLogic.t.sol'

### Lint Solidity

Lint the Solidity code:

```sh
$ pnpm lint:sol
```

### Lint TypeScript

Lint the TypeScript code:

```sh
$ pnpm lint:ts
```

### Coverage

Generate the code coverage report:

```sh
$ forge coverage
```

````sh
$ forge coverage --report lcov && genhtml lcov.info --branch-coverage --output-dir coverage
```
https://www.rareskills.io/post/foundry-forge-coverage

### Report Gas

See the gas usage per unit test and average gas per method call:

```sh
$ forge test --gas-report
````

### Deploy

Deploy the contracts to Hardhat Network:

```sh
$ pnpm deploy-mum:polygon-mumbai
```

```sh
$ forge script script/Deploy.s.sol:Deploy --rpc-url polygon --broadcast --verify --legacy
```

### Setting

```sh
$ forge script script/Craft.s.sol:Craft --rpc-url polygon --broadcast --legacy
```

### Slither

```sh
slither src/ --solc-remaps "@gelatonetwork=node_modules/@gelatonetwork @openzeppelin/=lib/openzeppelin-contracts/contracts/"
```

### Sol2UML

```sh
sol2uml class ./src
```

### GitHub Actions

This template comes with GitHub Actions pre-configured. Your contracts will be linted and tested on every push and pull
request made to the `main` branch.
