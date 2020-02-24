# AxisIndices

The core contribution provided by AxisIndices is the `AbstractAxis` type.
It is a subtype of `AbstractUnitRange{<:Integer}` with an additional interface for creating keys and interacting with them.
This additional interface is intended to be easily extended to new types that may be needed for a variety of different situations.
An additional `AxisIndicesArray` type is provided that uses any subtype of `AbstractAxis` for each axis.
However, many methods are provided and documented internally so that it's easy for users to alter the behavior of an `AxisIndicesArray` with a new `AbstractAxis` subtype or create an entirely unique multidimensional structure.

The goals of this package are:
1. Facilitate multidimensional indexing (e.g., `instance_of_an_array[indices]`) that supports semantic user facing indices (e.g., `indices = Second(1)`).
2. Accomplishing the first goal should not interfere in the ability to perform the vast majority of array related methods (e.g, `vcat`, `append!`, etc.).
3. It should be easy to implement new subtypes of `AbstractAxis` that accommodate novel behavior and needs.

