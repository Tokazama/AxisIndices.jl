
# OffsetAxis
OffsetAxis(f::Integer, inds::AbstractArray) = OffsetAxis(f, compose_axis(inds))
OffsetAxis(o::Integer, x::AbstractAxis) = _offset_axis(has_offset(x), o, x)
function _offset_axis(::True, o, x)
    o2, p = drop_offset(x)
    return _OffsetAxis(int(o + o2 - static(1)), p)
end
_offset_axis(::False, o, x) = _OffsetAxis(int(o), x)

function OffsetAxis(ks::AbstractUnitRange{T}, x::AbstractAxis) where {T}
    check_axis_length(ks, x)
    return OffsetAxis(static_first(ks) - static_first(x), x)
end
function OffsetAxis(ks::AbstractUnitRange{T}, inds::AbstractArray) where {T}
    return OffsetAxis(ks, compose_axis(inds))
end
function OffsetAxis(ks::Ks) where {Ks}
    fst = static_first(ks)
    if can_change_size(ks)
        return OffsetAxis(fst - one(fst), SimpleAxis(DynamicAxis(length(ks))))
    else
        return OffsetAxis(fst - one(fst), SimpleAxis(One():static_length(ks)))
    end
end

OffsetAxis(axis::OffsetAxis) = axis

@inline Base.getproperty(axis::OffsetAxis, k::Symbol) = getproperty(parent(axis), k)

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
        return _OffsetAxis(getfield(axis, :offset), unsafe_reconstruct(parent(axis), inds))
    end
end

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
            axs = (OffsetAxis(first(inds), SimpleAxis(DynamicAxis(axes(A, 1)))),)
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

