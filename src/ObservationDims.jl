
module ObservationDims

using NamedDims
using AxisIndices.Interface
using AxisIndices.NamedAxes


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
    select_obs,
    each_obs
 
Base.@pure is_observation(x::Symbol) = (x === :obs) | (x === :observations) | (x === :samples)

NamedAxes.@defdim obs is_observation

end

