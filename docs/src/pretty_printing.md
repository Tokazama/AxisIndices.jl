# Pretty Printing

!!! warning
    Currently pretty printing is an experimental feature that may undergo rapid changes.

It's important that we can view the custom indices that we assign to arrays.
Yet a surprising challenge of implementing and using arrays in interactive programming is how [complicated](https://github.com/JuliaLang/julia/blob/master/base/arrayshow.jl) printing them can be.
Rather than burdening users with cryptic text readouts this package seeks to provide "pretty" printing (quotes because beauty is in the eye of the beholder).
This package leans heavily on the [PrettyTables.jl](https://github.com/ronisbr/PrettyTables.jl) package to accomplish this by handing off everything that goes through the `show` method to `pretty_array`.
`pretty_array` in turn repeatedly calls `PrettyTables.pretty_print` along slices of arrays.

```@docs
AxisIndices.pretty_array
```
