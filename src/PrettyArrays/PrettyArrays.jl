
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

    axis_io = IOContext(io, :compact => true)
    for i in 1:N
        print(axis_io, " • $(getfield(dnames, i)) - ")
        print(axis_io, getfield(axs, i))
        print(axis_io, "\n")
    end

    io_has_color = get(io, :color, false)
    buf_io       = IOBuffer()
    buf          = IOContext(buf_io, :color => io_has_color)

    pretty_array(buf, x, axs, dnames; kwargs...)
    print(io, chomp(String(take!(buf_io))))
    return nothing
end

end

