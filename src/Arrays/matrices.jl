
const AxisMatrix{T,P<:AbstractMatrix{T},Ax1,Ax2} = AxisArray{T,2,P,Tuple{Ax1,Ax2}}

"""
    rot180(A::AbstractAxisMatrix)

Rotate `A` 180 degrees, along with its axes keys.

## Examples
```jldoctest
julia> using AxisIndices

julia> a = AxisArray([1 2; 3 4], ["a", "b"], ["one", "two"]);

julia> b = rot180(a);

julia> axes_keys(b)
(["b", "a"], ["two", "one"])

julia> c = rotr90(rotr90(a));

julia> axes_keys(c)
(["b", "a"], ["two", "one"])

julia> a["a", "one"] == b["a", "one"] == c["a", "one"]
true
```
"""
function Base.rot180(x::AbstractAxisMatrix)
    p = rot180(parent(x))
    axs = (reverse_keys(axes(x, 1), axes(p, 1)), reverse_keys(axes(x, 2), axes(p, 2)))
    return unsafe_reconstruct(x, p, axs)
end


"""
    rotr90(A::AbstractAxisMatrix)

Rotate `A` right 90 degrees, along with its axes keys.

## Examples
```jldoctest
julia> using AxisIndices

julia> a = AxisArray([1 2; 3 4], ["a", "b"], ["one", "two"]);

julia> b = rotr90(a);

julia> axes_keys(b)
(["one", "two"], ["b", "a"])

julia> a["a", "one"] == b["one", "a"]
true
```
"""
function Base.rotr90(x::AbstractAxisMatrix)
    p = rotr90(parent(x))
    axs = (assign_indices(axes(x, 2), axes(p, 1)), reverse_keys(axes(x, 1), axes(p, 2)))
    return unsafe_reconstruct(x, p, axs)
end

"""
    rotl90(A::AbstractAxisMatrix)

Rotate `A` left 90 degrees, along with its axes keys.

## Examples
```jldoctest
julia> using AxisIndices

julia> a = AxisArray([1 2; 3 4], ["a", "b"], ["one", "two"]);

julia> b = rotl90(a);

julia> axes_keys(b)
(["two", "one"], ["a", "b"])

julia> a["a", "one"] == b["one", "a"]
true

```
"""
function Base.rotl90(x::AbstractAxisMatrix)
    p = rotl90(parent(x))
    axs = (reverse_keys(axes(x, 2), axes(p, 1)), assign_indices(axes(x, 1), axes(p, 2)))
    return unsafe_reconstruct(x, p, axs)
end

"""
    matmul_axes(a, b) -> Tuple

Returns the appropriate axes for the return of `a * b` where `a` and `b` are a
vector or matrix.

## Examples
```jldoctest
julia> using AxisIndices

julia> axs2, axs1 = (Axis(1:2), Axis(1:4)), (Axis(1:6),);

julia> AxisIndices.matmul_axes(axs2, axs2)
(Axis(1:2 => Base.OneTo(2)), Axis(1:4 => Base.OneTo(4)))

julia> AxisIndices.matmul_axes(axs1, axs2)
(Axis(1:6 => Base.OneTo(6)), Axis(1:4 => Base.OneTo(4)))

julia> AxisIndices.matmul_axes(axs2, axs1)
(Axis(1:2 => Base.OneTo(2)),)

julia> AxisIndices.matmul_axes(axs1, axs1)
()

julia> AxisIndices.matmul_axes(rand(2, 4), rand(4, 2))
(SimpleAxis(Base.OneTo(2)), SimpleAxis(Base.OneTo(2)))

julia> AxisIndices.matmul_axes(CartesianAxes((2,4)), CartesianAxes((4, 2))) == AxisIndices.matmul_axes(rand(2, 4), rand(4, 2))
true
```
"""
matmul_axes(a::AbstractArray,  b::AbstractArray ) = matmul_axes(axes(a), axes(b))
matmul_axes(a::Tuple{Any},     b::Tuple{Any,Any}) = (to_axis(first(a)), to_axis(last(b)))
matmul_axes(a::Tuple{Any,Any}, b::Tuple{Any,Any}) = (to_axis(first(a)), to_axis(last(b)))
matmul_axes(a::Tuple{Any,Any}, b::Tuple{Any}    ) = (to_axis(first(a)),)
matmul_axes(a::Tuple{Any},     b::Tuple{Any}    ) = ()

for (N1,N2) in ((2,2), (1,2), (2,1))
    @eval begin
        function Base.:*(a::AbstractAxisArray{T1,$N1}, b::AbstractAxisArray{T2,$N2}) where {T1,T2}
            return _matmul(a, promote_type(T1, T2), *(parent(a), parent(b)), matmul_axes(a, b))
        end
        function Base.:*(a::AbstractArray{T1,$N1}, b::AbstractAxisArray{T2,$N2}) where {T1,T2}
            return _matmul(b, promote_type(T1, T2), *(a, parent(b)), matmul_axes(a, b))
        end
        function Base.:*(a::AbstractAxisArray{T1,$N1}, b::AbstractArray{T2,$N2}) where {T1,T2}
            return _matmul(a, promote_type(T1, T2), *(parent(a), b), matmul_axes(a, b))
        end
    end
end

function Base.:*(a::Diagonal{T1}, b::AbstractAxisArray{T2,2}) where {T1,T2}
    return _matmul(b, promote_type(T1, T2), *(a, parent(b)), matmul_axes(a, b))
end
function Base.:*(a::AbstractAxisArray{T1,2}, b::Diagonal{T2}) where {T1,T2}
    return _matmul(a, promote_type(T1, T2), *(parent(a), b), matmul_axes(a, b))
end

_matmul(A, ::Type{T}, a::T, axs) where {T} = a
_matmul(A, ::Type{T}, a::AbstractArray{T}, axs) where {T} = unsafe_reconstruct(A, a, axs)

# Using `CovVector` results in Method ambiguities; have to define more specific methods.
for A in (Adjoint{<:Any, <:AbstractVector}, Transpose{<:Real, <:AbstractVector{<:Real}})
    @eval function Base.:*(a::$A, b::AbstractAxisArray{T,1,<:AbstractVector{T}}) where {T}
        return *(a, parent(b))
    end
end

# vector^T * vector
function Base.:*(a::AbstractAxisArray{T,2,<:CoVector}, b::AbstractAxisArray{S,1}) where {T,S}
    return *(parent(a), parent(b))
end

function covcor_axes(old_axes::NTuple{2,Any}, new_indices::NTuple{2,Any}, dim::Int)
    if dim === 1
        return (
            assign_indices(last(old_axes), first(new_indices)),
            StaticRanges.resize_last(last(old_axes), last(new_indices))
        )
    elseif dim === 2
        return (
            StaticRanges.resize_last(first(old_axes), first(new_indices)),
            assign_indices(first(old_axes), last(new_indices))
        )
    else
        return (
            StaticRanges.resize_last(first(old_axes), first(new_indices)),
            StaticRanges.resize_last(last(old_axes), last(new_indices))
        )
    end
end

for fun in (:cor, :cov)

    fun_doc = """
        $fun(x::AbstractAxisArrayMatrix; dims=1, kwargs...)

    Performs `$fun` on the parent matrix of `x` and reconstructs a similar type
    with the appropriate axes.

    ## Examples
    ```jldoctest
    julia> using AxisIndices, Statistics

    julia> A = AxisArray([1 2 3; 4 5 6; 7 8 9], ["a", "b", "c"], [:one, :two, :three]);

    julia> axes_keys($fun(A, dims = 2))
    (["a", "b", "c"], ["a", "b", "c"])

    julia> axes_keys($fun(A, dims = 1))
    ([:one, :two, :three], [:one, :two, :three])

    ```
    """
    @eval begin
        @doc $fun_doc
        function Statistics.$fun(x::AbstractAxisArray{T,2}; dims=1, kwargs...) where {T}
            p = Statistics.$fun(parent(x); dims=dims, kwargs...)
            return unsafe_reconstruct(x, p, covcor_axes(axes(x), axes(p), dims))
        end
    end
end

# TODO get rid of indicesarray_result
for f in (:mean, :std, :var, :median)
    @eval function Statistics.$f(a::AbstractAxisArray; dims=:, kwargs...)
        return reconstruct_reduction(a, Statistics.$f(parent(a); dims=dims, kwargs...), dims)
    end
end
