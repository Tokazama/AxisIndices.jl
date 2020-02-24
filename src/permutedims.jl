
function Base.dropdims(ia::AxisIndicesArray; dims)
    return AxisIndicesArray(dropdims(parent(ia); dims=dims), drop_axes(ia, dims))
end

function Base.permutedims(a::AxisIndicesArray, perm)
    return AxisIndicesArray(permutedims(parent(a), perm), permute_axes(a, perm))
end

#Base.selectdim(a::AxisIndicesArray, d::Integer, i) = selectdim(a, d, i)

for f in (
    :(Base.transpose),
    :(Base.adjoint),
    :(Base.permutedims),
    :(LinearAlgebra.pinv))
    # Vector
    @eval function $f(v::AxisIndicesVector)
        return AxisIndicesArray($f(parent(v)), permute_axes(v))
    end

    # Vector Double Transpose
    if f != :(Base.permutedims)
        # TODO fix CoVector
        @eval function $f(a::AxisIndicesMatrix{T,A}) where {L,T,A<:CoVector}
            return AxisIndicesArray($f(parent(a)), (axes(a, 2),))
        end
    end

    # Matrix
    @eval function $f(a::AxisIndicesMatrix)
        return AxisIndicesArray($f(parent(a)), permute_axes(a))
    end
end


# reshape
# For now we only implement the version that drops dimension names
# TODO
#Base.reshape(ia::AxisIndicesArray, d::Vararg{Union{Colon, Int}}) = reshape(parent(ia), d)
