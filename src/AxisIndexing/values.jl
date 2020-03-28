
Base.valtype(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs} = V

Base.allunique(a::AbstractAxis) = true

Base.in(x::Integer, a::AbstractAxis) = in(x, values(a))

"""
    values_type(x)

Retrieves the type of the values of `x`. This should be functionally equivalent
to `typeof(values(x))`.

## Examples
```jldoctest
julia> using AxisIndices

julia>  values_type(Axis(1:2))
Base.OneTo{Int64}

julia> values_type(typeof(Axis(1:2)))
Base.OneTo{Int64}

julia> values_type(typeof(1:2))
UnitRange{Int64}
```
"""
values_type(::T) where {T} = values_type(T)
# if it's not a subtype of AbstractAxis assume it is the collection of values
values_type(::Type{T}) where {T} = T  
values_type(::Type{<:AbstractAxis{K,V,Ks,Vs}}) where {K,V,Ks,Vs} = Vs

"""
    values_type(x, i)

Retrieves axis values of the ith dimension of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia>  values_type([1], 1)
Base.OneTo{Int64}

julia> values_type(typeof([1]), 1)
Base.OneTo{Int64}
```
"""
values_type(::T, i) where {T} = values_type(T, i)
values_type(::Type{T}, i) where {T} = values_type(axes_type(T, i))

