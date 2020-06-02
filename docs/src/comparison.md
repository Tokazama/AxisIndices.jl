# Comparison to Other Packages

This is very brief overview of how AxisIndices compares to other packages.
Rather than a comprehensive comparison of available alternatives and integrations, this is intended to provide a general idea of how AxisIndices fits in the Julia ecosystem.

[AxisArrays.jl](https://github.com/JuliaArrays/AxisArrays.jl) similarly supports mapping some sort of keys to each set of indices.
AxisIndices is intended to be a more comprehensive, well documented, and flexible implementation of this concept.
AxisArays natively offers the ability to name each dimension.
In contrast AxisIndices was developed with the intention of using packages like [NamedDims.jl](https://github.com/invenia/NamedDims.jl) to more fully implement such features in a complementary way.

[DimensionalData.jl](https://github.com/rafaqz/DimensionalData.jl) is a notable package that covers many similar funcitonalities as AxisArrays did.
There are numerous differences in design decisions between this package and DimensionalData.
It's likely that the majority of these differences represent personal preferences rather than strictly objective advantages over one another.
In terms of approach, DimensionalData offers a more comprehensive alternative to the functionality of AxisArrays, where AxisIndices is intended only to be a highly customizable component of some of the features AxisArrays offers.
Therefore, this package expects users seeking a complete replacement for AxisArrays to ultimately use another package that composes a modular solution to replacing AxisArrays.

There are many packages that offer overlapping features.
For example, [Dictionaries.jl](https://github.com/andyferris/Dictionaries.jl) implements a focused improvement on dictionaries where mapping keys to indices highly overlaps.
However, as Dictionaries.jl continues to evolve many of the types provided therein may prove extremely useful in constructing the keys of an `Axis` type thereby giving these dictionaries multidimensional functionality.
Similarly, many packages provide overlapping features that could actually be extended with the addition of AxisIndices.


