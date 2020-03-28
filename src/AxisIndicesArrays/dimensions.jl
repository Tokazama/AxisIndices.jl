
# These are base module methods that simply need to swap/drop axes positions
function Base.permutedims(a::AbstractAxisIndices, perm)
    return unsafe_reconstruct(a, permutedims(parent(a), perm), permute_axes(a, perm))
end

#Base.selectdim(a::AbstractAxisIndices, d::Integer, i) = selectdim(a, d, i)

const CoVector = Union{Adjoint{<:Any, <:AbstractVector}, Transpose{<:Any, <:AbstractVector}}

for f in (
    :(Base.transpose),
    :(Base.adjoint),
    :(Base.permutedims),
    :(LinearAlgebra.pinv))
    # Vector
    @eval function $f(a::AbstractAxisIndices{T,1}) where {T}
        return unsafe_reconstruct(a, $f(parent(a)), permute_axes(a))
    end

    # Vector Double Transpose
    if f != :(Base.permutedims)
        # TODO fix CoVector
        @eval function $f(a::AbstractAxisIndices{T,2,A}) where {T,A<:CoVector}
            return unsafe_reconstruct(a, $f(parent(a)), (axes(a, 2),))
        end
    end

    # Matrix
    @eval function $f(a::AbstractAxisIndices{T,2}) where {T}
        return unsafe_reconstruct(a, $f(parent(a)), permute_axes(a))
    end
end

function Base.dropdims(a::AxisIndicesArray; dims)
    return unsafe_reconstruct(a, dropdims(parent(a); dims=dims), drop_axes(a, dims))
end

# reshape
# For now we only implement the version that drops dimension names
# TODO
#Base.reshape(ia::AbstractAxisIndices, d::Vararg{Union{Colon, Int}}) = reshape(parent(ia), d)

