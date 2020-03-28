
import Base: rot180, rotr90, rotl90

function Base.rotl90(x::AbstractAxisIndices)
    return unsafe_reconstruct(x, rotl90(parent(x)), rotl90_axes(x))
end

function Base.rotr90(x::AbstractAxisIndices)
    return unsafe_reconstruct(x, rotr90(parent(x)), rotr90_axes(x))
end

function Base.rot180(x::AbstractAxisIndices)
    return unsafe_reconstruct(x, rot180(parent(x)), rot180_axes(x))
end

rot180_doc = """
## AxisIndices Examples
```jldoctest
julia> using AxisIndices

julia> a = AxisIndicesArray([1 2; 3 4], ["a", "b"], ["one", "two"])
2-dimensional AxisIndicesArray{Int64,2,Array{Int64,2}...}
      one   two
  a   1.0   2.0
  b   3.0   4.0


julia> b = rot180(a)
2-dimensional AxisIndicesArray{Int64,2,Array{Int64,2}...}
      two   one
  b   4.0   3.0
  a   2.0   1.0


julia> c = rotr90(rotr90(a))
2-dimensional AxisIndicesArray{Int64,2,Array{Int64,2}...}
      two   one
  b   4.0   3.0
  a   2.0   1.0


julia> a["a", "one"] == b["a", "one"] == c["a", "one"]
true
```
"""

rotr90_doc = """
## AxisIndices Examples
```jldoctest
julia> using AxisIndices

julia> a = AxisIndicesArray([1 2; 3 4], ["a", "b"], ["one", "two"])
2-dimensional AxisIndicesArray{Int64,2,Array{Int64,2}...}
      one   two
  a   1.0   2.0
  b   3.0   4.0


julia> b = rotr90(a)
2-dimensional AxisIndicesArray{Int64,2,Array{Int64,2}...}
          b     a
  one   3.0   1.0
  two   4.0   2.0


julia> a["a", "one"] == b["one", "a"]
true
```
"""

rotl90_doc = """
## AxisIndices Examples
```jldoctest
julia> using AxisIndices

julia> a = AxisIndicesArray([1 2; 3 4], ["a", "b"], ["one", "two"])
2-dimensional AxisIndicesArray{Int64,2,Array{Int64,2}...}
      one   two
  a   1.0   2.0
  b   3.0   4.0


julia> b = rotl90(a)
2-dimensional AxisIndicesArray{Int64,2,Array{Int64,2}...}
          a     b
  two   2.0   4.0
  one   1.0   3.0


julia> a["a", "one"] == b["one", "a"]
true
```
"""

@doc rot180_doc rot180
@doc rotr90_doc rotr90
@doc rotl90_doc rotl90

