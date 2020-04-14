
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
include("pretty_array.jl")

function Base.show(io::IO, x::AbstractAxisIndices; kwargs...)
    return show(io, MIME"text/plain"(), x, kwargs...)
end
function Base.show(io::IO, m::MIME"text/plain", x::AbstractAxisIndices{T,N}; kwargs...) where {T,N}
    println(io, "$(typeof(x).name.name){$T,$N,$(parent_type(x))...}")
    return show_array(io, x; kwargs...)
end

Base.show(io::IO, x::NIArray; kwargs...) = show(io, MIME"text/plain"(), x, kwargs...)
function Base.show(io::IO, m::MIME"text/plain", x::NIArray{L,T,N}; kwargs...) where {L,T,N}
    println(io, "$(typeof(x).name.name){$T,$N,$(parent_type(parent(x)))...}")
    return show_array(io, x; kwargs...)
    #println(io, "$N-dimensional $(typeof(x).name.name){$T,$N,$(parent_type(parent(x)))...}")
    #return pretty_array(io, parent(parent(x)), named_axes(x); kwargs...)
end

function show_array(io::IO, x::AbstractArray{T,N}; kwargs...) where {T,N}
    return show_array(io, x, named_axes(x); kwargs...)
end

function show_array(io::IO, x::AbstractArray{T,N}, axs::NamedTuple{L}; kwargs...) where {T,N,L}
    for i in 1:N
        println(io, " • $(L[i]) - $(axes(x, i))")
    end
    return pretty_array(io, x, named_axes(x); screen_size=displaysize(io), kwargs...)
end




end

