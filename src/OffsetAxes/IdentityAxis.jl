
Base.keys(axis::IdentityAxis) = getfield(axis, :keys)

Base.parentindices(axis::IdentityAxis) = getfield(axis, :parent_indices)

Interface.is_indices_axis(::Type{<:IdentityAxis}) = false
function Interface.unsafe_reconstruct(axis::IdentityAxis, ks::Ks, inds::Inds) where {Ks,Inds}
    return IdentityAxis{eltype(Ks),Ks,Inds}(ks, inds, false)
end

function _reset_keys!(axis::IdentityAxis, len)
    ks = keys(axis)
    set_length!(ks, len)
end

#=
for (f, FT, arg) in ((:-, typeof(-), Number),
                     (:+, typeof(+), Real),
                     (:*, typeof(*), Real))
    @eval begin
        function Base.broadcasted(::DefaultArrayStyle{1}, ::$FT, x::$arg, r::AbstractAxis)
            return _broadcast(r, broadcast($f, x, indices(r)))
        end
        function Base.broadcasted(::DefaultArrayStyle{1}, ::$FT, r::AbstractAxis, x::$arg)
            return _broadcast(r, broadcast($f, indices(r), x))
        end
    end
end
=#

#=
function Base.:(==)(r::IdentityAxis, s::IdentityAxis)
    return (first(r) == first(s)) & (step(r) == step(s)) & (last(r) == last(s))
end

function Base.:(==)(r::IdentityAxis, s::OrdinalRange)
    return (first(r) == first(s) == first(axes(s)[1])) & (step(r) == step(s)) & (last(r) == last(s))
end

Base.:(==)(s::OrdinalRange, r::IdentityAxis) = r == s
=#
# TODO IdentityAxis examples
"""
    idaxis(inds::AbstractUnitRange{<:Integer}) -> IdentityAxis

Shortcut for creating [`IdentityAxis`](@ref).

## Examples

```jldoctest
julia> using AxisIndices

julia> AxisArray(ones(3), idaxis)[2:3]
2-element AxisArray{Float64,1}
 • dim_1 - 2:3

  2   1.0
  3   1.0


```
"""
idaxis(inds) = IdentityAxis(inds)

parent_indices_type(::Type{T}) where {Inds,T<:IdentityAxis{<:Any,<:Any,Inds}} = Inds

