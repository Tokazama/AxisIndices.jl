
"""
    cat_axis(x, y) -> cat_axis(CombineStyle(x, y), x, y)
    cat_axis(::CombineStyle, x, y) -> collection

Returns the concatenated axes `x` and `y`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.cat_axis(Axis(UnitMRange(1, 10)), SimpleAxis(UnitMRange(1, 10)))
Axis(UnitMRange(1:20) => UnitMRange(1:20))

julia> AxisIndices.cat_axis(SimpleAxis(UnitMRange(1, 10)), SimpleAxis(UnitMRange(1, 10)))
SimpleAxis(UnitMRange(1:20))
```
"""
cat_axis(x, y) = cat_axis(CombineStyle(x, y), x, y)
cat_axis(x, y, inds) = cat_axis(CombineStyle(x, y), x, y, inds)

function cat_axis(cs::CombineResize, x::X, y::Y) where {X,Y}
    return set_length(promote_axis_collections(x, y), length(x) + length(y))
end

function cat_axis(cs::CombineStack, x::AbstractVector{T}, y::AbstractVector{T}) where {T}
    for x_i in x
        if x_i in y
            error("Element $x_i appears in both collections in call to cat_axis!(collection1, collection2). All elements must be unique.")
        end
    end
    return vcat(x, y)
end

function cat_axis(cs::CombineStack, x::AbstractVector{T1}, y::AbstractVector{T2}) where {T1,T2}
    return Vcat(x, y)
end

function cat_axis(::CombineAxis, x::X, y::Y) where {X,Y}
    ks = cat_axis(keys(x), keys(y))
    vs = cat_axis(values(x), values(y))
    return similar_type(promote_type(X, Y), typeof(ks), typeof(vs))(ks, vs)
end

function cat_axis(::CombineSimpleAxis, x::X, y::Y) where {X,Y}
    vs = cat_axis(values(x), values(y))
    return similar_type(promote_type(X, Y), typeof(vs))(vs)
end

function cat_axis(::CombineAxis, x::X, y::Y, inds::I) where {X,Y,I}
    ks = cat_axis(keys(x), keys(y))
    return similar_type(promote_type(X, Y), typeof(ks), I)(ks, inds)
end

function cat_axis(::CombineSimpleAxis, x::X, y::Y, inds::I) where {X,Y,I}
    return similar_type(promote_type(X, Y), I)(inds)
end

for (tf, T, sf, S) in ((parent, :AbstractAxisIndicesVecOrMat, parent, :AbstractAxisIndicesVecOrMat),
                       (parent, :AbstractAxisIndicesVecOrMat, identity, :AbstractVecOrMat),
                       (identity, :AbstractVecOrMat,          parent,  :AbstractAxisIndicesVecOrMat))
    @eval function Base.vcat(A::$T, B::$S, Cs::AbstractVecOrMat...)
        return vcat(AxisIndicesArray(vcat($tf(A), $sf(B)), vcat_axes(A, B)), Cs...)
    end

    @eval function Base.hcat(A::$T, B::$S, Cs::AbstractVecOrMat...)
        return hcat(AxisIndicesArray(hcat($tf(A), $sf(B)), hcat_axes(A, B)), Cs...)
    end

    @eval function Base.cat(A::$T, B::$S, Cs::AbstractVecOrMat...; dims)
        #=
        N = ndims(A)
        axs = ntuple(N) do i
            if i in dims
                cat_axis(axes(A, i), axes(B, i))
            else
                broadcast_axis(axes(A, i), axes(B, i))
            end
        end
        =#
        p = cat($tf(A), $sf(B); dims=dims)
        return cat(AxisIndicesArray(p, cat_axes(A, B, p, dims)), Cs..., dims=dims)
    end
end

function Base.hcat(A::AbstractAxisIndices{T,N}) where {T,N}
    if N === 1
        return unsafe_reconstruct(A, hcat(parent(A)), (axes(A, 1), SimpleAxis(OneTo(1))))
    else
        return A
    end
end

Base.vcat(A::AbstractAxisIndices{T,N}) where {T,N} = A
Base.cat(A::AbstractAxisIndices{T,N}; dims) where {T,N} = A

"""
    cat_axes(x::AbstractArray, y::AbstractArray, xy::AbstractArray, dims)

Produces the appropriate set of axes where `x` and `y` are the arrays that were
concatenated over `dims` to produce `xy`. The appropriate indices of each axis
are derived from from `xy`.
"""
@inline function cat_axes(x::AbstractArray, y::AbstractArray, xy::AbstractArray{T,N}, dims) where {T,N}
    ntuple(Val(N)) do i
        if i in dims
            cat_axis(axes(x, i), axes(y, i), axes(xy, i))
        else
            broadcast_axis(axes(x, i), axes(y, i), true_axes(xy, i))
        end
    end
end

# TODO do these work?
function vcat_axes(x::AbstractArray, y::AbstractArray, xy::AbstractArray)
    return cat_axes(x, y, xy, 1)
end

function hcat_axes(x::AbstractArray, y::AbstractArray, xy::AbstractArray)
    return cat_axes(x, y, xy) = cat_axes(x, y, xy, 2)
end

@inline function cat_axes(x::AbstractArray{T1,N1}, y::AbstractArray{T2,N2}, dims) where {T1,T2,N1,N2}
    ntuple(Val(max(N1,N2))) do i
        if i in dims
            cat_axis(axes(x, i), axes(y, i))
        else
            broadcast_axis(axes(x, i), axes(y, i))
        end
    end
end

vcat_axes(x::AbstractArray, y::AbstractArray) = cat_axes(x, y, 1)

hcat_axes(x::AbstractArray, y::AbstractArray) = cat_axes(hcat(x), hcat(y), 2)
