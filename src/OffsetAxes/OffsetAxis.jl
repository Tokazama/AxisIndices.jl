
# TODO OffsetAxis
# - impliment similar_type
# - implement constructors that use Val for static offset
# 

@inline function _construct_offset_keys(offset::T, inds::Tuple{Vararg{<:AbstractUnitRange{<:Integer}}}) where {T}
    if is_static(inds)
        return UnitSRange{T}(first(inds) + offset, last(inds) + offset)
    elseif is_fixed(inds)
        return UnitRange{T}(first(inds) + offset, last(inds) + offset)
    else
        return UnitMRange{T}(first(inds) + offset, last(inds) + offset)
    end
end


Base.parentindices(axis::OffsetAxis) = getfield(axis, :parent_indices)
function Interface.unsafe_reconstruct(axis::OffsetAxis{I,Ks}, inds::Inds) where {I,Ks,Inds}
    return similar_type(axis, Ks, Inds)(
        Ks(first(inds) + first(axis) - first(indices(axis)), last(inds) + last(axis) - last(indices(axis))),
        inds
    )
end

#@inline function Interface.assign_indices(axis::OffsetAxis, inds::AbstractIndices)
#    return OffsetAxis{keytype(axis),eltype(inds),keys_type(axis),typeof(inds)}(keys(axis), inds)
#end


function _reset_keys!(axis::OffsetAxis{I,Ks,Inds}, len) where {I,Ks,Inds}
    ks = keys(axis)
    set_length!(ks, len)
end


"""
    offset(x)

Shortcut for creating `OffsetAxis` where `x` is the first argument to [`OffsetAxis`](@ref).

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisArray(ones(3), offset(2))
3-element AxisArray{Float64,1}
 • dim_1 - 3:5

  3   1.0
  4   1.0
  5   1.0

```
"""
offset(x) = inds -> OffsetAxis(x, inds)


known_offset(::Type{<:OffsetAxis{<:Any,Val{F}}}) where {F} = F
known_offset(::Type{<:OffsetAxis}) = nothing

get_offset(axis::OffsetAxis) = getfield(axis, :offset)

parent_indices_type(::Type{T}) where {Inds,T<:OffsetAxis{<:Any,<:Any,Inds}} = Inds

