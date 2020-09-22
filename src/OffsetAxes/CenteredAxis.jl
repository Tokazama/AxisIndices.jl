# TODO Mutating methods on CenteredAxis need to be specialize to ensure the center
# is maintained


### centered_start
centered_start(::Type{T}, x::AbstractUnitRange) where {T} = _centered_start_from_len(T, length(x))
_centered_start_from_len(::Type{T}, len) where {T} = T(-div(len, 2))

### centered_stop
@inline function centered_stop(::Type{T}, x::AbstractUnitRange) where {T}
    len = length(x)
    return _centered_stop_from_len_and_start(_centered_start_from_len(T, len), len)
end
_centered_stop_from_len_and_start(start::T, len) where {T} = T(start + len - 1)

function _reset_keys!(axis::CenteredAxis{K}) where {K}
    len = length(indices(axis))
    start = K(-div(len, 2))
    stop = K(start + len - 1)
    ks = keys(axis)
    set_first!(ks, start)
    set_last!(ks, stop)
    return nothing
end

"""
    center(inds::AbstractUnitRange{<:Integer}) -> CenteredAxis(inds)

Shortcut for creating [`CenteredAxis`](@ref).

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisArray(ones(3), center)
3-element AxisArray{Float64,1}
 • dim_1 - -1:1

  -1   1.0
   0   1.0
   1   1.0

```
"""
center(inds) = CenteredAxis(inds)

@inline function known_offset(::Type{<:CenteredAxis{I,Inds}}) where {I,Inds}
    if start === nothing || stop === nothing
        return nothing
    else
        return _find_center(start, stop)
    end
end

function get_offset(axis::CenteredAxis)
    inds = parentindices(axis)
    return _find_center(first(inds), last(inds))
end


ArrayInterface.parent_type(::Type{T}) where {Inds,T<:CenteredAxis{<:Any,Inds}} = Inds

