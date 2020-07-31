module Interface

using EllipsisNotation
using AxisIndices.Styles
using MappedArrays
using NamedDims
using StaticRanges
using StaticRanges: OneToUnion
using StaticRanges: resize_last

import MetadataArrays: MetadataArray

using MappedArrays: ReadonlyMultiMappedArray, MultiMappedArray, ReadonlyMappedArray
using EllipsisNotation: Ellipsis
using Base: @propagate_inbounds, OneTo, Fix2, tail, front

export
    AxisIterator,
    AxesIterator,
    @defdim,
    # methods
    axes_keys,
    axis_eltype,
    axis_eltypes,
    col_axis,
    col_keys,
    col_type,
    drop_axes,
    has_dimnames,
    named_axes,
    parent_type,
    indices,
    indices_type,
    is_indices_axis,
    keys_type,
    row_axis,
    row_keys,
    row_type,
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
include("to_indices.jl")
include("to_keys.jl")
include("to_axes.jl")
include("checkindex.jl")
include("iterators.jl")

end

