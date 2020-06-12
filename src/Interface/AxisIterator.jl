
"""
    AxisIterator(axis, window_size[, first_pad=nothing, last_pad=nothing, stride=nothing, dilation=nothing])

Creates an iterator for indexing ranges of elements within `axis`.

## Examples

Size of the window may be determined by providing an explicit size or the size in
terms of the keys of an axis.
```jldoctest axis_iterator_examples
julia> using AxisIndices

julia> axis = Axis(range(2.0, step=3.0, length=20))
Axis(2.0:3.0:59.0 => Base.OneTo(20))

julia> collect(AxisIterator(axis, 3))
6-element Array{Any,1}:
 1:3
 4:6
 7:9
 10:12
 13:15
 16:18

julia> collect(AxisIterator(axis, 9.0))
6-element Array{Any,1}:
 1:3
 4:6
 7:9
 10:12
 13:15
 16:18

```

The iterator may start with padding from the beginning..
```jldoctest axis_iterator_examples
julia> collect(AxisIterator(axis, 3, first_pad=1))
6-element Array{Any,1}:
 2:4
 5:7
 8:10
 11:13
 14:16
 17:19

julia> collect(AxisIterator(axis, 9.0, first_pad=3.0))
6-element Array{Any,1}:
 2:4
 5:7
 8:10
 11:13
 14:16
 17:19

```
...and the end.
```jldoctest axis_iterator_examples
julia> collect(AxisIterator(axis, 3, first_pad=1, last_pad=2))
5-element Array{Any,1}:
 2:4
 5:7
 8:10
 11:13
 14:16

julia> collect(AxisIterator(axis, 9.0, first_pad=3.0, last_pad=6.0))
5-element Array{Any,1}:
 2:4
 5:7
 8:10
 11:13
 14:16

```

The window can be dilated so that a regular but non-continuous range of elements
are indexed.
```jldoctest axis_iterator_examples
julia> collect(AxisIterator(axis, 3, first_pad=1, last_pad=2, dilation=2))
5-element Array{Any,1}:
 2:2:4
 5:2:7
 8:2:10
 11:2:13
 14:2:16

julia> collect(AxisIterator(axis, 9.0, first_pad=3.0, last_pad=6.0, dilation=6.0))
5-element Array{Any,1}:
 2:2:4
 5:2:7
 8:2:10
 11:2:13
 14:2:16

```

Regular strides can be placed between each iteration.
```jldoctest axis_iterator_examples
julia> collect(AxisIterator(axis, 3, first_pad=1, last_pad=2, stride=2))
3-element Array{Any,1}:
 2:4
 7:9
 12:14

julia> collect(AxisIterator(axis, 9.0, first_pad=3.0, last_pad=6.0, stride=6.0))
3-element Array{Any,1}:
 2:4
 7:9
 12:14

```
"""
struct AxisIterator{B<:AbstractRange{<:Integer},W<:AbstractRange{<:Integer}}
    bounds::B
    window::W

    AxisIterator{B,W}(bounds::B, window::W) where {B,W} = new{B,W}(bounds, window)

    function AxisIterator(axis, sz; first_pad=nothing, last_pad=nothing, stride=nothing, dilation=nothing)
        return _axis_iterator(axis, _to_size(axis, sz), first_pad, last_pad, stride, dilation)
    end
end

@inline function _to_size(axis, x)
    if is_key(x)
        return Int(div(x, step(keys(axis))))
    else
        return Int(div(x, step(axis)))
    end
end

function _axis_iterator(axis, sz::Integer, first_pad, last_pad, stride, dilation)
    if dilation === nothing
        window = OneTo(sz)
    else
        fi = firstindex(axis)
        window = fi:_to_size(axis, dilation):(fi + sz - 1)
    end


    start = firstindex(axis) - 1
    if first_pad !== nothing
        start = start + _to_size(axis, first_pad)
    end

    stop = lastindex(axis) - sz
    if last_pad !== nothing
        stop = stop - _to_size(axis, last_pad)
    end

    if stride === nothing
        bounds = range(start, step=sz, stop=stop)
    else
        bounds = range(start, step=_to_size(axis, stride) + sz, stop = stop)
    end

    return AxisIterator{typeof(bounds),typeof(window)}(bounds, window)
end

Base.length(w::AxisIterator) = length(getfield(w, :bounds))

@inline function Base.iterate(w::AxisIterator)
    itr = iterate(getfield(w, :bounds))
    if itr === nothing
        return nothing
    else
        return _iterate(first(itr), getfield(w, :window)), last(itr)
    end
end

@inline function Base.iterate(w::AxisIterator, state)
    itr = iterate(getfield(w, :bounds), state)
    if itr === nothing
        return nothing
    else
        return _iterate(first(itr), getfield(w, :window)), last(itr)
    end
end

_iterate(itr, w::AbstractUnitRange) = (first(w) + itr):(last(w) + itr)
_iterate(itr, w::OrdinalRange) = (first(w) + itr):step(w):(last(w) + itr)

