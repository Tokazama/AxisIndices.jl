# Arrays With Axes

The following describes many of the available methods for accomodating multidimensional manipulation of types that have axes.

## AxisIndicesArray

`AxisIndicesArray` is provided as a convenient subtype of `AbstractArray` for using instances of `AbstractAxis`.
The implementation is meant to be basic and have sane defaults that can be overridden as necessary.
In other words, default methods for manipulating arrays that return an `AxisIndicesArray` should not cause unexpected downstream behavior for users.
However, it should also be possible to change the behavior of an `AxisIndicesArray` through unique subtypes of `AbstractAxis`.

## Concatenating Arrays With Axes

```@docs
AxisIndices.cat_axes
AxisIndices.hcat_axes
AxisIndices.vcat_axes
AxisIndices.cat_axis
AxisIndices.cat_values
AxisIndices.cat_keys
```

## Mutating Methods

```@docs
AxisIndices.append_axis
AxisIndices.append_axis!
AxisIndices.append_keys
AxisIndices.append_values
```

## Swapping Dimensions

### Drop Dimensions

```@docs
AxisIndices.drop_axes
```

### Permute Dimensions

```@docs
AxisIndices.permute_axes
```

### Covariance and Correlation

```@docs
AxisIndices.covcor_axes
```

## Linear Algebra

### Inverse Array

```@docs
AxisIndices.inverse_axes
```

### Matrix Multiplication

```@docs
AxisIndices.matmul_axes
```

### Diagonal

```@docs
AxisIndices.diagonal_axes
```

### Factorizations

```@docs
AxisIndices.get_factorization
```
