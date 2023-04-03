# LibDDRV

![Github Actions](https://github.com/valorem-labs-inc/LibDDRV/workflows/CI/badge.svg)

Library for generating discrete random variates from a set of dynamically weighted elements in Solidity.

Based on [this paper](https://kuscholarworks.ku.edu/bitstream/handle/1808/7224/MVN03.dynamic_rv_gen.pdf).

The algorithm preprocesses a list of weighted elements into a forest of trees data structure, and then 
traverses that forest to generate a random variate from the discrete distribution in sublinear time.
Critically, the library supports inserting, updating, and deleting elements from the forest.

_more to come_

## Getting Started

## Contributing

## Security
