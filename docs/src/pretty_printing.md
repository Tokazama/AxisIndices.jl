# Pretty Printing

!!! warning
    Currently pretty printing is an experimental feature that may undergo rapid changes.

Each 2-dimensional `AbstractAxisIndices` subtype prints with keyword arguments passed to `PrettyTables`.
N-dimensional arrays iteratively call matrix printing similar to how base Julia does (but passing keyword arguments for pretty printing).
Keywords are incorporated through the `show` method (e.g., `show(::IO, ::AbstractAxisIndices; kwargs...)`).

```jldoctest
julia> using AxisIndices

julia> AxisIndicesArray(1:2, ([:a, :b],))
1-dimensional AxisIndicesArray{Int64,1,UnitRange{Int64}...}

  a   1
  b   2

julia> AxisIndicesArray(reshape(1:4, (2,2)), ([:a, :b], ["a", "b"]))
2-dimensional AxisIndicesArray{Int64,2,Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}...}
      a   b
  a   1   3
  b   2   4

julia> AxisIndicesArray(reshape(1:16, (2,2,2,2)), ([:a, :b], ["a", "b"], ["c", "d"], ["e", "f"]))
4-dimensional AxisIndicesArray{Int64,4,Base.ReshapedArray{Int64,4,UnitRange{Int64},Tuple{}}...}
[dim1, dim2, dim1[c], dim4[e]] =
      e   f  
  c   1   3  
  d   2   4  


[dim1, dim2, dim1[d], dim4[e]] =
      e   f  
  c   5   7  
  d   6   8  


[dim1, dim2, dim1[c], dim4[f]] =
       e    f  
  c    9   11  
  d   10   12  


[dim1, dim2, dim1[d], dim4[f]] =
       e    f  
  c   13   15  
  d   14   16  

```
