
module PrettyArrays

using PrettyTables
using StaticRanges
using AxisIndices.AxisCore
using AxisIndices.Names
using Base: tail

export
    pretty_array,
    get_formatters,
    text_format

include("formatters.jl")
include("text.jl")
include("latex.jl")
include("html.jl")
include("pretty_array.jl")

function Base.show(io::IO, m::MIME"text/plain", x::AbstractAxisIndices{T,N}; kwargs...) where {T,N}
    println(io, "$N-dimensional $(typeof(x).name.name){$T,$N,$(parent_type(x))...}")
    return pretty_array(io, parent(x), named_axes(x); kwargs...)
end

function Base.show(io::IO, m::MIME"text/plain", x::NIArray{L,T,N}; kwargs...) where {L,T,N}
    println(io, "$N-dimensional $(typeof(x).name.name){$T,$N,$(parent_type(parent(x)))...}")
    return pretty_array(io, parent(parent(x)), named_axes(x); kwargs...)
end


end

