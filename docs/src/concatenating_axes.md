# Concatenating Axes

Concatenating axes can happen by one of the following:
1. Stacking two collections of completely unique elements
2. Resizing a range of values

The second only happens when the two collections provided are subtypes of `AbstractRange`.

Customizing concatenating axes should be accomplished through either `AxisIndices.CombineStyle` or `AxisIndices.cat_axis!`.
```@docs
AxisIndices.cat_axis
AxisIndices.cat_axes
AxisIndices.hcat_axes
AxisIndices.vcat_axes
```

