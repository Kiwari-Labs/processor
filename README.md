<img align="right" width="150" height="150" top="100" src="./public/kiwarilabs.jpg">

# processor • [![tests](https://github.com/refcell/femplate/actions/workflows/ci.yml/badge.svg?label=tests)](https://github.com/refcell/femplate/actions/workflows/ci.yml) ![license](https://img.shields.io/github/license/refcell/femplate?label=license) ![solidity](https://img.shields.io/badge/solidity-^0.8.17-lightgrey)

`processor` is a Solidity library that provides utility functions to efficiently handle general computational tasks. It focuses on **optimizing performance** and **reducing gas costs** for various operations in smart contracts.  

### Installing

```
npm install --save-dev @kiwarilabs/processor
```

### Usage

**Building & Testing**

Build the foundry project with `forge build`. Then you can run tests with `forge test`.

**Deployment & Verification**

Inside the [`utils/`](./utils/) directory are a few preconfigured scripts that can be used to deploy and verify contracts.

Scripts take inputs from the cli, using silent mode to hide any sensitive information.

_NOTE: These scripts are required to be _executable_ meaning they must be made executable by running `chmod +x ./utils/*`._

_NOTE: these scripts will prompt you for the contract name and deployed addresses (when verifying). Also, they use the `-i` flag on `forge` to ask for your private key for deployment. This uses silent mode which keeps your private key from being printed to the console (and visible in logs)._


### I'm new, how do I get started?

We created a guide to get you started with: [GETTING_STARTED.md](./GETTING_STARTED.md).


### Blueprint

```txt
lib
├─ forge-std — https://github.com/foundry-rs/forge-std
├─ solmate — https://github.com/transmissions11/solmate
scripts
├─ Deploy.s.sol — Example Contract Deployment Script
src
├─ Greeter — Example Contract
├─ compression
│  └── P2U128.sol — Packed 2 Uint128 to Uint256 Library
├─ datastructure
│  └── PU128LL.sol — Packed Uint128 Linked List Library
test
├─ Greeter.t.sol — Example Contract Tests
├─ compression
│  └── P2U128.t.sol — Packed 2 Uint128 to Uint256 Library Tests
├─ datastructure
│  └── PU128LL.t.sol — Packed Uint128 Linked List Library Tests
```


### Notable Mentions

- [femplate](https://github.com/refcell/femplate)
- [foundry](https://github.com/foundry-rs/foundry)
- [solmate](https://github.com/Rari-Capital/solmate)
- [forge-std](https://github.com/brockelmore/forge-std)
- [forge-template](https://github.com/foundry-rs/forge-template)
- [foundry-toolchain](https://github.com/foundry-rs/foundry-toolchain)


### Disclaimer

_These smart contracts are being provided as is. No guarantee, representation or warranty is being made, express or implied, as to the safety or correctness of the user interface or the smart contracts. They have not been audited and as such there can be no assurance they will work as intended, and users may experience delays, failures, errors, omissions, loss of transmitted information or loss of funds. The creators are not liable for any of the foregoing. Users should proceed with caution and use at their own risk._

---
All code under `src` Copyright (C) Kiwari Labs. All rights reserved.  
See [LICENSE](./LICENSE) for more details.
