
module PrettyArrays

using PrettyTables
using Base: tail

export
    pretty_array,
    get_formatters,
    text_format,
    show_array

include("formatters.jl")
include("text.jl")
include("pretty_array.jl")

function show_array(
    io::IO,
    x::AbstractArray{T,N},
    axs::Tuple=axes(x),
    dnames::Tuple=ntuple(i -> Symbol(:dim_, i), N);
    kwargs...
) where {T,N}
    for i in 1:N
        println(io, " • $(getfield(dnames, i)) - $(getfield(axs, i))")
    end
    return pretty_array(io, x, axs, dnames; kwargs...)
end

end

