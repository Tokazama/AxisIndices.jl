
module ObservationDims

using NamedDims
using AxisIndices.Interface

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

Interface.@defdim obs is_observation

end
