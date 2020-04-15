# Compatibility

The following packages outside of the `Base` module have some form of support.
In addition to creating awareness of existing functionality, the following provides users with a better idea of how exactly these packages are supported.
This means features existing outside of those described here are not within the domain of intended coverage and users should seek support linked resources.

## MappedArrays

[MappedArrays.jl](https://github.com/JuliaArrays/MappedArrays.jl) allows "lazy" in-place elementwise transformations of arrays.
Support is provided by overloading the `mappedarray` method, which AxisIndices does not export (i.e. users must `using mappedArrays` to get access to it).
In order to avoid method ambiguities multi-mapping of mixed `AbstractArray` and `AbstractAxisIndices` cannot be provided.
In other words, the current version can only support multi-mapping multiple `AbstractAxisIndices`.

## NamedDims

[NamedDims.jl](https://github.com/invenia/NamedDims.jl)

## OffsetArrays

Many of the tests used for `OffsetArrays` package have been incorporated into the tests of `AxisIndices` to ensure compatibility.

