
"""
    CenteredAxis(indices; origin=0)

A `CenteredAxis` takes `indices` and provides a user facing set of keys centered around zero.
The `CenteredAxis` is a subtype of `AbstractOffsetAxis` and its keys are treated as the predominant indexing style.
Note that the element type of a `CenteredAxis` cannot be unsigned because any instance with a length greater than 1 will begin at a negative value.

## Examples

A `CenteredAxis` sends all indexing arguments to the keys and only maps to the indices when `to_index` is called.
```jldoctest
julia> using AxisIndices

julia> axis = CenteredAxis(1:10)
CenteredAxis(-5:4 => 1:10)

julia> axis[10]  # the indexing goes straight to keys and is centered around zero
ERROR: BoundsError: attempt to access 10-element CenteredAxis(-5:4 => 1:10) at index [10]
[...]

julia> axis[-4]
-4

julia> AxisIndices.to_index(axis, -5)
1

```
"""
struct CenteredAxis{I,Inds,F} <: AbstractOffsetAxis{I,Inds,F}
    parent::Inds
    offset::F

    function CenteredAxis{I,Inds,F}(inds::AbstractAxis, f::Integer) where {I,Inds,F}
        if inds isa Inds && f isa F
            return new{I,Inds,F}(inds, f)
        else
            return CenteredAxis(convert(Inds, inds); origin=f)
        end
    end

    function CenteredAxis{I,Inds,F}(inds::AbstractUnitRange) where {I,Inds,F}
        return CenteredAxis{I,Inds}(inds; origin=Zero())
    end

    function CenteredAxis{I,Inds}(inds::AbstractUnitRange; origin=Zero()) where {I,Inds}
        return CenteredAxis{I,Inds}(SimpleAxis(inds); origin=origin)
    end

    function CenteredAxis{I,Inds}(inds::AbstractAxis; origin=Zero()) where {I,Inds}
        if inds isa Inds
            start = static_first(inds)
            f = (origin - div(static_length(inds), 2one(start))) - start
            return CenteredAxis{I,Inds, typeof(f)}(inds, f)
        else
            return CenteredAxis{I}(convert(Inds, inds); origin=origin)
        end
    end

    function CenteredAxis{I}(inds::AbstractUnitRange; origin=Zero()) where {I}
        return CenteredAxis{I}(SimpleAxis(inds); origin=origin)
    end

    function CenteredAxis{I}(inds::AbstractAxis; origin=Zero()) where {I}
        if eltype(inds) <: I
            return CenteredAxis{I,typeof(inds)}(inds; origin=origin)
        else
            return CenteredAxis{I}(convert(AbstractUnitRange{I}, inds); origin=origin)
        end
    end

    function CenteredAxis(inds::AbstractOffsetAxis; origin=Zero())
        return CenteredAxis(parent(inds); origin=origin)
    end
    function CenteredAxis(inds::AbstractUnitRange; origin=Zero())
        return CenteredAxis(SimpleAxis(inds); origin=origin)
    end
    function CenteredAxis(inds::AbstractAxis; origin=Zero())
        return CenteredAxis{eltype(inds)}(inds; origin=origin)
    end
end

function ArrayInterface.unsafe_reconstruct(axis::CenteredAxis, inds; kwargs...)
    if inds isa AbstractOffsetAxis
        # drop other offset axes b/c they will all be centered anyway
        return unsafe_reconstruct(axis, parent(inds); kwargs...)
    else
        p = parent(axis)
        len = static_length(axis)
        origin = static_first(p) + offsets(axis, 1) + div(len, 2one(len))
        return CenteredAxis(unsafe_reconstruct(p, inds; kwargs...); origin=origin)
    end
end

"""
    center(inds::AbstractUnitRange{<:Integer}) -> CenteredAxis(inds)

Shortcut for creating [`CenteredAxis`](@ref).

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisArray(ones(3), center)
3-element AxisArray{Float64,1}
 • dim_1 - -1:1

  -1   1.0
   0   1.0
   1   1.0

```
"""
center(inds::AbstractUnitRange) = CenteredAxis(inds)

"""
    CenteredArray(A::AbstractArray)

Provides centered axes for indexing `A`.

## Examples
```jldoctest
julia> using AxisIndices

julia> CenteredArray(ones(3,3))
3×3 AxisArray{Float64,2}
 • dim_1 - -1:1
 • dim_2 - -1:1
        -1     0     1
  -1   1.0   1.0   1.0
   0   1.0   1.0   1.0
   1   1.0   1.0   1.0

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

julia> CenteredVector(ones(3))
3-element AxisArray{Float64,1}
 • dim_1 - -1:1

  -1   1.0
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

julia> CenteredVector{Union{Missing, Int}}(missing, 3)
3-element AxisArray{Union{Missing, Int64},1}
 • dim_1 - -1:1

  -1   missing
   0   missing
   1   missing
```
"""
function CenteredVector{T}(init::ArrayInitializer, arg) where {T}
    return CenteredVector{T}(Vector{T}(init, arg))
end

