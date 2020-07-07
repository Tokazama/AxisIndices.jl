
for f in (:map, :map!)
    # Here f::F where {F} is needed to avoid ambiguities in Julia 1.0
    @eval begin
        function Base.$f(f::F, a::AbstractArray, b::AbstractAxisArray, cs::AbstractArray...) where {F}
            return unsafe_reconstruct(
                b,
                $f(f, parent(a), parent(b), parent.(cs)...),
                Broadcast.combine_axes(a, b, cs...,)
            )
        end

        function Base.$f(f::F, a::AbstractAxisArray, b::AbstractAxisArray, cs::AbstractArray...) where {F}
            return unsafe_reconstruct(
                b,
                $f(f, parent(a), parent(b), parent.(cs)...),
                Broadcast.combine_axes(a, b, cs...,)
            )
        end

        function Base.$f(f::F, a::AbstractAxisArray, b::AbstractArray, cs::AbstractArray...) where {F}
            return unsafe_reconstruct(
                a,
                $f(f, parent(a), parent(b), parent.(cs)...),
                Broadcast.combine_axes(a, b, cs...,)
            )
        end

        function Base.$f(f::F, a::NamedDimsArray, b::AbstractAxisArray, cs::AbstractArray...) where {F}
            data = Base.$f(f, unname(a), unname(b), unname.(cs)...)
            new_names = unify_names(dimnames(a), dimnames(b), dimnames.(cs)...)
            return NamedDimsArray(data, new_names)
        end

        function Base.$f(f::F, a::AbstractAxisArray, b::NamedDimsArray, cs::AbstractArray...) where {F}
            data = Base.$f(f, unname(a), unname(b), unname.(cs)...)
            new_names = unify_names(dimnames(a), dimnames(b), dimnames.(cs)...)
            return NamedDimsArray(data, new_names)
        end
    end
end
function Base.map(f::F, a::StaticArray, b::AbstractAxisArray, cs::AbstractArray...) where {F}
    return unsafe_reconstruct(
        b,
        map(f, a, parent(b), parent.(cs)...),
        Broadcast.combine_axes(a, b, cs...,)
    )
end

function Base.map(f::F, a::AbstractAxisArray, b::StaticArray, cs::AbstractArray...) where {F}
    return unsafe_reconstruct(
        b,
        map(f, parent(a), b, parent.(cs)...),
        Broadcast.combine_axes(a, b, cs...,)
    )
end

Base.map(f, A::AbstractAxisArray) = unsafe_reconstruct(A, map(f, parent(A)), axes(A))

# We can't just make a type alias for mapped array types because this would require
# multiple calls to combine_axes for multi-mapped types for every axes call. It also
# would require overloading a bunch of other methods to ensure they work correctly
# (e.g., getindex, setindex!, view, show, etc...)
#
# We can't directly overload the head of each method because data::AbstractArray....
# is too similar to Union{AbstractAxisArray,AbstractArray} so we only specialize
# on method heads that handle all AbstractAxisArray subtypes. Therefore, including
# any other array type will miss these specific methods.

function MappedArrays.mappedarray(f, data::AbstractAxisArray)
    return unsafe_reconstruct(data, mappedarray(f, parent(data)), axes(data))
end

function MappedArrays.mappedarray(::Type{T}, data::AbstractAxisArray) where T
    return unsafe_reconstruct(data, mappedarray(T, parent(data)), axes(data))
end

function MappedArrays.mappedarray(f, data::AbstractAxisArray...)
    return AxisArray(
        mappedarray(f, map(unwrap_broadcasted, data)...),
        Broadcast.combine_axes(data...)
    )
end

function MappedArrays.mappedarray(::Type{T}, data::AbstractAxisArray...) where T
    return AxisArray(
        mappedarray(T, map(unwrap_broadcasted, data)...),
        Broadcast.combine_axes(data...)
    )
end

# These needed to have the additional ::Function defined to avoid ambiguities
function MappedArrays.mappedarray(f, finv::Function, data::AbstractAxisArray)
    return unsafe_reconstruct(data, mappedarray(f, finv, parent(data)), axes(data))
end

function MappedArrays.mappedarray(f, finv::Function, data::AbstractAxisArray...)
    return AxisArray(
        mappedarray(f, finv, map(unwrap_broadcasted, data)...),
        Broadcast.combine_axes(data...)
    )
end

function MappedArrays.mappedarray(::Type{T}, finv::Function, data::AbstractAxisArray...) where T
    return AxisArray(
        mappedarray(T, finv, map(unwrap_broadcasted, data)...),
        Broadcast.combine_axes(data...)
    )
end

function MappedArrays.mappedarray(f, ::Type{Finv}, data::AbstractAxisArray...) where Finv
    return AxisArray(
        mappedarray(f, Finv, map(unwrap_broadcasted, data)...),
        Broadcast.combine_axes(data...)
    )
end

function MappedArrays.mappedarray(::Type{T}, ::Type{Finv}, data::AbstractAxisArray...) where {T,Finv}
    return AxisArray(
        mappedarray(T, Finv, map(unwrap_broadcasted, data)...),
        Broadcast.combine_axes(data...)
    )
end
