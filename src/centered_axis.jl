
"""
    CenteredAxis(origin=0, indices)

A `CenteredAxis` takes `indices` and provides a user facing set of keys centered around zero.
The `CenteredAxis` is a subtype of `AbstractOffsetAxis` and its keys are treated as the predominant indexing style.
Note that the element type of a `CenteredAxis` cannot be unsigned because any instance with a length greater than 1 will begin at a negative value.

## Examples

A `CenteredAxis` sends all indexing arguments to the keys and only maps to the indices when `to_index` is called.
```jldoctest
julia> using AxisIndices

julia> axis = AxisIndices.CenteredAxis(1:10)
center(SimpleAxis(1:10)); origin=0)

julia> axis[10]  # the indexing goes straight to keys and is centered around zero
ERROR: BoundsError: attempt to access center(SimpleAxis(1:10)); origin=0) at index [10]
[...]

julia> axis[-4]
-4

```
"""
struct CenteredAxis{I,Inds,F} <: AbstractOffsetAxis{I,Inds,F}
    origin::F
    parent::Inds

    function CenteredAxis{I,Inds,F}(origin::Integer, inds::AbstractAxis) where {I,Inds,F}
        if inds isa Inds && origin isa F
            return new{I,Inds,F}(origin, inds)
        else
            return CenteredAxis(origin, convert(Inds, inds))
        end
    end
    function CenteredAxis{I,Inds,F}(inds::AbstractRange) where {I,Inds,F<:StaticInt}
        return new{I,Inds,F}(F(), inds)
    end
    function CenteredAxis{I,Inds,F}(inds::AbstractRange) where {I,Inds,F}
        return new{I,Inds,F}(F(0), inds)
    end

    function CenteredAxis{I,Inds,F}(origin::Integer, inds::AbstractRange) where {I,Inds,F}
        return CenteredAxis{I,Inds}(origin, inds)
    end

    function CenteredAxis{I,Inds}(inds::AbstractRange) where {I,Inds}
        return CenteredAxis{I,Inds}(Zero(), inds)
    end
    function CenteredAxis{I,Inds}(origin::Integer, inds::AbstractArray) where {I,Inds}
        return CenteredAxis{I,Inds}(origin, compose_axis(inds))
    end
    function CenteredAxis{I,Inds}(origin::Integer, inds::AbstractAxis) where {I,Inds}
        if inds isa Inds
            return CenteredAxis{I,Inds,typeof(origin)}(origin, inds)
        else
            return CenteredAxis{I}(origin, convert(Inds, inds))
        end
    end

    function CenteredAxis{I}(origin::Integer, inds::AbstractArray) where {I}
        return CenteredAxis{I}(origin, compose_axis(inds))
    end
    function CenteredAxis{I}(origin::Integer, inds::AbstractOffsetAxis) where {I}
        return CenteredAxis{I}(origin, parent(inds))
    end
    function CenteredAxis{I}(origin::Integer, inds::AbstractAxis) where {I}
        if eltype(inds) <: I
            return CenteredAxis{I,typeof(inds)}(origin, inds)
        else
            return CenteredAxis{I}(origin, convert(AbstractUnitRange{I}, inds))
        end
    end
    CenteredAxis{I}(inds::AbstractRange) where {I} = CenteredAxis{I}(Zero(), inds)

    CenteredAxis(inds::AbstractRange) = CenteredAxis(Zero(), inds)
    function CenteredAxis(origin::Integer, inds::AbstractOffsetAxis)
        return CenteredAxis(origin, parent(inds))
    end
    function CenteredAxis(origin::Integer, inds::AbstractArray)
        return CenteredAxis(origin, compose_axis(inds))
    end
    function CenteredAxis(origin::Integer, inds::AbstractAxis)
        return CenteredAxis{eltype(inds)}(origin, inds)
    end
end

@inline Base.getproperty(axis::CenteredAxis, k::Symbol) = getproperty(parent(axis), k)

function ArrayInterface.unsafe_reconstruct(axis::CenteredAxis, inds; kwargs...)
    return CenteredAxis(origin(axis), unsafe_reconstruct(parent(axis), inds; kwargs...))
end

ArrayInterface.known_first(::Type{T}) where {T<:CenteredAxis{<:Any,<:Any,<:Any}} = nothing
function ArrayInterface.known_first(::Type{T}) where {Inds,F,T<:CenteredAxis{<:Any,Inds,StaticInt{F}}}
    if known_length(Inds) === nothing
        return nothing
    else
        return F - div(known_length(Inds), 2)
    end
end
Base.first(axis::CenteredAxis) = origin(axis) - div(length(parent(axis)), 2)

ArrayInterface.known_last(::Type{T}) where {T<:CenteredAxis{<:Any,<:Any,<:Any}} = nothing
function ArrayInterface.known_last(::Type{T}) where {Inds,F,T<:CenteredAxis{<:Any,Inds,StaticInt{F}}}
    if known_length(Inds) === nothing
        return nothing
    else
        return F - div(known_length(Inds), 2) + known_length(Inds)
    end
end
Base.last(axis::CenteredAxis) = last(parent(axis)) + _origin_to_offset(axis)

function _origin_to_offset(axis::CenteredAxis)
    p = parent(axis)
    return _origin_to_offset(first(p), length(p), origin(axis))
end
_origin_to_offset(start, len, origin) = (origin - div(len, 2one(start))) - start

origin(axis::CenteredAxis) = getfield(axis, :origin)
@inline function ArrayInterface.offsets(axis::CenteredAxis)
    inds = parent(axis)
    return (_origin_to_offset(static_first(inds), static_length(inds), origin(axis)),)
end


"""
    center(collection, origin=0)

Shortcut for creating [`CenteredAxis`](@ref).

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisArray(ones(3), center(0))
3-element AxisArray(::Array{Float64,1}
  • axes:
     1 = -1:1
)
      1
  -1  1.0
  0   1.0
  1   1.0

```
"""
struct Center <: AxisInitializer end
const center = Center()
axis_method(::Center, x, inds) = CenteredAxis(x, inds)
center(collection::AbstractArray) = center(collection, Zero())

"""
    CenteredArray(A::AbstractArray)

Provides centered axes for indexing `A`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.CenteredArray(ones(3,3))
3×3 AxisArray(::Array{Float64,2}
  • axes:
     1 = -1:1
     2 = -1:1
)
      -1    0    1
  -1   1.0  1.0  1.0
  0    1.0  1.0  1.0
  1    1.0  1.0  1.0

```
"""
const CenteredArray{T,N,P,A<:Tuple{Vararg{<:CenteredAxis}}} = AxisArray{T,N,P,A}

CenteredArray(A::AbstractArray{T,N}) where {T,N} = CenteredArray{T,N}(A)

CenteredArray(A::AbstractArray{T,0}) where {T} = AxisArray(A)


CenteredArray{T}(A::AbstractArray) where {T} = CenteredArray{T,ndims(A)}(A)

CenteredArray{T,N}(A::AbstractArray) where {T,N} = CenteredArray{T,N,typeof(A)}(A)

CenteredArray{T,N,P}(A::CenteredArray{T,N,P}) where {T,N,P} = A
function CenteredArray{T,N,P}(A::CenteredArray) where {T,N,P}
    return CenteredArray{T,N,P}(parent(A))
end


function CenteredArray{T,N,P}(A::AbstractArray) where {T,N,P<:AbstractArray{T,N}}
    return CenteredArray{T,N,P}(convert(P, A))
end

function CenteredArray{T,N,P}(A::P) where {T,N,P<:AbstractArray{T,N}}
    axs = map(center, axes(A))
    return CenteredArray{T,N,P,typeof(axs)}(A, axs)
end

function CenteredArray{T}(init::ArrayInitializer, sz::Tuple=()) where {T}
    return CenteredArray{T,length(inds)}(init, sz)
end

function CenteredArray{T,N}(init::ArrayInitializer, sz::Tuple=()) where {T,N}
    return CenteredArray{T,N}(Array{T,N}(init, sz))
end

"""
    CenteredVector(v::AbstractVector)

Provides a centered axis for indexing `v`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.CenteredVector(ones(3))
3-element AxisArray(::Array{Float64,1}
  • axes:
     1 = -1:1
)
      1
  -1  1.0
  0   1.0
  1   1.0

```
"""
const CenteredVector{T,P<:AbstractVector{T},Ax1<:CenteredAxis} = CenteredArray{T,1,P,Tuple{Ax1}}

CenteredVector(A::AbstractVector) = CenteredArray{eltype(A)}(A)
CenteredVector{T}(A::AbstractVector) where {T} = CenteredArray{T,1}(A)

"""
    CenteredVector{T}(init::ArrayInitializer, sz::Integer)

Creates a vector with elements of type `T` of size `sz` and a centered axis.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.CenteredVector{Union{Missing, Int}}(missing, 3)
3-element AxisArray(::Array{Union{Missing, Int64},1}
  • axes:
     1 = -1:1
)
      1
  -1   missing
  0    missing
  1    missing

```
"""
function CenteredVector{T}(init::ArrayInitializer, arg) where {T}
    return CenteredVector{T}(Vector{T}(init, arg))
end

function print_axis(io::IO, axis::CenteredAxis)
    print(io, "center($(parent(axis))); origin=$(Int(origin(axis))))")
end
