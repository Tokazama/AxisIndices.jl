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
    sampling_rate,
    assert_timedim_last

Base.@pure is_time(x::Symbol) = (x === :time) || (x === :Time)

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
sampling_rate(x) = 1 / step(time_keys(x))

"""
    assert_timedim_last(x)

Throw an error if the `x` has a time dimension that is not the last dimension.
"""
@inline assert_timedim_last(x) = is_time(last(dimnames(x)))

end
