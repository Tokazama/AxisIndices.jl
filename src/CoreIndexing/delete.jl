
function StaticRanges.similar_type(
    ::Type{A},
    ks_type::Type=keys_type(A),
    vs_type::Type=parent_type(A)
) where {A<:Axis}

    return Axis{eltype(ks_type),eltype(vs_type),ks_type,vs_type}
end

function StaticRanges.similar_type(
    ::Type{SimpleAxis{I,Inds}},
    ks_type::Type=Inds,
    vs_type::Type=ks_type
) where {I,Inds}

    return SimpleAxis{eltype(vs_type),vs_type}
end

###
### similar
###
function StaticRanges.similar_type(
    ::Type{A},
    ks_type::Type=keys_type(A),
    vs_type::Type=ks_type
) where {A<:AbstractAxis}

    if is_indices_axis(A)
        return similar_type(A, ks_type, inds_type)
    else
        return similar_type(A, inds_type)
    end
end

"""
    similar(axis::AbstractAxis, new_keys::AbstractVector) -> AbstractAxis

Create a new instance of an axis of the same type as `axis` but with the keys `new_keys`

## Examples
```jldoctest
julia> using AxisIndices

julia> similar(Axis(1.0:10.0, 1:10), [:one, :two])
Axis([:one, :two] => 1:2)
```
"""
function Base.similar(axis::AbstractAxis, new_keys::AbstractVector)
    if is_static(axis)
        return unsafe_reconstruct(
            axis,
            as_static(new_keys),
            as_static(set_length(values(axis), length(new_keys)))
        )
    elseif is_fixed(axis)
        return unsafe_reconstruct(
            axis,
            as_fixed(new_keys),
            as_fixed(set_length(values(axis), length(new_keys)))
        )
    else
        return unsafe_reconstruct(
            axis,
            as_dynamic(new_keys),
            as_dynamic(set_length(values(axis), length(new_keys)))
        )
    end
end


#=
function Base.similar(
    axis::AbstractAxis,
    new_keys::AbstractUnitRange{T}
) where {K,V<:Integer,Ks,Vs<:AbstractUnitRange{V},T}

    if is_static(axis)
        return unsafe_reconstruct(
            axis,
            as_static(new_keys),
            as_static(set_length(values(axis), length(new_keys)))
        )
    elseif is_fixed(axis)
        return unsafe_reconstruct(
            axis,
            as_fixed(new_keys),
            as_fixed(set_length(values(axis), length(new_keys)))
        )
    else
        return unsafe_reconstruct(
            axis,
            as_dynamic(new_keys),
            as_dynamic(set_length(values(axis), length(new_keys)))
        )
    end
end
=#

"""
    similar(axis::AbstractAxis, new_keys::AbstractVector, new_indices::AbstractUnitRange{Integer} [, check_length::Bool=true] ) -> AbstractAxis

Create a new instance of an axis of the same type as `axis` but with the keys `new_keys`
and indices `new_indices`. If `check_length` is `true` then the lengths of `new_keys`
and `new_indices` are checked to ensure they have the same length before construction.

## Examples
```jldoctest
julia> using AxisIndices

julia> similar(Axis(1.0:10.0, 1:10), [:one, :two], UInt(1):UInt(2))
Axis([:one, :two] => 0x0000000000000001:0x0000000000000002)

julia> similar(Axis(1.0:10.0, 1:10), [:one, :two], UInt(1):UInt(3))
ERROR: DimensionMismatch("keys and indices must have same length, got length(keys) = 2 and length(indices) = 3.")
[...]
```
"""
function Base.similar(
    axis::AbstractAxis,
    new_keys::AbstractVector,
    new_indices::AbstractUnitRange{<:Integer},
    check_length::Bool=true
)

    check_length && check_axis_length(new_keys, new_indices)
    if is_static(axis)
        return unsafe_reconstruct(axis, as_static(new_keys), as_static(new_indices))
    elseif is_fixed(axis)
        return unsafe_reconstruct(axis, as_fixed(new_keys), as_fixed(new_indices))
    else
        return unsafe_reconstruct(axis, as_dynamic(new_keys), as_dynamic(new_indices))
    end
end

"""
    similar(axis::AbstractAxis, new_indices::AbstractUnitRange)

Create a new instance of an axis of the same type as `axis` but with the keys `new_keys`

## Examples
```jldoctest
julia> using AxisIndices

julia> similar(SimpleAxis(1:10), 1:3)
SimpleAxis(1:3)
```
"""
function Base.similar(axis::AbstractAxis, new_keys::AbstractUnitRange{<:Integer})
    if is_static(axis)
        return unsafe_reconstruct(axis, as_static(new_keys))
    elseif is_fixed(axis)
        return unsafe_reconstruct(axis, as_fixed(new_keys))
    else
        return unsafe_reconstruct(axis, as_dynamic(new_keys))
    end
end

const AbstractAxes{N} = Tuple{Vararg{<:AbstractAxis,N}}


function StaticRanges.similar_type(
    ::Type{<:CenteredAxis},
    ::Type{Ks},
    ::Type{Inds},
) where {Ks,Inds}

    return _centered_axis_similar_type(Ks, Inds)
end

function StaticRanges.similar_type(::Type{<:CenteredAxis}, ::Type{Ks}) where {Ks}
    return _centered_axis_similar_type(Ks)
end


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


# FIXME keys_type should never be included in this callTODO
function StaticRanges.similar_type(::Type{A}, ks_type::Type, inds_type::Type) where {A<:OffsetAxis}
    return OffsetAxis{eltype(inds_type),ks_type,inds_type}
end

function StaticRanges.similar_type(::Type{A}, inds_type::Type) where {A<:OffsetAxis}
    return OffsetAxis{eltype(inds_type),keys_type(A),inds_type}
end

function StaticRanges.similar_type(
    ::Type{StructAxis{T,L,V,Vs}},
    new_type::Type=T,
    new_vals::Type=OneToSRange{Int,nfields(T)}
) where {T,L,V,Vs}

    return StructAxis{T,nfields(T),eltype(new_vals),new_vals}
end

function StaticRanges.similar_type(::A, vs_type::Type=indices_type(A)) where {A<:CenteredAxis}
    return similar_type(A, vs_type)
end

function _centered_axis_similar_type(::Type{Ks}, ::Type{Inds}) where {Ks,Inds}
    if Ks <: OneToUnion
        error("CenteredAxis cannot have keys that start at one, got keys of type $Ks")
    else
        return CenteredAxis{eltype(Inds),Ks,Inds}
    end
end

function _centered_axis_similar_type(::Type{OneToSRange{T,L}}) where {T,L}
    start = _centered_start_from_len(T, L)
    return CenteredAxis{T,UnitSRange{T,start,_centered_stop_from_len_and_start(start, L)},OneToSRange{T,L}}
end

function _centered_axis_similar_type(::Type{UnitSRange{T,B,L}}) where {T,B,L}
    len = L - B + 1
    start = _centered_start_from_len(T, len)
    return CenteredAxis{T,UnitSRange{T,start,_centered_stop_from_len_and_start(start, len)},UnitSRange{T,B,L}}
end

function _centered_axis_similar_type(::Type{Inds}) where {Inds}
    I = eltype(Inds)
    return CenteredAxis{I,UnitRange{I},Inds}
end

function StaticRanges.similar_type(
    ::AxisArray{T,N,P,AI},
    parent_type::Type=P,
    axes_type::Type=AI
) where {T,N,P,AI}

    return AxisArray{eltype(parent_type), ndims(parent_type), parent_type, axes_type}
end

# TODO this should all be derived from the values of the axis
# Base.stride(x::AbstractAxisIndices) = axes_to_stride(axes(x))
#axes_to_stride()

for f in (:as_static, :as_fixed, :as_dynamic)
    @eval begin
        function StaticRanges.$f(x::A) where {A<:AbstractAxis}
            if is_indices_axis(A)
                return unsafe_reconstruct(x, StaticRanges.$f(values(x)))
            else
                return unsafe_reconstruct(x, StaticRanges.$f(keys(x)), StaticRanges.$f(values(x)))
            end
        end
    end
end

for f in (:is_static, :is_fixed)
    @eval begin
        function StaticRanges.$f(::Type{A}) where {A<:AbstractAxis}
            if is_indices_axis(A)
                return StaticRanges.$f(parent_indices_type(A))
            else
                return StaticRanges.$f(keys_type(A)) & StaticRanges.$f(parent_indices_type(A))
            end
        end
    end
end

# Using `CovVector` results in Method ambiguities; have to define more specific methods.
#for A in (Adjoint{<:Any, <:AbstractVector}, Transpose{<:Real, <:AbstractVector{<:Real}})
#    @eval function Base.:*(a::$A, b::AbstractAxisArray{T,1,<:AbstractVector{T}}) where {T}
#        return *(a, parent(b))
#    end
#end
#
#function Base.:*(A::AbstractMatrix, adjB::Adjoint{<:Any,<:AbstractTriangular})
#end

NamedDims.@declare_matmul(AxisMatrix, AxisVector)

# this only works if the axes are the same size
function Interface.unsafe_reconstruct(A::AbstractAxisArray{T1,N}, p::AbstractArray{T2,N}) where {T1,T2,N}
    return unsafe_reconstruct(A, p, map(assign_indices,  axes(A), axes(p)))
end

function permuteddimsview(A::NamedDimsArray{L}, perm) where {L}
    dnames = NamedDims.permute_dimnames(L, perm)
    return NamedDimsArray{dnames}(permuteddimsview(parent(A), perm))
end

for f in (:map, :map!)
    # Here f::F where {F} is needed to avoid ambiguities in Julia 1.0
    @eval begin
        function Base.$f(f::F, a::NamedDimsArray, b::AxisArray, cs::AbstractArray...) where {F}
            data = Base.$f(f, unname(a), unname(b), unname.(cs)...)
            new_names = unify_names(dimnames(a), dimnames(b), dimnames.(cs)...)
            return NamedDimsArray(data, new_names)
        end

        function Base.$f(f::F, a::AxisArray, b::NamedDimsArray, cs::AbstractArray...) where {F}
            data = Base.$f(f, unname(a), unname(b), unname.(cs)...)
            new_names = unify_names(dimnames(a), dimnames(b), dimnames.(cs)...)
            return NamedDimsArray(data, new_names)
        end
    end
end

function Base.map(f::F, a::StaticArray, b::AxisArray, cs::AbstractArray...) where {F}
    return unsafe_reconstruct(
        b,
        map(f, a, parent(b), parent.(cs)...),
        Broadcast.combine_axes(a, b, cs...,)
    )
end

function Base.map(f::F, a::AxisArray, b::StaticArray, cs::AbstractArray...) where {F}
    return unsafe_reconstruct(
        b,
        map(f, parent(a), b, parent.(cs)...),
        Broadcast.combine_axes(a, b, cs...,)
    )
end

function Base.BroadcastStyle(a::AxisArrayStyle{A}, b::NamedDims.NamedDimsStyle{B}) where {A,B}
    return NamedDims.NamedDimsStyle(a, B())
end
function Base.BroadcastStyle(a::NamedDims.NamedDimsStyle{M}, b::AxisArrayStyle{B}) where {B,M}
    return NamedDims.NamedDimsStyle(M(), b)
end

