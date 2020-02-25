struct AxisIndicesArray{T,N,P<:AbstractArray{T,N},A<:Tuple{Vararg{<:AbstractAxis,N}}} <: AbstractArray{T,N}
    parent::P
    axes::A

    function AxisIndicesArray{T,N,P,A}(p::P, axs::A, check_length::Bool) where {T,N,P,A}
        if check_length
            for (i, axs_i) in enumerate(axs)
                if size(p, i) != length(axs_i)
                    error("All keys and values must have the same length as the respective axes of the parent array, got size(parent, $i) = $(size(p, i)) and length(key_i) = $(length(axs_i))")
                else
                    continue
                end
            end
        end
        return new{T,N,P,A}(p, axs)
    end
end

parent_type(::T) where {T} = parent_type(T)
parent_type(::Type{<:AxisIndicesArray{T,N,P}}) where {T,N,P} = P

const AxisIndicesMatrix{T,P<:AbstractMatrix{T},A1,A2} = AxisIndicesArray{T,2,P,Tuple{A1,A2}}

const AxisIndicesVector{T,P<:AbstractVector{T},A1} = AxisIndicesArray{T,1,P,Tuple{A1}}

Base.parent(x::AxisIndicesArray) = getfield(x, :parent)

Base.axes(x::AxisIndicesArray) = getfield(x, :axes)

Base.axes(x::AxisIndicesArray, i) = axes(x)[i]

Base.size(x::AxisIndicesArray, i) = length(axes(x, i))

Base.size(x::AxisIndicesArray) = map(length, axes(x))

Base.length(x::AxisIndicesArray) = prod(size(x))

Base.parentindices(x::AxisIndicesArray) = axes(parent(x))

function AxisIndicesArray(x::AbstractArray{T,N}, axs::Tuple=axes(x), check_length::Bool=true) where {T,N}
    axs = map(to_axis, axs)
    return AxisIndicesArray{T,N,typeof(x),typeof(axs)}(x, axs, check_length)
end

#function AxisIndicesArray{T,N,X}(x::X, axs::A, check_length::Bool=true) where {T,N,X,A}
#    return AxisIndicesArray{T,N,X,A}(x, axs, check_length)
#end

###
### Indexixng
###

#=

function to_axis(x::AbstractArray{T,N}, axs::Tuple) where {T,N}
    if is_static(x)
        return as_static.(axs)
    elseif is_fixed(x)
        return as_fixed.(axs)
    else
        return as_dynamic.(axs)
    end
end

=#

@propagate_inbounds function Base.setindex!(a::AxisIndicesArray, value, inds...)
    return setindex!(parent(a), value, to_indices(a, axes(a), inds)...)
end

for f in (:getindex, :view, :dotview)
    _f = Symbol(:_, f)
    @eval begin
        @propagate_inbounds function Base.$f(a::AxisIndicesArray, inds...)
            return $_f(a, to_indices(a, axes(a), inds)...)
        end

        @propagate_inbounds function $_f(a::AxisIndicesArray, inds::Vararg{<:Integer})
            return Base.$f(parent(a), inds...)
        end

        @propagate_inbounds function $_f(a::AxisIndicesArray, ci::CartesianIndex)
            return Base.$f(parent(a), ci)
        end

        @propagate_inbounds function $_f(a::AxisIndicesArray, inds...)
            return AxisIndicesArray(Base.$f(parent(a), inds...), reindex(axes(a), inds))
        end
    end
end
function Base.similar(
    a::AxisIndicesArray{T},
    eltype::Type=T,
    dims::Tuple{Vararg{Int}}=size(a)
   ) where {T}
    return AxisIndicesArray(similar(parent(a), eltype, ))
end

function Base.similar(
    a::AxisIndicesArray{T},
    inds::Tuple{Vararg{<:AbstractVector,N}}
   ) where {T,N}
    return AxisIndicesArray(similar(parent(a), T, map(length, inds)), inds)
end

function Base.similar(
    a::AxisIndicesArray{T},
    eltype::Type,
    inds::Tuple{Vararg{<:AbstractVector,N}}
   ) where {T,N}
    return AxisIndicesArray(similar(parent(a), eltype, map(length, inds)), inds)
end
