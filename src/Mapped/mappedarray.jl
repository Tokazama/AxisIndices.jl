

# We can't just make a type alias for mapped array types because this would require
# multiple calls to combine_axes for multi-mapped types for every axes call. It also
# would require overloading a bunch of other methods to ensure they work correctly
# (e.g., getindex, setindex!, view, show, etc...)
#
# We can't directly overload the head of each method because data::AbstractArray....
# is too similar to Union{AbstractAxisIndices,AbstractArray} so we only specialize
# on method heads that handle all AbstractAxisIndices subtypes. Therefore, including
# any other array type will miss these specific methods.

function MappedArrays.mappedarray(f, data::AbstractAxisIndices)
    return unsafe_reconstruct(data, mappedarray(f, parent(data)), axes(data))
end

function MappedArrays.mappedarray(::Type{T}, data::AbstractAxisIndices) where T
    return unsafe_reconstruct(data, mappedarray(T, parent(data)), axes(data))
end

function MappedArrays.mappedarray(f, data::AbstractAxisIndices...)
    return AxisIndicesArray(
        mappedarray(f, map(unwrap_broadcasted, data)...),
        Broadcast.combine_axes(data...)
    )
end

function MappedArrays.mappedarray(::Type{T}, data::AbstractAxisIndices...) where T
    return AxisIndicesArray(
        mappedarray(T, map(unwrap_broadcasted, data)...),
        Broadcast.combine_axes(data...)
    )
end

# These needed to have the additional ::Function defined to avoid ambiguities
function MappedArrays.mappedarray(f, finv::Function, data::AbstractAxisIndices)
    return unsafe_reconstruct(data, mappedarray(f, finv, parent(data)), axes(data))
end

function MappedArrays.mappedarray(f, finv::Function, data::AbstractAxisIndices...)
    return AxisIndicesArray(
        mappedarray(f, finv, map(unwrap_broadcasted, data)...),
        Broadcast.combine_axes(data...)
    )
end

function MappedArrays.mappedarray(::Type{T}, finv::Function, data::AbstractAxisIndices...) where T
    return AxisIndicesArray(
        mappedarray(T, finv, map(unwrap_broadcasted, data)...),
        Broadcast.combine_axes(data...)
    )
end

function MappedArrays.mappedarray(f, ::Type{Finv}, data::AbstractAxisIndices...) where Finv
    return AxisIndicesArray(
        mappedarray(f, Finv, map(unwrap_broadcasted, data)...),
        Broadcast.combine_axes(data...)
    )
end

function MappedArrays.mappedarray(::Type{T}, ::Type{Finv}, data::AbstractAxisIndices...) where {T,Finv}
    return AxisIndicesArray(
        mappedarray(T, Finv, map(unwrap_broadcasted, data)...),
        Broadcast.combine_axes(data...)
    )
end
