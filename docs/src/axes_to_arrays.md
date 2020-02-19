# Axes to Arrays

Most of the methods up to this point are potentially useful for manipulating an axis independent of a parent structure that it may belong to.
However, we want it to be easy to use an `AbstractAxis` in a variety of settings.
The following methods are likely to only be useful when extending the use of a multidimensional arrays to use the `AbstractAxis` interface.

## Swapping Axes

```@docs
StaticRanges.drop_axes
StaticRanges.permute_axes
StaticRanges.reduce_axes
StaticRanges.reduce_axis
```
## Matrix Multiplication and Statistics

```@docs
StaticRanges.matmul_axes
StaticRanges.inverse_axes
StaticRanges.covcor_axes
```
