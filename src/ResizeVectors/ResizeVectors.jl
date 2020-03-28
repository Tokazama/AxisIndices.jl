
module ResizeVectors

using StaticRanges
using StaticRanges: can_set_first, can_set_last, can_set_length
using Base: @propagate_inbounds, OneTo, to_index, tail, front

export
    prev_type,
    next_type,
    grow_first,
    grow_first!,
    grow_last,
    grow_last!,
    shrink_first,
    shrink_first!,
    shrink_last,
    shrink_last!,
    resize_first,
    resize_first!,
    resize_last,
    resize_last!

include("prev_type.jl")
include("next_type.jl")
include("grow_first.jl")
include("grow_last.jl")
include("shrink_first.jl")
include("shrink_last.jl")
include("resize_first.jl")
include("resize_last.jl")

end

