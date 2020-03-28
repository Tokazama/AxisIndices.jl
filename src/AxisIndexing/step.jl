
Base.step(a::AbstractAxis) = step(values(a))

Base.step_hp(a::AbstractAxis) = Base.step_hp(values(a))

"""
    step_key(x)

Returns the step size of the keys of `x`.

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisIndices.step_key(Axis(1:2:10))
2

julia> AxisIndices.step_key(rand(2))
1
```
"""
@inline step_key(x::AbstractVector) = _step_keys(keys(x))
@inline step_key(x) = _step_keys(keys(x))
function _step_keys(ks)
    if StaticRanges.has_step(ks)
        return step(ks)
    else
        # TODO is `nothing` what we want when there isn't a step
        return nothing
    end
end
_step_keys(ks::LinearIndices) = 1

