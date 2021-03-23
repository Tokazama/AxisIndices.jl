#=
for (f, FT, arg) in ((:+, typeof(+), Real),)
    @eval begin
        function Base.broadcasted(::DefaultArrayStyle{1}, ::$FT, x::$arg, r::AbstractAxis)
            return unsafe_reconstruct(r, broadcast($f, x, eachindex(r)))
        end
        function Base.broadcasted(::DefaultArrayStyle{1}, ::$FT, r::AbstractAxis, x::$arg)
            return unsafe_reconstruct(r, broadcast($f, eachindex(r), x))
        end
    end
end
=#

###
### cat
###
cat_indices(x, y) = set_length(indices(x), length(x) + length(y))

cat_keys(x::AbstractVector, y::AbstractRange) = StaticRanges.grow_end(y, length(x))

cat_keys(x::AbstractRange, y::AbstractVector) = StaticRanges.grow_end(x, length(y))

cat_keys(x::AbstractRange, y::AbstractRange) = StaticRanges.grow_end(x, length(y))

cat_keys(x::AbstractVector, y::AbstractVector) = cat_keys!(promote(x, y)...,)

cat_keys(x::AbstractVector{T}, y::AbstractVector{T}) where {T} = cat_keys!(copy(x), y)

function cat_keys!(x::AbstractVector{T}, y::AbstractVector{T}) where {T}
    for x_i in x
        if x_i in y
            error("Element $x_i appears in both collections in call to cat_axis!(collection1, collection2). All elements must be unique.")
        end
    end
    return vcat(x, y)
end

function cat_axis(x::Axis, y::AbstractUnitRange, inds=cat_indices(x, y))
    return maybe_unsafe_reconstruct(x, inds; keys=cat_keys(keys(x), keys(y)))
end

function cat_axis(x::Axis, y::Axis, inds=cat_indices(x, y))
    return maybe_unsafe_reconstruct(x, inds; keys=cat_keys(keys(x), keys(y)))
end

function cat_axis(x::AbstractUnitRange, y::Axis, inds=cat_indices(x, y))
    return maybe_unsafe_reconstruct(y, inds; keys=cat_keys(keys(x), keys(y)))
end

function cat_axis(x::AbstractUnitRange, y::AbstractUnitRange, inds=cat_indices(x, y))
    if x isa AbstractAxis
        return unsafe_reconstruct(x, inds)
    else
        return unsafe_reconstruct(y, inds)
    end
end

#=
    cat_axes(x::AbstractArray, y::AbstractArray, xy::AbstractArray, dims)

Produces the appropriate set of axes where `x` and `y` are the arrays that were
concatenated over `dims` to produce `xy`. The appropriate indices of each axis
are derived from from `xy`.
=#

#dims_indicators(x, dims)

@inline function cat_axes(x::AbstractArray, y::AbstractArray, xy::AbstractArray{T,N}, dims) where {T,N}
    ntuple(Val(N)) do i
        if i in dims
            cat_axis(axes(x, i), axes(y, i), axes(xy, i))
        else
            broadcast_axis(axes(x, i), axes(y, i), axes(xy, i))
        end
    end
end
# TODO do these work?
vcat_axes(x::AbstractArray, y::AbstractArray, xy::AbstractArray) = cat_axes(x, y, xy, 1)

hcat_axes(x::AbstractArray, y::AbstractArray, xy::AbstractArray) = cat_axes(x, y, xy, 2)

###
### combine
###
# LinearIndices indicates that keys are not formally defined so the collection
# that isn't LinearIndices is used. If both are LinearIndices then take the underlying
# OneTo as the new keys.
combine_keys(x, y) = _combine_keys(keys(x), keys(y))
_combine_keys(x, y) = promote_axis_collections(x, y)
_combine_keys(x,                y::LinearIndices) = x
_combine_keys(x::LinearIndices, y               ) = y
_combine_keys(x::LinearIndices, y::LinearIndices) = first(y.indices)

