
"""
    OffsetAxis(keys::AbstractUnitRange{<:Integer}, indices::AbstractUnitRange{<:Integer}[, check_length::Bool=true])
    OffsetAxis(offset::Integer, indices::AbstractUnitRange{<:Integer})

An axis that has the indexing behavior of an [`AbstractOffsetAxis`](@ref) and retains an
offset from its underlying indices in its keys.

## Examples

Users may construct an `OffsetAxis` by providing an from a set of indices.
```jldoctest offset_axis_examples
julia> using AxisIndices

julia> axis = OffsetAxis(-2, 1:3)
OffsetAxis(-1:1 => 1:3)
```

In this instance the first index of the wrapped indices is 1 (`firstindex(indices(axis))`)
but adding the offset (`-2`) moves it to `-1`.
```jldoctest offset_axis_examples
julia> firstindex(axis)
-1

julia> axis[-1]
-1
```

Similarly, the last index is move by `-2`.
```jldoctest offset_axis_examples
julia> lastindex(axis)
1

julia> axis[1]
1

```

This means that traditional one based indexing no longer applies and may result in
errors.
```jldoctest offset_axis_examples
julia> axis[3]
ERROR: BoundsError: attempt to access 3-element OffsetAxis(-1:1 => 1:3) at index [3]
[...]
```

When an `OffsetAxis` is reconstructed the offset from indices are presserved.
```jldoctest offset_axis_examples
julia> axis[0:1]  # offset of -2 still applies
OffsetAxis(0:1 => 2:3)

```
"""
struct OffsetAxis{I,Inds<:AbstractAxis,F} <: AbstractOffsetAxis{I,Inds,F}
    offset::F
    parent::Inds

    function OffsetAxis{I,Inds,F}(f::Integer, inds::AbstractUnitRange; kwargs...) where {I,Inds,F}
        if inds isa Inds && f isa F
            return new{I,Inds,F}(f, inds)
        else
            return OffsetAxis(f, Inds(inds))
        end
    end

    function OffsetAxis{I,Inds,F}(ks::AbstractUnitRange, inds::AbstractUnitRange; checks=AxisArrayChecks()) where {I,Inds,F}
        check_axis_length(ks, inds, checks)
        return OffsetAxis{I,Inds,F}(static_first(ks) - static_first(inds), inds)
    end

    # OffsetAxis{I,Inds}
    function OffsetAxis{I,Inds}(f::Integer, inds::AbstractUnitRange; kwargs...) where {I,Inds}
        if inds isa Inds
            return OffsetAxis{I,Inds,typeof(f)}(f, inds)
        else
            return OffsetAxis{I,Inds}(f, Inds(inds))
        end
    end

    @inline function OffsetAxis{I,Inds}(ks::AbstractUnitRange, inds::AbstractUnitRange; checks=AxisArrayChecks()) where {I,Inds}
        check_axis_length(ks, inds, checks)
        return OffsetAxis{I,Inds}(static_first(ks) - static_first(inds), inds)
    end

    @inline function OffsetAxis{I,Inds}(ks::AbstractUnitRange; kwargs...) where {I,Inds}
        f = static_first(ks)
        return OffsetAxis{I}(f - one(f), Inds(OneTo(static_length(ks))))
    end

    # OffsetAxis{I}
    function OffsetAxis{I}(f::Integer, inds::AbstractAxis; kwargs...) where {I}
        return OffsetAxis{I,typeof(inds)}(f, inds)
    end
    function OffsetAxis{I}(f::Integer, inds::AbstractRange; kwargs...) where {I}
        return OffsetAxis{I}(f, SimpleAxis(inds))
    end
    @inline function OffsetAxis{I}(ks::AbstractUnitRange, inds::AbstractUnitRange; checks=AxisArrayChecks()) where {I}
        check_axis_length(ks, inds, checks)
        return OffsetAxis{I}(static_first(ks) - static_first(inds), inds)
    end
    @inline function OffsetAxis{I}(ks::AbstractUnitRange; kwargs...) where {I}
        f = static_first(ks)
        return OffsetAxis{I}(f - one(f), SimpleAxis(One():static_length(ks)))
    end
    function OffsetAxis{I}(f::Integer, inds::AbstractOffsetAxis) where {I}
        return OffsetAxis(f + offsets(inds, 1), parent(inds))
    end
 
    # OffsetAxis
    OffsetAxis(f::Integer, inds::AbstractRange; kwargs...) = OffsetAxis{eltype(inds)}(f, inds)
    function OffsetAxis(ks::AbstractUnitRange, inds::AbstractUnitRange; checks=AxisArrayChecks())
        check_axis_length(ks, inds, checks)
        return OffsetAxis(static_first(ks) - static_first(inds), inds)
    end
    function OffsetAxis(ks::Ks; kwargs...) where {Ks}
        fst = static_first(ks)
        return OffsetAxis(fst - one(fst), SimpleAxis(One():static_length(ks)))
    end

    OffsetAxis(axis::OffsetAxis; kwargs...) = axis
end

function ArrayInterface.unsafe_reconstruct(axis::OffsetAxis, inds; kwargs...)
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

"""
    OffsetArray

An array whose axes are all `OffsetAxis`
"""
const OffsetArray{T,N,P,A<:Tuple{Vararg{<:OffsetAxis}}} = AxisArray{T,N,P,A}

"""
    OffsetVector

A vector whose axis is `OffsetAxis`
"""
const OffsetVector{T,P<:AbstractVector{T},Ax1<:OffsetAxis} = OffsetArray{T,1,P,Tuple{Ax1}}

OffsetArray(A::AbstractArray{T,N}, inds::Vararg) where {T,N} = OffsetArray(A, inds)

OffsetArray(A::AbstractArray{T,N}, inds::Tuple) where {T,N} = OffsetArray{T,N}(A, inds)

OffsetArray(A::AbstractArray{T,0}, ::Tuple{}) where {T} = AxisArray(A)
OffsetArray(A::AbstractArray) = OffsetArray(A, axes(A))

# OffsetVector constructors
OffsetVector(A::AbstractVector, arg) = OffsetArray{eltype(A)}(A, arg)

function OffsetVector{T}(init::ArrayInitializer, arg) where {T}
    return OffsetVector(Vector{T}(init, length(arg)), arg)
end
OffsetArray{T}(A, inds::Tuple) where {T} = OffsetArray{T,length(inds)}(A, inds)
OffsetArray{T}(A, inds::Vararg) where {T} = OffsetArray{T,length(inds)}(A, inds)

function OffsetArray{T,N}(init::ArrayInitializer, inds::Tuple=()) where {T,N}
    return OffsetArray{T,N}(Array{T,N}(init, map(length, inds)), inds)
end
OffsetArray{T,N}(A, inds::Vararg) where {T,N} = OffsetArray{T,N}(A, inds)
function OffsetArray{T,N}(A::AbstractArray{T,N}, inds::Tuple) where {T,N}
    return OffsetArray{T,N,typeof(A)}(A, inds)
end
function OffsetArray{T,N}(A::AbstractArray{T2,N}, inds::Tuple) where {T,T2,N}
    return OffsetArray{T,N}(copyto!(Array{T}(undef, size(A)), A), inds)
end
function OffsetArray{T,N}(A::AxisArray, inds::Tuple; kwargs...) where {T,N}
    return OffsetArray{T,N}(parent(A), inds; kwargs...)
end

function OffsetArray{T,N,P}(A::AbstractArray, inds::NTuple{M,Any}) where {T,N,P<:AbstractArray{T,N},M}
    return OffsetArray{T,N,P}(convert(P, A))
end

OffsetArray{T,N,P}(A::OffsetArray{T,N,P}) where {T,N,P} = A

function OffsetArray{T,N,P}(A::OffsetArray) where {T,N,P}
    p = convert(P, parent(A))
    return AxisArray{T,N,P,typeof(axs)}(p, axes(A); checks=NoChecks)
end

function OffsetArray{T,N,P}(A::P, inds::Tuple{Vararg{<:Any,N}}; checks=AxisArrayChecks()) where {T,N,P<:AbstractArray{T,N},M}
    if N === 1
        if can_change_size(P)
            axs = (OffsetAxis(first(inds), SimpleAxis(OneToMRange(axes(A, 1))); checks=checks),)
        else
            axs = (OffsetAxis(first(inds), axes(A, 1)),)
        end
    else
        axs = map((f, axis) -> OffsetAxis(f, axis; checks=checks), inds, axes(A))
    end
    return AxisArray{T,N,typeof(A),typeof(axs)}(A, axs; checks=NoChecks)
end

