# Axes to Arrays

Most of the methods up to this point are potentially useful for manipulating an axis independent of a parent structure that it may belong to.
However, we want it to be easy to use an `AbstractAxis` in a variety of settings.
The following methods are likely to only be useful when extending the use of a multidimensional arrays to use the `AbstractAxis` interface.

## Swapping Axes

```@docs
AxisIndices.drop_axes
AxisIndices.permute_axes
AxisIndices.reduce_axes
AxisIndices.reduce_axis
```
## Matrix Multiplication and Statistics

```@docs
AxisIndices.matmul_axes
AxisIndices.inverse_axes
AxisIndices.covcor_axes
```
