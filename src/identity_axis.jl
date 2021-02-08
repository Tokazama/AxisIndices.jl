
"""
    IdentityAxis(start, stop) -> axis
    IdentityAxis(keys::AbstractUnitRange) -> axis
    IdentityAxis(keys::AbstractUnitRange, indices::AbstractUnitRange) -> axis

`AbstractAxis` subtype that preserves indices after indexing.

# Examples
```julia
julia> using AxisIndices

julia> axis = AxisIndices.IdentityAxis(3:5)
idaxis(3:5)(SimpleAxis(1:3))

julia> axis[4:5]
idaxis(4:5)(SimpleAxis(2:3))

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
    function IdentityAxis{I,Inds}(f::Integer, inds::AbstractArray) where {I,Inds}
        return IdentityAxis{I,Inds}(f, compose_axis(inds))
    end
    function IdentityAxis{I,Inds}(f::AbstractUnitRange, inds::AbstractAxis) where {I,Inds}
        return IdentityAxis{I,Inds}(static_first(ks) - static_first(inds), inds)
    end
 
    function IdentityAxis{I,Inds}(f::AbstractUnitRange, inds::AbstractArray) where {I,Inds}
        return IdentityAxis{I,Inds}(f, compose_axis(inds))
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
    function IdentityAxis{I}(f::Integer, inds::AbstractArray) where {I}
        return IdentityAxis{I}(f, compose_axis(inds))
    end
    function IdentityAxis{I}(f::Integer, inds::AbstractAxis) where {I}
        return IdentityAxis{I,typeof(inds)}(f, inds)
    end
    function IdentityAxis{I}(ks::AbstractRange{<:Integer}) where {I}
        return IdentityAxis{I}(ks, OneTo{I}(length(ks)))
    end
    function IdentityAxis{I}(start::Integer, stop::Integer) where {I}
        return IdentityAxis{I}(start:stop)
    end
    function IdentityAxis{I}(ks::AbstractRange, inds::AbstractAxis) where {I}
        return IdentityAxis{I}(static_first(ks) - static_first(inds), inds)
    end
    function IdentityAxis{I}(ks::AbstractRange, inds::AbstractOffsetAxis) where {I}
        return IdentityAxis{I}(ks, parent(inds))
    end
    function IdentityAxis{I}(ks::AbstractRange, inds::AbstractArray) where {I}
        return IdentityAxis{I}(ks, compose_axis(inds))
    end

    # IdentityAxis
    function IdentityAxis(f::Integer, inds::AbstractAxis)
        return IdentityAxis{eltype(inds)}(f, inds)
    end
    function IdentityAxis(ks::AbstractRange, inds::AbstractAxis)
        return IdentityAxis{eltype(inds)}(ks, compose_axis(inds))
    end
    function IdentityAxis(ks::AbstractRange, inds::AbstractArray)
        return IdentityAxis(ks, compose_axis(inds))
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

@inline Base.getproperty(axis::IdentityAxis, k::Symbol) = getproperty(parent(axis), k)

ArrayInterface.known_first(::Type{T}) where {T<:IdentityAxis{<:Any,<:Any,<:Any}} = nothing
function ArrayInterface.known_first(::Type{T}) where {Inds,F,T<:IdentityAxis{<:Any,Inds,StaticInt{F}}}
    if known_first(Inds) === nothing
        return nothing
    else
        return known_first(Inds) + F
    end
end
Base.first(axis::IdentityAxis) = first(parent(axis)) + getfield(axis, :offset)

ArrayInterface.known_last(::Type{T}) where {T<:IdentityAxis{<:Any,<:Any,<:Any}} = nothing
function ArrayInterface.known_last(::Type{T}) where {Inds,F,T<:IdentityAxis{<:Any,Inds,StaticInt{F}}}
    if known_last(Inds) === nothing
        return nothing
    else
        return known_last(Inds) + F
    end
end
Base.last(axis::IdentityAxis) = last(parent(axis)) + getfield(axis, :offset)

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
        return IdentityAxis(keys, inds)
    end
end

"""
    idaxis(inds::AbstractUnitRange{<:Integer})

Shortcut for creating [`IdentityAxis`](@ref).

# Examples

```jldoctest
julia> using AxisIndices

julia> AxisArray(ones(3), idaxis)[2:3]
2-element AxisArray(::Vector{Float64}
  • axes:
     1 = 2:3
)
     1
  2  1.0
  3  1.0

```
"""
struct IdAxis <: AxisInitializer end
axis_method(::IdAxis, x, inds) = IdentityAxis(x, inds)
const idaxis = IdAxis()
function idaxis(collection)
    if known_step(collection) === 1
        return IdentityAxis(collection)
    else
        return idaxis(collection, axes(collection))
    end
end

"""
    IdentityArray(A::AbstractArray)

Provides [`IdentityAxis`](@ref)s for indexing `A`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.IdentityArray(ones(3,3))[2:3, 2:3]
2×2 AxisArray(::Matrix{Float64}
  • axes:
     1 = 2:3
     2 = 2:3
)
     2    3
  2  1.0  1.0
  3  1.0  1.0

```
"""
const IdentityArray{T,N,P,A<:Tuple{Vararg{<:IdentityAxis}}} = AxisArray{T,N,P,A}


IdentityArray(A::AbstractArray{T,N}) where {T,N} = IdentityArray{T,N}(A)

IdentityArray(A::AbstractArray{T,0}) where {T} = AxisArray(A)

IdentityArray{T}(A::AbstractArray) where {T} = IdentityArray{T,ndims(A)}(A)

IdentityArray{T,N}(A::AbstractArray) where {T,N} = IdentityArray{T,N,typeof(A)}(A)

function IdentityArray{T,N,P}(x::P; checks=AxisArrayChecks(), kwargs...) where {T,N,P<:AbstractArray{T,N}}
    axs = map(IdentityAxis, axes(x))
    return AxisArray{T,N,P,typeof(axs)}(x, axs; checks=NoChecks)
end
function AxisArray{T,N,P}(x::P, axs::Tuple; kwargs...) where {T,N,P}
    axs = map(IdentityAxis, axs)
    return AxisArray{T,N,P}(convert(P, x), axs; kwargs...)
end

IdentityArray{T,N,P}(A::IdentityArray{T,N,P}) where {T,N,P} = A

"""
    IdentityVector(v::AbstractVector)

Provides an [`IdentityAxis`](@ref) for indexing `v`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.IdentityVector(ones(4))[3:4]
2-element AxisArray(::Vector{Float64}
  • axes:
     1 = 3:4
)
     1
  3  1.0
  4  1.0

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

julia> AxisIndices.IdentityVector{Union{Missing, Int}}(missing, 3)[2:3]
2-element AxisArray(::Vector{Union{Missing, Int64}}
  • axes:
     1 = 2:3
)
     1
  2   missing
  3   missing


```
"""
function IdentityVector{T}(init::ArrayInitializer, arg) where {T}
    return IdentityVector{T}(Vector{T}(init, arg))
end

@inline function ArrayInterface.to_axis(::IndexStyle, axis::IdentityAxis, inds)
    return unsafe_reconstruct(axis, StaticInt(1):static_length(inds); keys=inds)
end

function print_axis(io::IO, axis::IdentityAxis)
    print(io, "idaxis(")
    print(io, Int(first(axis)))
    print(io, ")(")
    print(io, Int(last(axis)))
    print(io, " parent=$(parent(axis)))")
end

