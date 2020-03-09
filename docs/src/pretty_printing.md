# Pretty Printing

!!! warning
    Currently pretty printing is an experimental feature that may undergo rapid changes.

Each 2-dimensional `AbstractAxisIndices` subtype prints with keyword arguments passed to `PrettyTables`.
N-dimensional arrays iteratively call matrix printing similar to how base Julia does (but passing keyword arguments for pretty printing).
Keywords are incorporated through the `show` method (e.g., `show(::IO, ::AbstractAxisIndices; kwargs...)`) ore threw a call to `pretty_array`.
Documentation for pretty printing is still being developed but you can look at the "CoefTable" example to get a better idea of how flexible this can be.

```jldoctest
julia> using AxisIndices

julia> AxisIndicesArray(ones(2,2,2), (2:3, [:one, :two], ["a", "b"]))
3-dimensional AxisIndicesArray{Float64,3,Array{Float64,3}...}
[dim1, dim2, dim3[a]] =
      one   two
  2   1.0   1.0
  3   1.0   1.0


[dim1, dim2, dim3[b]] =
      one   two
  2   1.0   1.0
  3   1.0   1.0

```
