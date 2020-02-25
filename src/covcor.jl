
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

Each axis is resized to equal to the smallest sized dimension if given a dimensional
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

for fun in (:cor, :cov)
    @eval function Statistics.$fun(a::AxisIndicesMatrix; dims=1, kwargs...)
        return AxisIndicesArray(Statistics.$fun(parent(a); dims=dims, kwargs...), covcor_axes(a, dims))
    end
end
