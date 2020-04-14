
"""
## AxisIndices Examples
```jldoctest
julia> using AxisIndices

julia> a = AxisIndicesArray([1 2; 3 4], ["a", "b"], ["one", "two"])
2-dimensional AxisIndicesArray{Int64,2,Array{Int64,2}...}
      one   two
  a     1     2
  b     3     4


julia> b = rot180(a)
2-dimensional AxisIndicesArray{Int64,2,Array{Int64,2}...}
      two   one
  b     4     3
  a     2     1


julia> c = rotr90(rotr90(a))
2-dimensional AxisIndicesArray{Int64,2,Array{Int64,2}...}
      two   one
  b     4     3
  a     2     1


julia> a["a", "one"] == b["a", "one"] == c["a", "one"]
true
```
"""
Base.rot180(x::AbstractAxisIndices) = unsafe_rot180(x, rot180(parent(x)))
function unsafe_rot180(x::AbstractAxisIndices, p::AbstractArray)
    return unsafe_reconstruct(
        x,
        p,
        (reverse_keys(axes(x, 1), axes(p, 1)),
         reverse_keys(axes(x, 2), axes(p, 2)))
    )
end


"""
## AxisIndices Examples
```jldoctest
julia> using AxisIndices

julia> a = AxisIndicesArray([1 2; 3 4], ["a", "b"], ["one", "two"])
2-dimensional AxisIndicesArray{Int64,2,Array{Int64,2}...}
      one   two
  a     1     2
  b     3     4


julia> b = rotr90(a)
2-dimensional AxisIndicesArray{Int64,2,Array{Int64,2}...}
        b   a
  one   3   1
  two   4   2


julia> a["a", "one"] == b["one", "a"]
true
```
"""
Base.rotr90(x::AbstractAxisIndices) = unsafe_rotr90(x, rotr90(parent(x)))
function unsafe_rotr90(x::AbstractAxisIndices, p::AbstractArray)
    unsafe_reconstruct(
        x,
        p,
        (similar_axis(axes(x, 2), nothing, axes(p, 1), false),
         reverse_keys(axes(x, 1), axes(p, 2)))
    )
end

"""
## AxisIndices Examples
```jldoctest
julia> using AxisIndices

julia> a = AxisIndicesArray([1 2; 3 4], ["a", "b"], ["one", "two"])
2-dimensional AxisIndicesArray{Int64,2,Array{Int64,2}...}
      one   two
  a     1     2
  b     3     4


julia> b = rotl90(a)
2-dimensional AxisIndicesArray{Int64,2,Array{Int64,2}...}
        a   b
  two   2   4
  one   1   3


julia> a["a", "one"] == b["one", "a"]
true

```
"""
Base.rotl90(x::AbstractAxisIndices) = unsafe_rotl90(x, rotl90(parent(x)))
function unsafe_rotl90(x::AbstractAxisIndices, p::AbstractArray)
    unsafe_reconstruct(
        x,
        p,
        (reverse_keys(axes(x, 2), axes(p, 1)),
         similar_axis(axes(x, 1), nothing, axes(p, 2), false))
    )
end

