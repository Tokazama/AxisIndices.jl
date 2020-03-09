
#=
"""
    cat_axis(x, y)

Returns the concatenation of the axes `x` and `y`. New subtypes of `AbstractAxis`
must implement a unique `cat_axis` method.
"""
function cat_axis(x::AbstractAxis, y::AbstractAxis)
    ks = cat_keys(keys(x), keys(y))
    vs = cat_values(values(x), values(y))
    return similar_type(x, typeof(ks), typeof(vs))(ks, vs)
end
function cat_axis(x::AbstractSimpleAxis, y::AbstractAxis)
    ks = cat_keys(keys(x), keys(y))
    vs = cat_values(values(x), values(y))
    return similar_type(x, typeof(ks), typeof(vs))(ks, vs)
end
function cat_axis(x::AbstractAxis, y::AbstractSimpleAxis)
    ks = cat_keys(keys(x), keys(y))
    vs = cat_values(values(x), values(y))
    return similar_type(x, typeof(ks), typeof(vs))(ks, vs)
end
function cat_axis(x::AbstractSimpleAxis, y::AbstractSimpleAxis)
    vs = cat_values(values(x), values(y))
    return similar_type(x, typeof(vs))(vs)
end
cat_axis(x, y) = cat_values(x, y)
"""
    cat_keys(x, y)

Returns the appropriate keys of the `x` and `y` index within the operation `cat_axis(x, y)`

See also: [`cat_axis`](@ref)
"""
cat_keys(x, y) = __cat_keys(StaticRanges.Continuity(x), x, y)
__cat_keys(::StaticRanges.ContinuousTrait, x, y) = set_length(x, length(x) + length(y))
function __cat_keys(::StaticRanges.DiscreteTrait, x, y)
    return error("No method defined for combining keys of type $(typeof(x)) and $(typeof(y)).")
end

"""
    cat_values(x, y)

Returns the appropriate values of the `x` and `y` index within the operation `cat_axis(x, y)`

See also: [`cat_axis`](@ref)
"""
function cat_values(x::AbstractUnitRange{<:Integer}, y::AbstractUnitRange{<:Integer})
    val, _ = promote(x, y)
    return set_length(val, length(x) + length(y))
end

=#

"""
    cat_axes(x, y, dims) -> Tuple

Returns the appropriate axes for `cat(x, y; dims)`. If any of `dims` are names
then they should refer to the dimensions of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.cat_axes(LinearAxes((2,3)), LinearAxes((2,3)), dims=(1,2))
(SimpleAxis(Base.OneTo(4)), SimpleAxis(Base.OneTo(6)))
```
"""
cat_axes(x::AbstractArray, y::AbstractArray; dims) = cat_axes(axes(x), axes(y), dims)
cat_axes(x::Tuple, y::Tuple; dims) = cat_axes(x, y, dims)

function cat_axes(x::Tuple{Vararg{<:Any,N}}, y::Tuple{Vararg{<:Any,N}}, dims::Int) where {N}
    return cat_axes(x, y, (dims,))
end
function cat_axes(
    x::Tuple{Vararg{<:Any,N}},
    y::Tuple{Vararg{<:Any,N}},
    dims::Tuple{Vararg{Int}}
   ) where {N}

    return Tuple([ifelse(in(i, dims),
                         cat_axis(x[i], y[i]),
                         broadcast_axis(x[i], y[i])
                        ) for i in 1:N])
end


"""
    vcat_axes(x, y) -> Tuple

Returns the appropriate axes for `vcat(x, y)`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.vcat_axes((Axis(1:2), Axis(1:4)), (Axis(1:2), Axis(1:4)))
(Axis(1:4 => Base.OneTo(4)), Axis(1:4 => Base.OneTo(4)))

julia> a, b = [1 2 3 4 5], [6 7 8 9 10; 11 12 13 14 15];

julia> AxisIndices.vcat_axes(a, b) == axes(vcat(a, b))
true

julia> c, d = LinearAxes((1:1, 1:5,)), LinearAxes((1:2, 1:5));

julia> length.(AxisIndices.vcat_axes(c, d)) == length.(AxisIndices.vcat_axes(a, b))
true
```
"""
vcat_axes(x::AbstractArray, y::AbstractArray) = vcat_axes(axes(x), axes(y))
function vcat_axes(x::Tuple{Any,Vararg}, y::Tuple{Any,Vararg})
    return (cat_axis(first(x), first(y)), Broadcast.broadcast_shape(tail(x), tail(y))...)
end

"""
    hcat_axes(x, y) -> Tuple

Returns the appropriate axes for `hcat(x, y)`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.hcat_axes((Axis(1:4), Axis(1:2)), (Axis(1:4), Axis(1:2)))
(Axis(1:4 => Base.OneTo(4)), Axis(1:4 => Base.OneTo(4)))

julia> a, b = [1; 2; 3; 4; 5], [6 7; 8 9; 10 11; 12 13; 14 15];

julia> AxisIndices.hcat_axes(a, b) == axes(hcat(a, b))
true

julia> c, d = CartesianAxes((Axis(1:5),)), CartesianAxes((Axis(1:5), Axis(1:2)));

julia> length.(AxisIndices.hcat_axes(c, d)) == length.(AxisIndices.hcat_axes(a, b))
true
```
"""
hcat_axes(x::AbstractArray, y::AbstractArray) = hcat_axes(axes(x), axes(y))
function hcat_axes(x::Tuple, y::Tuple)
    return (broadcast_axis(first(x), first(y)), _hcat_axes(tail(x), tail(y))...)
end
_hcat_axes(x::Tuple{}, y::Tuple) = (grow_last(first(y), 1), tail(y)...)
_hcat_axes(x::Tuple, y::Tuple{}) = (grow_last(first(x), 1), tail(x)...)
_hcat_axes(x::Tuple{}, y::Tuple{}) = (SimpleAxis(OneTo(2)),)
function _hcat_axes(x::Tuple, y::Tuple)
    return (cat_axis(first(x), first(y)), _combine_axes(tail(x), tail(y))...)
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
        N = ndims(A)
        axs = ntuple(N) do i
            if i in dims
                cat_axis(axes(A, i), axes(B, i))
            else
                broadcast_axis(axes(A, i), axes(B, i))
            end
        end
        p = cat($tf(A), $sf(B); dims=dims)
        #=
        Ndiff = ndims(p) - N
        if Ndiff != 0
            axs = (axs..., ntuple(_ -> SimpleAxis(OneTo(1)), Ndiff-1)..., SimpleAxis(OneTo(2)))
        end
        =#
        #return cat(AxisIndicesArray(p, axs), Cs..., dims=dims)
        return cat(AxisIndicesArray(p, axs), Cs..., dims=dims)
    end
end

function Base.hcat(A::AbstractAxisIndices{T,N}) where {T,N}
    if N === 1
        m = hcat(parent(A))
        axs = (axes(A, 1), SimpleAxis(OneTo(1)))
        return similar_type(A, typeof(m), typeof(axs))(m, axs)
    else
        return A
    end
end

Base.vcat(A::AbstractAxisIndices{T,N}) where {T,N} = A
Base.cat(A::AbstractAxisIndices{T,N}; dims) where {T,N} = A

