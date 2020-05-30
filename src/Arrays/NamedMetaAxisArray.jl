
"""
    NamedMetaAxisArray

An AxisArray with metadata and named dimensions.
"""
const NamedMetaAxisArray{L,T,N,Ax,M,P<:AbstractAxisArray{T,N,Ax}} = NamedDimsArray{L,T,N,MetadataArray{T,N,M,P}}


# NamedMetaAxisArray{L,T,N}
function NamedMetaAxisArray{L,T,N}(init::ArrayInitializer, args::AbstractVector...; metadata=nothing, kwargs...) where {L,T,N}
    return NamedMetaAxisArray{L}(MetaAxisArray{T,N}(init, args; metadata=metadata, kwargs...))
end

function NamedMetaAxisArray{L,T,N}(init::ArrayInitializer, axs::Tuple; metadata=nothing, kwargs...) where {L,T,N}
    return NamedMetaAxisArray{L}(MetaAxisArray{T,N}(init, axs; metadata=metadata, kwargs...))
end

# NamedMetaAxisArray{L,T}
function NamedMetaAxisArray{L,T}(init::ArrayInitializer, args::AbstractVector...; metadata=nothing, kwargs...) where {L,T}
    return NamedMetaAxisArray{L}(MetaAxisArray{T}(init, args; metadata=metadata, kwargs...))
end

function NamedMetaAxisArray{L,T}(init::ArrayInitializer, axs::Tuple; metadata=nothing, kwargs...) where {L,T}
    return NamedMetaAxisArray{L}(MetaAxisArray{T}(init, axs; metadata=metadata, kwargs...))
end

# NamedMetaAxisArray{L}
function NamedMetaAxisArray{L}(A::AbstractArray; metadata=nothing, kwargs...) where {L}
    return NamedDimsArray{L}(MetaAxisArray(A; metadata=metadata, kwargs...))
end

function NamedMetaAxisArray{L}(A::AbstractArray, args::AbstractVector...; metadata=nothing, kwargs...) where {L}
    return NamedDimsArray{L}(MetaAxisArray(A, args; metadata=metadata, kwargs...))
end

function NamedMetaAxisArray{L}(A::AbstractArray, axs::Tuple; metadata=nothing, kwargs...) where {L}
    return NamedDimsArray{L}(MetaAxisArray(A, axs; metadata=metadata, kwargs...))
end

NamedMetaAxisArray{L}(A::MetaAxisArray) where {L} = NamedDimsArray{L}(A)

# NamedMetaAxisArray
function NamedMetaAxisArray(A::AbstractArray{T,N}; metadata=nothing, kwargs...) where {T,N}
    return NamedMetaAxisArray{Interface.default_names(Val(N))}(A; metadata=metadata, kwargs...)
end

function NamedMetaAxisArray(A::AbstractArray, args::AbstractVector...; metadata=nothing, kwargs...)
    return NamedMetaAxisArray(A, args; metadata=metadata, kwargs...)
end

function NamedMetaAxisArray(A::AbstractArray{T,N}, axs::Tuple; metadata=nothing, kwargs...) where {T,N}
    return NamedMetaAxisArray{Interface.default_names(Val(N))}(A, axs; metadata=metadata, kwargs...)
end

function NamedMetaAxisArray(A::AbstractArray, axs::NamedTuple{L}; metadata=nothing, kwargs...) where {L}
    return NamedMetaAxisArray{L}(A, values(axs); metadata=metadata, kwargs...)
end
Base.show(io::IO, A::NamedMetaAxisArray; kwargs...) = show(io, MIME"text/plain"(), A; kwargs...)

function Base.show(io::IO, m::MIME"text/plain", A::NamedMetaAxisArray{T,N}; kwargs...) where {T,N}
    if N == 1
        print(io, join(size(A), "×"))
    else
        print(io, "$(length(A))-element")
    end
    print(io, " NamedMetaAxisArray{$T,$N}\n")
    PrettyArrays.print_array_summary(io, A)
    return show_array(io, parent(parent(A)), axes(A); kwargs...)
end
