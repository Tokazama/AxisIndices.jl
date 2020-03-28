
"""
    prev_type(x::T)

Returns the immediately lesser value of type `T`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.prev_type("b")
"a"

julia> AxisIndices.prev_type(:b)
:a

julia> AxisIndices.prev_type('b')
'a': ASCII/Unicode U+0061 (category Ll: Letter, lowercase)

julia> AxisIndices.prev_type(1)
0

julia> AxisIndices.prev_type(1.0)
0.9999999999999999

julia> AxisIndices.prev_type("")
""
```
"""
function prev_type(x::AbstractString)
    isempty(x) && return ""
    return x[1:prevind(x, lastindex(x))] * (last(x) - 1)
end
prev_type(x::Symbol) = Symbol(prev_type(string(x)))
prev_type(x::AbstractChar) = x - 1
prev_type(x::T) where {T<:AbstractFloat} = prevfloat(x)
prev_type(x::T) where {T} = x - one(T)

