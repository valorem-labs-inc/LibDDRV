# LibDDRV

![Github Actions](https://github.com/valorem-labs-inc/LibDDRV/workflows/CI/badge.svg)

A library for generating dynamically weighted discrete probability mass 
function random variates in solidity, given a source of uniform randomness.

Based on [this paper](https://kuscholarworks.ku.edu/bitstream/handle/1808/7224/MVN03.dynamic_rv_gen.pdf).

The algorithm preprocesses a list of weights into a forest of trees, and then 
traverses that forest to generate these random numbers in sub-linear time.

## Getting Started

Click "Use this template" on [GitHub](https://github.com/foundry-rs/forge-template) to create a new repository with this repo as the initial state.

Or, if your repo already exists, run:
```sh
forge init
forge build
forge test
```

## Development

This project uses [Foundry](https://getfoundry.sh). See the [book](https://book.getfoundry.sh/getting-started/installation.html) for instructions on how to install and use Foundry.
