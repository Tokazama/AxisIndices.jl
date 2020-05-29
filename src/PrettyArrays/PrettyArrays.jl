
module PrettyArrays

using AxisIndices.Interface

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


function print_array_summary(io::IO, A::AbstractArray{T,N}) where {T,N}
    print(io, join(size(A), "×"))
    print(io, " $(typeof(A).name.name){$T,$N}\n")
end

function print_array_summary(io::IO, A::AbstractVector{T}) where {T}
    print(io, "$(length(A))-element")
    print(io, " $(typeof(A).name.name){$T,1}\n")
end


function print_axes_summary(io::IO, A::AbstractArray{T,N}, axs::Tuple, dnames::Tuple) where {T,N}
    for i in 1:N
        print(io, " • $(getfield(dnames, i)) - ")
        print(io, getfield(axs, i))
        print(io, "\n")
    end
end

print_meta_summary(io::IO, ::Nothing) = nothing
function print_meta_summary(io::IO, meta)
    print(io, "metadata: ")
    print(io, meta)
    print(io, "\n")
end

function show_array(
    io::IO,
    A::AbstractArray{T,N},
    axs::Tuple=axes(A),
    dnames::Tuple=Interface.default_names(Val(N)),
    meta=metadata(A);
    kwargs...
) where {T,N}

    io_compact = IOContext(io, :compact => true)
    print_axes_summary(io_compact, A, axs, dnames)
    print_meta_summary(io_compact, meta)

    io_has_color = get(io, :color, false)
    buf_io       = IOBuffer()
    buf          = IOContext(buf_io, :color => io_has_color)

    pretty_array(buf, A, axs, dnames; kwargs...)
    print(io, chomp(String(take!(buf_io))))
    return nothing
end

end

