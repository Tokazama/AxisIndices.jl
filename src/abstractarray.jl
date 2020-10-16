
function Base.push!(A::AxisVector, item)
    StaticRanges.can_set_last(axes(A, 1)) || throw(MethodError(push!, (A, item)))
    push!(parent(A), item)
    grow_last!(axes(A, 1), 1)
    return A
end

function Base.push!(A::AxisVector, item::Pair)
    axis = axes(A, 1)
    StaticRanges.can_set_last(axis) || throw(MethodError(push!, (A, item)))
    push!(parent(A), last(item))
    push_key!(axis, first(item))
    return A
end

function Base.pushfirst!(A::AxisVector, item)
    can_change_size(A) || throw(MethodError(pushfirst!, (A, item)))
    pushfirst_axis!(axes(A, 1))
    pushfirst!(parent(A), item)
    return A
end

function pushfirst_axis!(axis::Axis, key)
    pushfirst!(keys(axis), key)
    grow_last!(parent(axis), 1)
    return nothing
end

function pushfirst_axis!(axis::AbstractAxis)
    grow_last!(parent(axis), 1)
    return nothing
end

function pushfirst_axis!(axis::Axis)
    grow_first!(keys(axis), 1)
    grow_last!(parent(axis), 1)
    return nothing
end

function Base.pushfirst!(A::AxisVector, item::Pair)
    can_change_size(A) || throw(MethodError(pushfirst!, (A, item)))
    axis = axes(A, 1)
    pushfirst_axis!(axis, first(item))
    pushfirst!(parent(A), last(item))
    return A
end

function Base.mapslices(f, a::AxisArray; dims, kwargs...)
    return reconstruct_reduction(a, Base.mapslices(f, parent(a); dims=dims, kwargs...), dims)
end

Base.:(==)(a::AxisArray, b::AxisArray) = ==(parent(a), parent(b))
Base.:(==)(a::AxisArray, b::AbstractArray) = ==(parent(a), b)
Base.:(==)(a::AbstractArray, b::AxisArray) = ==(a, parent(b))
Base.:(==)(a::AxisArray, b::AbstractAxis) = ==(parent(a), b)
Base.:(==)(a::AbstractAxis, b::AxisArray) = ==(a, parent(b))
Base.:(==)(a::AxisArray, b::GapRange) = ==(parent(a), b)
Base.:(==)(a::GapRange, b::AxisArray) = ==(a, parent(b))

Base.:isequal(a::AxisArray, b::AxisArray) = isequal(parent(a), parent(b))
Base.:isequal(a::AxisArray, b::AbstractArray) = isequal(parent(a), b)
Base.:isequal(a::AbstractArray, b::AxisArray) = isequal(a, parent(b))
Base.:isequal(a::AxisArray, b::AbstractAxis) = isequal(parent(a), b)
Base.:isequal(a::AbstractAxis, b::AxisArray) = isequal(a, parent(b))

Base.isapprox(a::AxisArray, b::AxisArray; kw...) = isapprox(parent(a), parent(b); kw...)
Base.isapprox(a::AxisArray, b::AbstractArray; kw...) = isapprox(parent(a), b; kw...)
Base.isapprox(a::AbstractArray, b::AxisArray; kw...) = isapprox(a, parent(b); kw...)

Base.copy(A::AxisArray) = AxisArray(copy(parent(A)), map(copy, axes(A)))

function Base.similar(A::AxisArray, ::Type{T}, dims::Tuple{Vararg{Int}}) where {T}
    p = similar(parent(A), T, dims)
    return unsafe_reconstruct(A, p; axes=SimpleAxis.(axes(p)))
end

@inline function Base.similar(A::AxisArray{T}, dims::Tuple{Vararg{Int}}) where {T}
    return similar(A, T, dims)
end
function Base.similar(A::AxisArray, ::Type{T}, dims::Tuple{Vararg{Union{Integer,OneTo}}}) where {T}
    p = similar(parent(A), T, dims)
    c = AxisArrayChecks{CheckedAxisLengths}()
    return AxisArray(p, map((key, axis) -> compose_axis(key, axis, c), dims, axes(p)); checks=c)
end

function Base.similar(a::AxisArray, ::Type{T}, dims::Tuple{Union{Integer, Base.OneTo},Vararg{Union{Integer, Base.OneTo}}}) where {T}
    p = similar(parent(A), T, dims)
    c = AxisArrayChecks{CheckedAxisLengths}()
    return AxisArray(p, map((key, axis) -> compose_axis(key, axis, c), dims, axes(p)); checks=c)
end

function Base.similar(A::AxisArray, ::Type{T}, ks::Tuple{AbstractUnitRange,Vararg{AbstractUnitRange}}) where {T}
    p = similar(parent(A), T, map(length, ks))
    c = AxisArrayChecks{CheckedAxisLengths}()
    return AxisArray(p, map((key, axis) -> compose_axis(key, axis, c), ks, axes(p)); checks=c)
end

#=
similar(::Type{T}, ks::Tuple{Vararg{AbstractAxis,N} where N}) where T<:AbstractArray 
similar(::Type{T}, dims::Tuple{Vararg{Int64,N}} where N) where T<:AbstractArray in Base at abstractarr


ay.jl:675)
26: similar
30: similar
60: similar
61: similar
=#
const DimOrAxes = Union{<:AbstractAxis,Base.DimOrInd}


function Base.similar(a::AbstractArray, ::Type{T}, dims::Tuple{Vararg{DimOrAxes}}) where {T}
    return _similar(a, T, dims)
end

function _similar(a::AxisArray, ::Type{T}, dims::Tuple) where {T}
    p = similar(parent(a), T, map(Base.to_shape, dims))
    axs = map((key, axis) -> compose_axis(key, axis, NoChecks), dims, axes(p))
    return AxisArray{eltype(p),ndims(p),typeof(p),typeof(axs)}(p, axs; checks=NoChecks)
end
function _similar(a, ::Type{T}, dims::Tuple) where {T}
    p = similar(a, T, map(Base.to_shape, dims))
    axs = map((key, axis) -> compose_axis(key, axis, NoChecks), dims, axes(p))
    return AxisArray{eltype(p),ndims(p),typeof(p),typeof(axs)}(p, axs; checks=NoChecks)
end

function Base.similar(A::AxisArray)
    p = similar(parent(A))
    return unsafe_reconstruct(A, p; axes=map(assign_indices, axes(A), axes(p)))
end

function Base.similar(::Type{T}, shape::Tuple{DimOrAxes,Vararg{DimOrAxes}}) where {T<:AbstractArray}
    p = similar(T, Base.to_shape(shape))
    axs = map((key, axis) -> compose_axis(key, axis, NoChecks), shape, axes(p))
    return AxisArray{eltype(p),ndims(p),typeof(p),typeof(axs)}(p, axs; checks=NoChecks)
end
#=
function Base.similar(::Type{T}, ks::Tuple{Vararg{<:AbstractAxis}}) where {T<:AbstractArray}
    p = similar(T, map(length, ks))
    c = AxisArrayChecks{CheckedAxisLengths}()
    return AxisArray(p, map((key, axis) -> compose_axis(key, axis, c), ks, axes(p)); checks=c)
end
=#

for (tf, T, sf, S) in (
    (parent, :AxisArray, parent, :AxisArray),
    (parent, :AxisArray, identity, :AbstractArray),
    (identity, :AbstractArray, parent, :AxisArray))

    @eval function Base.cat(A::$T, B::$S, Cs::AbstractArray...; dims)
        p = cat($tf(A), $sf(B); dims=dims)
        return cat(AxisArray(p, cat_axes(A, B, p, dims)), Cs..., dims=dims)
    end
end

for (tf, T, sf, S) in (
    (parent, :AxisVecOrMat, parent, :AxisVecOrMat),
    (parent, :AxisArray, identity, :VecOrMat),
    (identity, :VecOrMat, parent, :AxisArray))
    @eval function Base.vcat(A::$T, B::$S, Cs::VecOrMat...)
        p = vcat($tf(A), $sf(B))
        axs = vcat_axes(A, B, p)
        return vcat(AxisArray(p, axs; checks=NoChecks), Cs...)
    end

    @eval function Base.hcat(A::$T, B::$S, Cs::VecOrMat...)
        p = hcat($tf(A), $sf(B))
        axs = hcat_axes(A, B, p)
        return hcat(AxisArray(p, axs; checks=NoChecks), Cs...)
    end
end

function Base.hcat(A::AxisArray{T,N}) where {T,N}
    if N === 1
        return AxisArray(hcat(parent(A)), (axes(A, 1), axes(A, 2)))
    else
        return A
    end
end

Base.vcat(A::AxisArray{T,N}) where {T,N} = A

Base.cat(A::AxisArray{T,N}; dims) where {T,N} = A
