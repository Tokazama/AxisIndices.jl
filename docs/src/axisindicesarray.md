# Arrays With Axes

The following describes many of the available methods for accommodating multidimensional manipulation of types that have axes.

## AbstractAxisIndices Interface

A minimal interface for creating arrays that use the `AbstractAxis`'s is offered via `AbstractAxisIndices`.
The only methods that absolutely needs to be defined for a subtype of `AbstractAxisIndices` are `axes`, `parent`, `similar_type`, and `similar`.
Most users should find the provided `AxisIndicesArray` subtype is sufficient for the majority of use cases.
Although custom behavior may be accomplished through a new subtype of `AbstractAxisIndices`, customizing the behavior of many methods described herein can be accomplished through a unique subtype of `AbstractAxis`.

This implementation is meant to be basic, well documented, and have sane defaults that can be overridden as necessary.
In other words, default methods for manipulating arrays that return an `AxisIndicesArray` should not cause unexpected downstream behavior for users;
and developers should be able to freely customize the behavior of `AbstractAxisIndices` subtypes with minimal effort.

```@docs
AxisIndices.AxisIndicesArray
```

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
