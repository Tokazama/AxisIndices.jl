# AxisIndices

## Introduction

The goals of this package are:
1. Facilitate multidimensional indexing (e.g., `instance_of_an_array[indices]`) that supports semantic user facing indices (e.g., `indices = Second(1)`).
2. Accomplishing the first goal should not interfere in the ability to perform the vast majority of array related methods (e.g, `vcat`, `append!`, etc.).
3. It should be easy to implement new subtypes of `AbstractAxis` that accommodate novel behavior and needs.

These goals are accomplished predominantly through the `AbstractAxis` type.
It is a subtype of `AbstractUnitRange{<:Integer}` with an additional interface for creating keys and interacting with them.
This additional interface is intended to be easily extended to new types that may be needed for a variety of different situations.
An additional `AxisIndicesArray` type is provided that uses any subtype of `AbstractAxis` for each axis.
However, many methods are provided and documented internally so that it's easy for users to alter the behavior of an `AxisIndicesArray` with a new `AbstractAxis` subtype or create an entirely unique multidimensional structure.

## Where to go from here

* I just want to get something done.

Then start with the [Quick Start](@ref) section.
A slightly more in depth tutorial is provided with [Indexing Tutorial](@ref).

* I want to make my own axis type.

Look at the [TimeAxis Guide](@ref), which implements a custom axis type.

* I want to understand _why_/_how_ something works

If you've read the appropriate docstrings (under "References" or available in the REPL) and still have questions then various sections under "Manual" are a good place to look.
If that doesn't help then create an issue in the AxisIndices repo.
