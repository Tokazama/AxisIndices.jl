# AxisIndices.jl

[![Build Status](https://travis-ci.com/Tokazama/AxisIndices.jl.svg?branch=master)](https://travis-ci.com/Tokazama/AxisIndices.jl) [![codecov](https://codecov.io/gh/Tokazama/AxisIndices.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/Tokazama/AxisIndices.jl) [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://Tokazama.github.io/AxisIndices.jl/stable) [![](https://img.shields.io/badge/docs-dev-blue.svg)](https://Tokazama.github.io/AxisIndices.jl/dev)

Here are some reasons you should try AxisIndices
* **Flexible design** for **customizing multidimensional indexing** behavior
* **It's fast**. [StaticRanges](https://github.com/Tokazama/StaticRanges.jl) are used to speed up indexing ranges. If something is slow, please create a detailed issue.
* **Works with with Julia's standard library** (in progress). The end goal of AxisIndices is to fully integrate with the standard library wherever possible. If you can find a relevant method that isn't supported in `Base`or  `Statistics` then it's likely an oversight, so make an issue. `LinearAlgebra`, `MappedArrays`, and `NamedDims` also have some form of support.

The linked documentation provides a very brief ["Quick Start"](https://tokazama.github.io/AxisIndices.jl/dev/quick_start/) section along with detailed documentation of internal methods and types.

