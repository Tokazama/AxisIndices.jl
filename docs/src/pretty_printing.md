# Pretty Printing

!!! warning
    Currently pretty printing is an experimental feature that may undergo rapid changes.

Each 2-dimensional `AbstractAxisIndices` subtype prints with keyword arguments passed to `PrettyTables`.
N-dimensional arrays iteratively call matrix printing similar to how base Julia does (but passing keyword arguments for pretty printing).
Keywords are incorporated through the `show` method (e.g., `show(::IO, ::AbstractAxisIndices; kwargs...)`).

```jldoctest
julia> using AxisIndices

julia> AxisIndicesArray(reshape(1:16, (2,2,2,2)), ([:a, :b], ["a", "b"], ["c", "d"], ["e", "f"]))
4-dimensional AxisIndicesArray{Int64,4,...} with axes:
    :axis 1, Axis(Symbol[:a, :b] => OneToMRange(2))
    :axis 2, Axis(["a", "b"] => OneToMRange(2))
    :axis 3, Axis(["c", "d"] => OneToMRange(2))
    :axis 4, Axis(["e", "f"] => OneToMRange(2))
[:, :, c, e] =
      e       f
  1.000   3.000
  2.000   4.000


[:, :, d, e] =
      e       f
  5.000   7.000
  6.000   8.000


[:, :, c, f] =
       e        f
   9.000   11.000
  10.000   12.000


[:, :, d, f] =
       e        f
  13.000   15.000
  14.000   16.000

```
