module TimeDims

using NamedDims
using AxisIndices.Names

export
    # @defdim output
    is_time,
    timedim,
    has_timedim,
    time_axis,
    time_axis_type,
    time_keys,
    time_indices,
    ntime,
    # other methods
    time_end,
    onset,
    duration,
    select_timedim,
    sampling_rate

Base.@pure is_time(x::Symbol) = x === :time

@defdim time is_time

"""
    time_end(x)

Last time point along the time axis.
"""
time_end(x) = last(time_keys(x))

"""
    onset(x)

First time point along the time axis.
"""
onset(x) = first(time_keys(x))

"""
    duration(x)

Duration of the event along the time axis.
"""
function duration(x)
    out = time_end(x) - onset(x)
    return out + oneunit(out)
end

"""
    sampling_rate(x)

Number of samples per second.
"""
sampling_rate(x) = 1 / step(time_axis(x))

end
