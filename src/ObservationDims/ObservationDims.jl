module ObservationDims

using NamedDims
using AxisIndices.Names

export
    # @defdim output
    obsdim,
    has_obsdim,
    obs_axis,
    obs_axis_type,
    obs_keys,
    obs_indices,
    nobs,
    is_observation,
    select_obsdim
 
Base.@pure is_observation(x::Symbol) = (x === :obs) | (x === :observations) | (x === :samples)

@defdim obs is_observation

end
