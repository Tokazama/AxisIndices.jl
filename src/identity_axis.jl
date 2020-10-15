
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
struct IdentityAxis{I,Inds<:AbstractAxis,F} <: AbstractOffsetAxis{I,Inds,F}
    offset::F
    parent::Inds

    @inline function IdentityAxis{I,Inds,F}(f::Integer, inds::AbstractUnitRange) where {I,Inds,F}
        if inds isa Inds && f isa F
            return new{I,Inds,F}(f, inds)
        else
            return IdentityAxis(f, Inds(inds))
        end
    end

    function IdentityAxis{I,Inds}(f::Integer, inds::AbstractAxis) where {I,Inds}
        return IdentityAxis{I,Inds,typeof(f)}(f, inds)
    end
    function IdentityAxis{I,Inds}(f::Integer, inds::AbstractUnitRange) where {I,Inds}
        return IdentityAxis{I,Inds}(f, SimpleAxis(inds))
    end
    function IdentityAxis{I,Inds}(f::AbstractUnitRange, inds::AbstractUnitRange) where {I,Inds}
        return IdentityAxis{I,Inds}(static_first(ks) - static_first(inds), inds)
    end
    function IdentityAxis{I,Inds}(ks::AbstractUnitRange) where {I,Inds}
        if can_change_size(ks)
            inds = OneToMRange(length(ks))
        else
            inds = OneTo(static_length(ks))
        end
        f = static_first(ks) - one(F)
        return IdentityAxis{eltype(inds),typeof(f),typeof(inds)}(f, inds)
    end

    # IdentityAxis{I}
    function IdentityAxis{I}(f::Integer, inds::AbstractOffsetAxis) where {I}
        return IdentityAxis(f + offsets(inds, 1), parent(inds))
    end
    function IdentityAxis{I}(f::Integer, inds::AbstractRange) where {I}
        return IdentityAxis{I}(f, SimpleAxis(inds))
    end
    function IdentityAxis{I}(f::Integer, inds::AbstractAxis) where {I}
        return IdentityAxis{I,typeof(inds)}(f, inds)
    end
    function IdentityAxis{I}(ks::AbstractRange{<:Integer}) where {I}
        return IdentityAxis{I}(ks, OneTo{I}(length(ks)))
    end
    function IdentityAxis{I}(start::Integer, stop::Integer) where {I}
        return IdentityAxis{I}(UnitRange{I}(start, stop))
    end
    function IdentityAxis{I}(ks::AbstractRange, inds::AbstractRange) where {I}
        return IdentityAxis{I}(static_first(ks) - static_first(inds), inds)
    end

    # IdentityAxis
    function IdentityAxis(f::Integer, inds::AbstractRange)
        return IdentityAxis{eltype(inds)}(f, inds)
    end
    function IdentityAxis(ks::AbstractUnitRange, inds::AbstractRange)
        return IdentityAxis(static_first(ks) - static_first(inds), inds)
    end
    IdentityAxis(start::Integer, stop::Integer) = IdentityAxis(start:stop)
    function IdentityAxis(ks::Ks) where {Ks}
        if can_change_size(ks)
            inds = SimpleAxis(OneToMRange(length(ks)))
        else
            inds = SimpleAxis(StaticInt(1):static_length(ks))
        end
        f = static_first(ks)
        f = f - one(f)
        return new{eltype(inds),typeof(inds),typeof(f)}(f, inds)
    end
end

function ArrayInterface.unsafe_reconstruct(axis::IdentityAxis, inds; keys=nothing, kwargs...)
    if keys === nothing
        if inds isa AbstractOffsetAxis
            f_axis = offsets(axis, 1)
            f_inds = offsets(inds, 1)
            if f_axis === f_inds
                return OffsetAxis(offsets(axis, 1), unsafe_reconstruct(parent(axis), parent(inds); kwargs...))
            else
                return OffsetAxis(f_axis + f_inds, unsafe_reconstruct(parent(axis), parent(inds); kwargs...))
            end
        else
            return OffsetAxis(offsets(axis, 1), unsafe_reconstruct(parent(axis), inds; kwargs...))
        end
    else
        return IdentityAxis(static_first(keys) - static_first(inds), inds)
    end
end

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

"""
    IdentityArray(A::AbstractArray)

Provides [`IdentityAxis`](@ref)s for indexing `A`.

## Examples
```jldoctest
julia> using AxisIndices

julia> IdentityArray(ones(3,3))[2:3, 2:3]
2×2 AxisArray{Float64,2}
 • dim_1 - 2:3
 • dim_2 - 2:3
        2     3
  2   1.0   1.0
  3   1.0   1.0

```
"""
const IdentityArray{T,N,P,A<:Tuple{Vararg{<:IdentityAxis}}} = AxisArray{T,N,P,A}


IdentityArray(A::AbstractArray{T,N}) where {T,N} = IdentityArray{T,N}(A)

IdentityArray(A::AbstractArray{T,0}) where {T} = AxisArray(A)


IdentityArray{T}(A::AbstractArray) where {T} = IdentityArray{T,ndims(A)}(A)

IdentityArray{T,N}(A::AbstractArray) where {T,N} = IdentityArray{T,N,typeof(A)}(A)

IdentityArray{T,N,P}(A::IdentityArray{T,N,P}) where {T,N,P} = A
function IdentityArray{T,N,P}(A::IdentityArray) where {T,N,P}
    return IdentityArray{T,N,P}(parent(A))
end

function IdentityArray{T,N,P}(A::AbstractArray) where {T,N,P<:AbstractArray{T,N}}
    return IdentityArray{T,N,P}(convert(P, A))
end

function IdentityArray{T,N,P}(A::P) where {T,N,P<:AbstractArray{T,N}}
    axs = map(idaxis, axes(A))
    return IdentityArray{T,N,P,typeof(axs)}(A, axs)
end

function IdentityArray{T}(init::ArrayInitializer, sz::Tuple=()) where {T}
    return IdentityArray{T,length(inds)}(init, sz)
end

function IdentityArray{T,N}(init::ArrayInitializer, sz::Tuple=()) where {T,N}
    return IdentityArray{T,N}(Array{T,N}(init, sz))
end

"""
    IdentityVector(v::AbstractVector)

Provides an [`IdentityAxis`](@ref) for indexing `v`.

## Examples
```jldoctest
julia> using AxisIndices

julia> IdentityVector(ones(4))[3:4]
2-element AxisArray{Float64,1}
 • dim_1 - 3:4

  3   1.0
  4   1.0

```
"""
const IdentityVector{T,P<:AbstractVector{T},Ax1<:IdentityAxis} = IdentityArray{T,1,P,Tuple{Ax1}}

IdentityVector(A::AbstractVector) = IdentityArray{eltype(A)}(A)
IdentityVector{T}(A::AbstractVector) where {T} = IdentityArray{T,1}(A)


"""
    IdentityVector{T}(init::ArrayInitializer, sz::Integer)

Creates a vector with elements of type `T` of size `sz` an [`IdentityAxis`](@ref).

## Examples
```jldoctest
julia> using AxisIndices

julia> IdentityVector{Union{Missing, Int}}(missing, 3)[2:3]
2-element AxisArray{Union{Missing, Int64},1}
 • dim_1 - 2:3

  2   missing
  3   missing

```
"""
function IdentityVector{T}(init::ArrayInitializer, arg) where {T}
    return IdentityVector{T}(Vector{T}(init, arg))
end


