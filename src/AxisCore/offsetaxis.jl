
#=
    OffsetAxis
The keys act as the indices for an OffsetAxis. So the `values(::OffsetAxis)` have
the indices `keys(::OffsetAxis)`
=#
struct OffsetAxis{V,Vs} <: AbstractOffsetAxis{V,Vs}
    offset::V
    values::Vs

    function OffsetAxis{V,Vs}(offset::V, r::Vs) where {V<:Integer,Vs<:AbstractUnitRange{V}}
        return new{V,Vs}(offset, r)
    end
end

Base.values(axis::OffsetAxis) = getfield(axis, :values)

offset(r::OffsetAxis) = getfield(r, :offset)

# args: range
OffsetAxis(vs::AbstractUnitRange) = OffsetAxis(0, vs)
OffsetAxis{V}(vs::AbstractUnitRange) where {V} = OffsetAxis{V}(zero(V), vs)
OffsetAxis{V,Vs}(vs::AbstractUnitRange) where {V,Vs} = OffsetAxis{V,Vs}(zero(V), vs)
function OffsetAxis{V}(r::OffsetAxis) where V<:Integer
    return OffsetAxis(offset(r), convert(AbstractUnitRange{V}, values(r)))
end
OffsetAxis(r::OffsetAxis) = r

# args: 2xrange
OffsetAxis(ks::AbstractUnitRange, vs::AbstractUnitRange{V}) where {V} = OffsetAxis{V}(ks, vs)
function OffsetAxis{V}(ks::AbstractUnitRange, vs::AbstractUnitRange{V}) where {V}
    return OffsetAxis{V,typeof(vs)}(ks, vs)
end
function OffsetAxis{V}(ks::AbstractUnitRange, vs::AbstractUnitRange) where {V}
    return OffsetAxis{V}(ks, convert(AbstractUnitRange{V}, vs))
end
function OffsetAxis{V,Vs}(ks::AbstractUnitRange, vs::AbstractUnitRange) where {V<:Integer,Vs<:AbstractUnitRange{V}}
    check_axis_length(ks, vs)
    return OffsetAxis{V,Vs}(compute_offset(vs, ks), vs)
end

# args: offset, range
function OffsetAxis{V,Vs}(offset::Integer, r::AbstractUnitRange) where {V<:Integer,Vs<:AbstractUnitRange{V}}
    o, rc = offset_coerce(Vs, r)
    return OffsetAxis{V,Vs}(convert(V, o + offset), rc)
end
function OffsetAxis{V}(offset::Integer, r::AbstractUnitRange) where V<:Integer
    rc = convert(AbstractUnitRange{V}, r)::AbstractUnitRange{V}
    return OffsetAxis{V,typeof(rc)}(convert(V, offset), rc)
end
function OffsetAxis(offset::Integer, r::AbstractUnitRange{V}) where V<:Integer
    return OffsetAxis{V,typeof(r)}(convert(V, offset), r)
end
function OffsetAxis(f::Integer, r::AbstractAxis{K,V}) where {K,V<:Integer}
    return OffsetAxis{V}(convert(V, f + (first(r) - 1)), values(r))
end

# Coercion from other OffsetAxis
@inline function OffsetAxis{V,Vs}(r::AbstractOffsetAxis) where {V<:Integer,Vs<:AbstractUnitRange{V}}
    return OffsetAxis{V,Vs}(offset(r), values(r))  # -> OffsetAxis{V,Vs}(::Integer, ::AbstractUnitRange)
end

function offset_coerce(::Type{Base.OneTo{V}}, r::AbstractUnitRange) where V<:Integer
    o = first(r) - 1
    return o, Base.OneTo{V}(last(r) - o)
end

function offset_coerce(::Type{Base.OneTo{V}}, r::Base.OneTo) where V<:Integer
    return 0, convert(Base.OneTo{V}, r)
end

# function offset_coerce(::Type{Base.OneTo{T}}, r::OffsetAxis) where T<:Integer
#     rc, o = offset_coerce(Base.OneTo{T}, r.parent)

# Fallback, specialze this method if `convert(I, r)` doesn't do what you need
function offset_coerce(::Type{Vs}, r::AbstractUnitRange) where Vs<:AbstractUnitRange{V} where V
    return 0, convert(Vs, r)
end

# TODO: uncomment these when Julia is ready
# # Conversion preserves both the values and the indexes, throwing an InexactError if this
# # is not possible.
# Base.convert(::Type{OffsetAxis{V,Vs}}, r::OffsetAxis{V,Vs}) where {V<:Integer,Vs<:AbstractUnitRange{V}} = r
# Base.convert(::Type{OffsetAxis{V,Vs}}, r::OffsetAxis) where {V<:Integer,Vs<:AbstractUnitRange{V}} =
#     OffsetAxis{V,Vs}(convert(Vs, r.parent), r.offset)
# Base.convert(::Type{OffsetAxis{V,Vs}}, r::AbstractUnitRange) where {V<:Integer,Vs<:AbstractUnitRange{V}} =
#     OffsetAxis{V,Vs}(convert(Vs, r), 0)

function AxisCore.unsafe_reconstruct(axis::OffsetAxis, vs::Vs) where {Ks,Vs}
    return similar_type(axis, Vs)(offset(axis), vs)
end

function assign_indices(axis::OffsetAxis, inds)
    return OffsetAxis(offset(axis), inds)
end

function StaticRanges.similar_type(::A, vs_type::Type=values_type(A)) where {A<:OffsetAxis}
    return StaticRanges.similar_type(A, vs_type)
end

function StaticRanges.similar_type(::Type{A}, vs_type::Type=values_type(A)) where {A<:OffsetAxis}
    return OffsetAxis{eltype(vs_type),vs_type}
end

function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:OffsetAxis,Y<:OffsetAxis}
    return OffsetAxis{
        promote_type(eltype(X),eltype(Y)),
        promote_type(values_type(X),values_type(Y))
    }
end

###
###
###
to_offset_axis(i::Integer, index::AbstractUnitRange) = OffsetAxis(i, index)
to_offset_axis(i::Integer, index::AbstractAxis) = OffsetAxis(i + offset(index), values(index))
to_offset_axis(i::AbstractUnitRange, index::AbstractUnitRange) = OffsetAxis(i, index)
to_offset_axis(i::AbstractUnitRange, index::AbstractAxis) = OffsetAxis(i, values(index))

@inline function to_offset_axes(A::AbstractArray{T,N}, inds::Tuple) where {T,N}
    return map((index, axis) -> to_offset_axis(index, axis), inds, axes(A))
end

@inline function to_offset_axes(A::AbstractVector{T}, inds::Tuple) where {T}
    if is_dynamic(A)
        return to_offset_axis(first(inds), as_dynamic(axes(A, 1)))
    else
        return to_offset_axis(first(inds), axes(A, 1))
    end
end

