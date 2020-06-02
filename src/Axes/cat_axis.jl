
cat_indices(x, y) = set_length(indices(x), length(x) + length(y))

cat_keys(x::AbstractVector, y::AbstractRange) = StaticRanges.grow_last(y, length(x))

cat_keys(x::AbstractRange, y::AbstractVector) = StaticRanges.grow_last(x, length(y))

cat_keys(x::AbstractRange, y::AbstractRange) = StaticRanges.grow_last(x, length(y))

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

function cat_axis(x::AbstractAxis, y::AbstractAxis, inds=cat_indices(x, y))
    if is_indices_axis(x)
        if is_indices_axis(y)
            return unsafe_reconstruct(x, inds)
        else
            return unsafe_reconstruct(y, set_length(keys(y), length(inds)), inds)
        end
    else
        if is_indices_axis(y)
            return unsafe_reconstruct(x, set_length(keys(x), length(inds)), inds)
        else
            return unsafe_reconstruct(y, cat_keys(keys(x), keys(y)), inds)
        end
    end
end

function cat_axis(x::AbstractUnitRange, y::AbstractAxis, inds=cat_indices(x, y))
    if is_indices_axis(y)
        return unsafe_reconstruct(y, inds)
    else
        return unsafe_reconstruct(y, set_length(keys(y), length(inds)), inds)
    end
end

function cat_axis(x::AbstractAxis, y::AbstractUnitRange, inds=cat_indices(x, y))
    if is_indices_axis(x)
        return unsafe_reconstruct(x, inds)
    else
        return unsafe_reconstruct(x, set_length(keys(x), length(inds)), inds)
    end
end

#=
    cat_axes(x::AbstractArray, y::AbstractArray, xy::AbstractArray, dims)

Produces the appropriate set of axes where `x` and `y` are the arrays that were
concatenated over `dims` to produce `xy`. The appropriate indices of each axis
are derived from from `xy`.
=#
@inline function cat_axes(x::AbstractArray, y::AbstractArray, xy::AbstractArray{T,N}, dims) where {T,N}
    ntuple(Val(N)) do i
        if i in dims
            cat_axis(axes(x, i), axes(y, i), axes(xy, i))
        else
            combine_axis(axes(x, i), axes(y, i), axes(xy, i))
        end
    end
end

# TODO do these work?
vcat_axes(x::AbstractArray, y::AbstractArray, xy::AbstractArray) = cat_axes(x, y, xy, 1)

hcat_axes(x::AbstractArray, y::AbstractArray, xy::AbstractArray) = cat_axes(x, y, xy, 2)

