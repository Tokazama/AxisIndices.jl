
"""
    WindowIterator(axis)

## Examples
"""
struct WindowIterator{B<:AbstractRange{<:Integer},W<:AbstractRange{<:Integer}}
    bounds::B
    window::W
end

Base.length(w::WindowIterator) = length(getfield(w, :bounds))

@inline function _to_axis_step(axis, x)
    if is_key(x)
        return Int(div(x, step(keys(axis))))
    else
        return Int(div(x, step(axis)))
    end
end

function _window_iterator(axis, sz::Integer, first_pad, last_pad, stride, dilation)
    if dilation === nothing
        window = OneTo(sz)
    else
        fi = firstindex(axis)
        window = fi:_to_axis_step(axis, dilation):(fi + sz - 1)
    end


    start = firstindex(axis) - 1
    if first_pad !== nothing
        start = start + _to_axis_step(axis, first_pad)
    end

    stop = lastindex(axis) - sz
    if last_pad !== nothing
        stop = stop - _to_axis_step(axis, last_pad)
    end

    if stride === nothing
        bounds = range(start, step=sz, stop=stop)
    else
        bounds = range(start, step=_to_axis_step(axis, stride) + sz, stop = stop)
    end

    return WindowIterator(bounds, window)
end

function WindowIterator(axis, sz::Integer; first_pad=nothing, last_pad=nothing, stride=nothing, dilation=nothing)
    return _window_iterator(axis, sz, first_pad, last_pad, stride, dilation)
end

function WindowIterator(axis, window; first_pad=nothing, last_pad=nothing, stride=nothing, dilation=nothing)
    return _window_iterator(axis, to_index(axis, ), first_pad, last_pad, stride, dilation)
end

@inline function Base.iterate(w::WindowIterator)
    itr = iterate(getfield(w, :bounds))
    if itr === nothing
        return nothing
    else
        return _iterate(first(itr), getfield(w, :window)), last(itr)
    end
end

@inline function Base.iterate(w::WindowIterator, state)
    itr = iterate(getfield(w, :bounds), state)
    if itr === nothing
        return nothing
    else
        return _iterate(first(itr), getfield(w, :window)), last(itr)
    end
end

_iterate(itr, w::AbstractUnitRange) = (first(w) + itr):(last(w) + itr)
_iterate(itr, w::OrdinalRange) = (first(w) + itr):step(w):(last(w) + itr)

