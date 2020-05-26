module Interface

using NamedDims
using ChainedFixes
using IntervalSets
using StaticRanges

using Base: @propagate_inbounds, OneTo, Fix2, tail, front, Fix2

export
    # Traits
    Indices,
    Keys,
    AxisIndicesStyle,
    KeyElement,
    IndexElement,
    BoolElement,
    CartesianElement,
    KeysCollection,
    IndicesCollection,
    IntervalCollection,
    BoolsCollection,
    KeysIn,
    IndicesIn,
    KeyEquals,
    IndexEquals,
    KeysFix2,
    IndicesFix2,
    SliceCollection,
    KeyedStyle,
    @defdim,
    # methods
    axes_keys,
    axis_eltype,
    axis_eltypes,
    colaxis,
    colkeys,
    coltype,
    drop_axes,
    first_key,
    has_dimnames,
    last_key,
    named_axes,
    indices,
    indices_type,
    is_collection,
    is_element,
    is_index,
    is_indices_axis,
    is_key,
    is_keys,  # TODO doc is_keys method
    keys_type,
    rowaxis,
    rowkeys,
    rowtype,
    select_axes,
    step_key,
    # NamedDims API
    dim,
    dimnames

@static if !isdefined(Base, :IdentityUnitRange)
    const IdentityUnitRange = Base.Slice
else
    using Base: IdentityUnitRange
end

include("utils.jl")
include("names.jl")
include("axes.jl")
include("styles.jl")
include("combine.jl")

end
