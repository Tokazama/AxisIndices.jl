
module PrettyArrays

using AxisIndices.Interface
using AxisIndices.Axes
using AxisIndices.Arrays
using AxisIndices.Metadata


using PrettyTables
using Base: tail

import NamedDims: NamedDimsArray
import MetadataArrays: MetadataArray

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
    print(io, "metadata: $(summary(meta))")
    print(io, "\n")
    print(io, " • $meta")
    print(io, "\n")
end

function show_array(
    io::IO,
    A::AbstractArray{T,N};
    axes::Tuple=axes(A),
    dimnames::Tuple=Interface.default_names(Val(N)),
    metadata=metadata(A),
    kwargs...
) where {T,N}

    io_compact = IOContext(io, :compact => true)
    print_axes_summary(io_compact, A, axes, dimnames)
    print_meta_summary(io_compact, metadata)

    io_has_color = get(io, :color, false)
    buf_io       = IOBuffer()
    buf          = IOContext(buf_io, :color => io_has_color)

    pretty_array(buf, A, axes, dimnames; kwargs...)
    print(io, chomp(String(take!(buf_io))))
    return nothing
end

function show_array(io::IO, A::NamedDimsArray; kwargs...)
    return show_array(io, parent(A); dimnames=dimnames(A), kwargs...)
end

function show_array(io::IO, A::MetadataArray; kwargs...)
    return show_array(io, parent(A); metadata=metadata(A), kwargs...)
end

function show_array(io::IO, A::AbstractAxisArray; kwargs...)
    return show_array(io, parent(A); axes=axes(A), kwargs...)
end



macro assign_show(T)
    print_name = QuoteNode(T)
    esc(quote
        Base.show(io::IO, A::$T; kwargs...) = show(io, MIME"text/plain"(), A, kwargs...)
        function Base.show(io::IO, m::MIME"text/plain", A::$T; kwargs...)
            N = ndims(A)
            if N == 1
                print(io, "$(length(A))-element")
            else
                print(io, join(size(A), "×"))
            end
            print(io, " " * string($print_name) * "{$(eltype(A)),$N}\n")
            return PrettyArrays.show_array(io, A; kwargs...)
        end
    end)
end


end

