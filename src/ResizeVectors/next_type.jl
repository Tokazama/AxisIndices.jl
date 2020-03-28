
"""
    next_type(x::T)

Returns the immediately greater value of type `T`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.next_type("b")
"c"

julia> AxisIndices.next_type(:b)
:c

julia> AxisIndices.next_type('a')
'b': ASCII/Unicode U+0062 (category Ll: Letter, lowercase)

julia> AxisIndices.next_type(1)
2

julia> AxisIndices.next_type(2.0)
2.0000000000000004

julia> AxisIndices.next_type("")
""
```
"""
function next_type(x::AbstractString)
    isempty(x) && return ""
    return x[1:prevind(x, lastindex(x))] * (last(x) + 1)
end
next_type(x::Symbol) = Symbol(next_type(string(x)))
next_type(x::AbstractChar) = x + 1
next_type(x::T) where {T<:AbstractFloat} = nextfloat(x)
next_type(x::T) where {T} = x + one(T)

