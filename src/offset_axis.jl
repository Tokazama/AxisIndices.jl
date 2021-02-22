
"""
    OffsetAxis(keys::AbstractUnitRange{<:Integer}, parent::AbstractUnitRange{<:Integer})
    OffsetAxis(offset::Integer, parent::AbstractUnitRange{<:Integer})

An axis that has the indexing behavior of an [`AbstractOffsetAxis`](@ref) and retains an
offset from its underlying indices in its keys. Note that `offset` is only the offset from
the parent indices. If `OffsetAxis` is part of an `AxisArray`, the number returned by
`ArrayInterface.offsets` refers to the offset from zero, not the offset found in this axis.

## Examples

Users may construct an `OffsetAxis` by providing an from a set of indices.
```jldoctest offset_axis_examples
julia> using AxisIndices

julia> axis = AxisIndices.OffsetAxis(-2, 1:3)
offset(-2)(SimpleAxis(1:3))

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
ERROR: BoundsError: attempt to access offset(-2)(SimpleAxis(1:3)) at index [3]
[...]
```

When an `OffsetAxis` is reconstructed the offset from indices are presserved.
```jldoctest offset_axis_examples
julia> axis[0:1]  # offset of -2 still applies
offset(-2)(SimpleAxis(2:3))

```
"""
struct OffsetAxis{I,Inds<:AbstractAxis,F} <: AbstractOffsetAxis{I,Inds,F}
    offset::F
    parent::Inds

    function OffsetAxis{I,Inds,F}(f::Integer, inds::AbstractUnitRange) where {I,Inds,F}
        if inds isa Inds && f isa F
            return new{I,Inds,F}(f, inds)
        else
            return OffsetAxis(f, Inds(inds))
        end
    end

    function OffsetAxis{I,Inds,F}(ks::AbstractUnitRange, inds::AbstractUnitRange) where {I,Inds,F}
        check_axis_length(ks, inds)
        return OffsetAxis{I,Inds,F}(static_first(ks) - static_first(inds), inds)
    end

    # OffsetAxis{I,Inds}
    function OffsetAxis{I,Inds}(f::Integer, inds::AbstractUnitRange) where {I,Inds}
        if inds isa Inds
            return OffsetAxis{I,Inds,typeof(f)}(f, inds)
        else
            return OffsetAxis{I,Inds}(f, Inds(inds))
        end
    end
    @inline function OffsetAxis{I,Inds}(ks::AbstractUnitRange, inds::AbstractUnitRange) where {I,Inds}
        check_axis_length(ks, inds)
        return OffsetAxis{I,Inds}(static_first(ks) - static_first(inds), inds)
    end
    @inline function OffsetAxis{I,Inds}(ks::AbstractUnitRange) where {I,Inds}
        f = static_first(ks)
        return OffsetAxis{I}(f - one(f), Inds(OneTo(static_length(ks))))
    end

    # OffsetAxis{I}
    function OffsetAxis{I}(f::Integer, inds::AbstractAxis) where {I}
        return OffsetAxis{I,typeof(inds)}(f, inds)
    end
    function OffsetAxis{I}(f::Integer, inds::AbstractArray) where {I}
        return OffsetAxis{I}(f, compose_axis(inds))
    end
    function OffsetAxis{I}(f::AbstractUnitRange, inds::AbstractArray) where {I}
        return OffsetAxis{I}(f, compose_axis(inds))
    end 
    function OffsetAxis{I}(ks::AbstractUnitRange, inds::AbstractAxis) where {I}
        check_axis_length(ks, inds)
        return OffsetAxis{I}(static_first(ks) - static_first(inds), inds)
    end
    function OffsetAxis{I}(ks::AbstractUnitRange) where {I}
        f = static_first(ks)
        return OffsetAxis{I}(f - one(f), SimpleAxis(One():static_length(ks)))
    end
    function OffsetAxis{I}(ks::AbstractUnitRange, inds::AbstractOffsetAxis) where {I}
        check_axis_length(ks, inds)
        p = parent(inds)
        return OffsetAxis{I}(static_first(ks) + static_first(inds) - static_first(p), p)
    end
    function OffsetAxis{I}(f::Integer, inds::AbstractOffsetAxis) where {I}
        p = parent(inds)
        return OffsetAxis{I}(f + static_first(inds) - static_first(p), parent(inds))
    end
 
    # OffsetAxis
    OffsetAxis(f::Integer, inds::AbstractAxis) = OffsetAxis{eltype(inds)}(f, inds)
    OffsetAxis(f::AbstractUnitRange, inds::AbstractAxis) = OffsetAxis{eltype(inds)}(f, inds)
    OffsetAxis(f::Integer, inds::AbstractArray) = OffsetAxis(f, compose_axis(inds))
    OffsetAxis(ks::AbstractUnitRange, inds::AbstractArray) = OffsetAxis(ks, compose_axis(inds))
    function OffsetAxis(ks::Ks) where {Ks}
        fst = static_first(ks)
        if can_change_size(ks)
            return OffsetAxis(fst - one(fst), SimpleAxis(OneToMRange(length(ks))))
        else
            return OffsetAxis(fst - one(fst), SimpleAxis(One():static_length(ks)))
        end
    end

    OffsetAxis(axis::OffsetAxis) = axis
end

@inline Base.getproperty(axis::OffsetAxis, k::Symbol) = getproperty(parent(axis), k)

ArrayInterface.known_first(::Type{T}) where {T<:OffsetAxis{<:Any,<:Any,<:Any}} = nothing
function ArrayInterface.known_first(::Type{T}) where {Inds,F,T<:OffsetAxis{<:Any,Inds,StaticInt{F}}}
    if known_first(Inds) === nothing
        return nothing
    else
        return known_first(Inds) + F
    end
end
Base.first(axis::OffsetAxis) = first(parent(axis)) + getfield(axis, :offset)

ArrayInterface.known_last(::Type{T}) where {T<:OffsetAxis{<:Any,<:Any,<:Any}} = nothing
function ArrayInterface.known_last(::Type{T}) where {Inds,F,T<:OffsetAxis{<:Any,Inds,StaticInt{F}}}
    if known_last(Inds) === nothing
        return nothing
    else
        return known_last(Inds) + F
    end
end
Base.last(axis::OffsetAxis) = last(parent(axis)) + getfield(axis, :offset)

function ArrayInterface.unsafe_reconstruct(axis::OffsetAxis, inds)
    if inds isa AbstractOffsetAxis
        f_axis = offsets(axis, 1)
        f_inds = offsets(inds, 1)
        if f_axis === f_inds
            return OffsetAxis(offsets(axis, 1), unsafe_reconstruct(parent(axis), parent(inds)))
        else
            return OffsetAxis(f_axis + f_inds, unsafe_reconstruct(parent(axis), parent(inds)))
        end
    else
        return OffsetAxis(getfield(axis, :offset), unsafe_reconstruct(parent(axis), inds))
    end
end

"""
    offset([collection,] x)


## Examples
```jldoctest
julia> using AxisIndices

julia> AxisArray(ones(3), offset(2))
3-element AxisArray(::Vector{Float64}
  • axes:
     1 = 3:5
)
     1
  3  1.0
  4  1.0
  5  1.0

```
"""
struct Offset <: AxisInitializer end
axis_method(::Offset, x, inds) = OffsetAxis(x, inds)

const offset = Offset()

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
function OffsetArray{T,N}(A::AxisArray, inds::Tuple) where {T,N}
    return OffsetArray{T,N}(parent(A), inds)
end

function OffsetArray{T,N,P}(A::AbstractArray, inds::NTuple{M,Any}) where {T,N,P<:AbstractArray{T,N},M}
    return OffsetArray{T,N,P}(convert(P, A))
end

OffsetArray{T,N,P}(A::OffsetArray{T,N,P}) where {T,N,P} = A

function OffsetArray{T,N,P}(A::OffsetArray) where {T,N,P}
    return initialize_axis_array(convert(P, parent(A)), axes(A))
end

function OffsetArray{T,N,P}(A::P, inds::Tuple{Vararg{<:Any,N}}) where {T,N,P<:AbstractArray{T,N}}
    if N === 1
        if can_change_size(P)
            axs = (OffsetAxis(first(inds), SimpleAxis(OneToMRange(axes(A, 1)))),)
        else
            axs = (OffsetAxis(first(inds), axes(A, 1)),)
        end
    else
        axs = map((f, axis) -> OffsetAxis(f, axis), inds, axes(A))
    end
    return initialize_axis_array(A, axs)
end

function print_axis(io::IO, axis::OffsetAxis)
    print(io, "offset($(Int(getfield(axis, :offset))))($(parent(axis)))")
end

