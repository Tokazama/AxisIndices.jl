
"""
    IdentityAxis(start, stop) -> axis
    IdentityAxis(keys::AbstractUnitRange) -> axis
    IdentityAxis(keys::AbstractUnitRange, indices::AbstractUnitRange) -> axis


These are particularly useful for creating `view`s of arrays that
preserve the supplied axes:
```julia
julia> a = rand(8);

julia> v1 = view(a, 3:5);

julia> axes(v1, 1)
Base.OneTo(3)

julia> idr = IdentityAxis(3:5)
IdentityAxis(3:5 => Base.OneTo(3))

julia> v2 = view(a, idr);

julia> axes(v2, 1)
3:5
```
"""
struct IdentityAxis{I,Ks,Inds} <: AbstractOffsetAxis{I,Ks,Inds}
    keys::Ks
    indices::Inds

    @inline function IdentityAxis{I,Ks,Inds}(
        ks::AbstractUnitRange,
        inds::AbstractUnitRange,
        check_length::Bool=true
    ) where {I,Ks,Inds}
        check_length && check_axis_length(ks, inds)
        if ks isa Ks
            if inds isa Inds
                check_length && check_axis_length(ks, inds)
                return new{I,Ks,Inds}(ks, inds)
            else
                return IdentityAxis{I}(ks, Inds(inds), check_length)
            end
        else
            if inds isa Inds
                return IdentityAxis{I}(Ks(ks), inds, check_length)
            else
                return IdentityAxis{I}(Ks(ks), Inds(inds), check_length)
            end
        end
    end

    function IdentityAxis{I}(ks::AbstractUnitRange{<:Integer}) where {I}
        return IdentityAxis{I}(ks, OneTo{I}(length(ks)), false)
    end

    function IdentityAxis{I}(start::Integer, stop::Integer) where {I}
        return IdentityAxis{I}(UnitRange{I}(start, stop))
    end

    function IdentityAxis{I}(
        ks::AbstractUnitRange{<:Integer},
        inds::AbstractUnitRange{<:Integer},
        check_length::Bool=true
    ) where {I}

        return IdentityAxis{I,typeof(ks),typeof(inds)}(ks, inds, check_length)
    end

    function IdentityAxis(
        ks::AbstractUnitRange{<:Integer},
        inds::AbstractUnitRange{<:Integer},
        check_length::Bool=true
    )

        return IdentityAxis{eltype(inds),typeof(ks),typeof(inds)}(ks, inds, check_length)
    end

    IdentityAxis(start::Integer, stop::Integer) = IdentityAxis(start:stop)

    function IdentityAxis(ks::Ks) where {Ks}
        if is_static(ks)
            return IdentityAxis(ks, OneToSRange(length(ks)))
        elseif is_fixed(ks)
            return IdentityAxis(ks, OneTo(length(ks)))
        else  # is_dynamic
            return IdentityAxis(ks, OneToMRange(length(ks)))
        end
    end
end

Base.keys(axis::IdentityAxis) = getfield(axis, :keys)

Base.values(axis::IdentityAxis) = getfield(axis, :indices)

Interface.is_indices_axis(::Type{<:IdentityAxis}) = false

function StaticRanges.similar_type(
    ::Type{<:IdentityAxis},
    ::Type{Ks},
    ::Type{Inds}
) where {Ks,Inds}

    return IdentityAxis{eltype(Ks),Ks,Inds}
end

function StaticRanges.similar_type(
    ::Type{<:IdentityAxis},
    ::Type{Inds}
) where {Inds}

    if is_static(Inds)
        Ks = UnitSRange{eltype(Inds)}
    elseif is_fixed(Inds)
        Ks = UnitRange{eltype(Inds)}
    else
        Ks = UnitMRange{eltype(Inds)}
    end
    return IdentityAxis{eltype(Inds),Ks,Inds}
end

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

