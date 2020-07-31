
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
    return NamedMetaAxisArray{NamedAxes.default_names(Val(N))}(A; metadata=metadata, kwargs...)
end

function NamedMetaAxisArray(A::AbstractArray, args::AbstractVector...; metadata=nothing, kwargs...)
    return NamedMetaAxisArray(A, args; metadata=metadata, kwargs...)
end

function NamedMetaAxisArray(A::AbstractArray{T,N}, axs::Tuple; metadata=nothing, kwargs...) where {T,N}
    return NamedMetaAxisArray{NamedAxes.default_names(Val(N))}(A, axs; metadata=metadata, kwargs...)
end

function NamedMetaAxisArray(A::AbstractArray, axs::NamedTuple{L}; metadata=nothing, kwargs...) where {L}
    return NamedMetaAxisArray{L}(A, values(axs); metadata=metadata, kwargs...)
end

Base.getproperty(A::NamedMetaAxisArray, k::Symbol) = metaproperty(A, k)

Base.setproperty!(A::NamedMetaAxisArray, k::Symbol, val) = metaproperty!(A, k, val)

for f in (:getindex, :view, :dotview)
    @eval begin
        @propagate_inbounds function Base.$f(A::NamedMetaAxisArray; named_inds...)
            inds = NamedDims.order_named_inds(A; named_inds...)
            return Base.$f(A, inds...)
        end

        @propagate_inbounds function Base.$f(a::NamedMetaAxisArray, raw_inds...)
            inds = Interface.to_indices(parent(a), raw_inds)  # checkbounds happens within to_indices
            data = @inbounds(Base.$f(parent(a), inds...))
            data isa AbstractArray || return data # Case of scalar output
            L = NamedDims.remaining_dimnames_from_indexing(dimnames(a), inds)
            if L === ()
                # Cases that merge dimensions down to vector like `mat[mat .> 0]`,
                # and also zero-dimensional `view(mat, 1,1)`
                return data
            else
                return NamedDimsArray{L}(data)
            end
        end
    end
end

Base.getindex(A::NamedMetaAxisArray, ::Ellipsis) = A

