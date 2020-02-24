
"""
    matmul_axes(a, b) -> Tuple

Returns the appropriate axes for the return of `a * b` where `a` and `b` are a
vector or matrix.

## Examples
```jldoctest
julia> using AxisIndices

julia> axs2, axs1 = (Axis(1:2), Axis(1:4)), (Axis(1:6),);

julia> matmul_axes(axs2, axs2)
(Axis(1:2 => Base.OneTo(2)), Axis(1:4 => Base.OneTo(4)))

julia> matmul_axes(axs1, axs2)
(Axis(1:6 => Base.OneTo(6)), Axis(1:4 => Base.OneTo(4)))

julia> matmul_axes(axs2, axs1)
(Axis(1:2 => Base.OneTo(2)),)

julia> matmul_axes(axs1, axs1)
()

julia> matmul_axes(rand(2, 4), rand(4, 2))
(Base.OneTo(2), Base.OneTo(2))

julia> matmul_axes(CartesianAxes((2,4)), CartesianAxes((4, 2))) == matmul_axes(rand(2, 4), rand(4, 2))
true
```
"""
matmul_axes(a::AbstractArray,  b::AbstractArray ) = matmul_axes(axes(a), axes(b))
matmul_axes(a::Tuple{Any},     b::Tuple{Any,Any}) = (first(a), last(b))
matmul_axes(a::Tuple{Any,Any}, b::Tuple{Any,Any}) = (first(a), last(b))
matmul_axes(a::Tuple{Any,Any}, b::Tuple{Any}    ) = (first(a),)
matmul_axes(a::Tuple{Any},     b::Tuple{Any}    ) = ()

"""
    inverse_axes(a::AbstractMatrix) = inverse_axes(axes(a))
    inverse_axes(a::Tuple{I1,I2}) -> Tuple{I2,I1}

Returns the inverted axes of `a`, corresponding to the `inv` method from the 
`LinearAlgebra` package in the standard library.

## Examples
```jldoctest
julia> using AxisIndices

julia> inverse_axes(rand(2,4))
(Base.OneTo(4), Base.OneTo(2))

julia> inverse_axes((Axis(1:2), Axis(1:4)))
(Axis(1:4 => Base.OneTo(4)), Axis(1:2 => Base.OneTo(2)))
```
"""
inverse_axes(x::AbstractMatrix) = inverse_axes(axes(x))
inverse_axes(x::Tuple{I1,I2}) where {I1,I2} = (last(x), first(x))

"""
    covcor_axes(x, dim) -> NTuple{2}

Returns appropriate axes for a `cov` or `var` method on array `x`.

## Examples
```jldoctest covcor_axes_examples
julia> using AxisIndices

julia> covcor_axes(rand(2,4), 1)
(Base.OneTo(4), Base.OneTo(4))

julia> covcor_axes((Axis(1:4), Axis(1:6)), 2)
(Axis(1:4 => Base.OneTo(4)), Axis(1:4 => Base.OneTo(4)))

julia> covcor_axes((Axis(1:4), Axis(1:4)), 1)
(Axis(1:4 => Base.OneTo(4)), Axis(1:4 => Base.OneTo(4)))
```

Each axis is resize to equal to the smallest sized dimension if given a dimensional
argument greater than 2.
```jldoctest covcor_axes_examples
julia> covcor_axes((Axis(2:4), Axis(3:4)), 3)
(Axis(2:3 => Base.OneTo(2)), Axis(3:4 => Base.OneTo(2)))
```
"""
covcor_axes(x::AbstractMatrix, dim::Int) = covcor_axes(axes(x), dim)
function covcor_axes(x::NTuple{2,Any}, dim::Int)
    if dim === 1
        return (last(x), last(x))
    elseif dim === 2
        return (first(x), first(x))
    else
        lf, ll = length.(x)
        if lf < ll
            return (first(x), shrink_last(last(x), ll - lf))
        elseif lf > ll
            return (shrink_last(first(x), lf - ll), last(x))
        else
            return x
        end
    end
end

