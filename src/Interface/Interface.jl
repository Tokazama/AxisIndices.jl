module Interface

using AxisIndices.Styles
using AxisIndices.Metadata
using NamedDims
using StaticRanges
using StaticRanges: OneToUnion
using StaticRanges: Staticness, Fixed, Static, Dynamic
using StaticRanges: resize_last

import MetadataArrays: MetadataArray

using Base: @propagate_inbounds, OneTo, Fix2, tail, front, Fix2

export
    AxisIterator,
    AxesIterator,
    @defdim,
    # methods
    axes_keys,
    axis_eltype,
    axis_eltypes,
    axis_meta,
    colaxis,
    colkeys,
    coltype,
    drop_axes,
    first_key,
    has_dimnames,
    has_metadata,
    last_key,
    metadata,
    metadata_type,
    named_axes,
    indices,
    indices_type,
    is_indices_axis,
    keys_type,
    rowaxis,
    rowkeys,
    rowtype,
    select_axes,
    step_key,
    unsafe_reconstruct,
    # NamedDims API
    dim,
    dimnames

@static if !isdefined(Base, :IdentityUnitRange)
    const IdentityUnitRange = Base.Slice
else
    using Base: IdentityUnitRange
end

const AbstractIndices{T<:Integer} = AbstractUnitRange{T}

include("utils.jl")
include("indices.jl")
include("keys.jl")
include("names.jl")
include("axes.jl")
include("rows.jl")
include("cols.jl")
include("constructors.jl")
include("to_index.jl")
include("to_keys.jl")
include("to_axes.jl")
include("checkindex.jl")
include("iterators.jl")

end

