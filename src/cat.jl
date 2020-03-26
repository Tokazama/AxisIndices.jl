
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
        return unsafe_reconstruct(hcat(parent(A)), (axes(A, 1), SimpleAxis(OneTo(1))))
    else
        return A
    end
end

Base.vcat(A::AbstractAxisIndices{T,N}) where {T,N} = A
Base.cat(A::AbstractAxisIndices{T,N}; dims) where {T,N} = A

