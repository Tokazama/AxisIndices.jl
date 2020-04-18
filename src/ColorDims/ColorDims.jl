module ColorDims

using NamedDims
using AxisIndices.Names

export
    is_color,
    # @defdim output
    colordim,
    has_colordim,
    color_axis,
    color_axis_type,
    color_keys,
    color_indices,
    ncolor,
    select_colordim

Base.@pure is_color(x::Symbol) = x === :color

@defdim color is_color

end
