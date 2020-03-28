
function Base.unsafe_convert(::Type{Ptr{T}}, x::AbstractAxisIndices{T}) where {T}
    return Base.unsafe_convert(Ptr{T}, parent(x))
end

function Base.read!(io::IO, a::AbstractAxisIndices)
    read!(io, parent(a))
    return a
end

Base.write(io::IO, a::AbstractAxisIndices) = write(io, parent(a))

