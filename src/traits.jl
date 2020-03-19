
# this is necessary for when we get to the head to_index(::ToIndexStyle, ::AbstractAxis, inds)
# `inds` needs to be a function but we don't know if it's a single element (==) or a collection (in)
# Of course, if the user provides a function as input to the indexing in the first place this
# isn't an issue at all.
is_collection(::Type{T}) where {T} = false
is_collection(::Type{T}) where {T<:F2Eq} = false
is_collection(::Type{T}) where {T<:Function} = true
is_collection(::Type{T}) where {T<:AbstractArray} = true
is_collection(::Type{T}) where {T<:Tuple} = true
is_collection(::Type{T}) where {T<:AbstractDict} = true

"""
    is_key_type(::T) -> Bool

Returns `true` if `T` is always considered a key for indexing. Only `CartesianIndex`
and subtypes of `Real` return `false`.
"""
is_key_type(::Type{<:Function}) = true
is_key_type(::Type{<:CartesianIndex}) = false
is_key_type(::Type{<:Integer}) = false
function is_key_type(::Type{T}) where {T}
    if is_collection(T)
        return is_key_type(eltype(T))
    else
        return true
    end
end

"""
    CombineStyle

Abstract type that determines the behavior of `broadcast_axis`, `cat_axis`, `append_axis!`.
"""
abstract type CombineStyle end

"""
    CombineAxis

Subtype of `CombineStyle` that informs relevant methods to produce a subtype of `AbstractAxis`.
"""
struct CombineAxis <: CombineStyle end

"""
    CombineSimpleAxis

Subtype of `CombineStyle` that informs relevant methods to produce a subtype of `AbstractSimpleAxis`.
"""
struct CombineSimpleAxis <: CombineStyle end

"""
    CombineResize

Subtype of `CombineStyle` that informs relevant methods that axes should be combined by
resizing a collection (as opposed to by concatenation or appending).
"""
struct CombineResize <: CombineStyle end

"""
    CombineStack

Subtype of `CombineStyle` that informs relevant methods that axes should be combined by
stacking elements in some whay (as opposed to resizing a collection).
"""
struct CombineStack <: CombineStyle end

CombineStyle(x, y) = CombineStyle(CombineStyle(x), CombineStyle(y))
CombineStyle(::T) where {T} = CombineStyle(T)
CombineStyle(::Type{T}) where {T} = CombineStack() # default
CombineStyle(::Type{T}) where {T<:AbstractAxis} = CombineAxis()
CombineStyle(::Type{T}) where {T<:AbstractSimpleAxis} = CombineSimpleAxis()
CombineStyle(::Type{T}) where {T<:AbstractRange} = CombineResize()
CombineStyle(::Type{T}) where {T<:LinearIndices{1}} = CombineResize()  # b/c it really is OneTo{Int}

CombineStyle(::CombineAxis, ::CombineStyle) = CombineAxis()
CombineStyle(::CombineStyle, ::CombineAxis) = CombineAxis()
CombineStyle(::CombineAxis, ::CombineAxis) = CombineAxis()
CombineStyle(::CombineSimpleAxis, ::CombineAxis) = CombineAxis()
CombineStyle(::CombineAxis, ::CombineSimpleAxis) = CombineAxis()

CombineStyle(::CombineSimpleAxis, ::CombineStyle) = CombineSimpleAxis()
CombineStyle(::CombineStyle, ::CombineSimpleAxis) = CombineSimpleAxis()
CombineStyle(::CombineSimpleAxis, ::CombineSimpleAxis) = CombineSimpleAxis()

CombineStyle(x::CombineStyle, y::CombineStyle) = x

abstract type ToIndexStyle end

"""
    ToKeysCollection()

Calling `to_index(::ToKeysCollection, axis, inds) -> newinds` results in:
1. Identifying the positions of `keys(axis)` that equal `inds`
2. Retreiving the `values(axis)` that correspond to the identified positions.
3. Attempt to reconstruct the axis type (e.g., `Axis` or `SimpleAxis`) with the relevant keys and values. This is only possible if `newinds isa AbstractUnitRange{Integer}` is `true`
"""
struct ToKeysCollection <: ToIndexStyle end

"""
    ToKeysElement()

Calling `to_index(::ToIndicesCollection, axis, inds) -> newinds` results in:
1. Identifying the position of `key(axis)` that equal `inds`.
2. Return the element of `values(axis)` that corresponds to the identified position.
"""
struct ToKeysElement <: ToIndexStyle end

"""
    ToIndicesCollection()

Calling `to_index(::ToIndicesCollection, axis, inds) -> newinds` results in:
1. Identifying the positions of `values(axis)` that equal `inds`
2. Attempt to reconstruct the axis type (e.g., `Axis` or `SimpleAxis`) with the relevant keys and values. This is only possible if `newinds isa AbstractUnitRange{Integer}` is `true`
"""
struct ToIndicesCollection <: ToIndexStyle end

"""
    ToIndicesElement()

Calling `to_index(::ToIndicesCollection, axis, inds) -> newinds` results in:
1. Identifying the position of `values(axis)` that equal `inds`.
2. Return the element of `values(axis)` that corresponds to the identified position.
"""
struct ToIndicesElement <: ToIndexStyle end

const ToCollection = Union{ToKeysCollection,ToIndicesCollection}
const ToElement = Union{ToKeysElement,ToIndicesElement}

const ToKeys = Union{ToKeysCollection,ToKeysElement}
const ToIndices = Union{ToIndicesCollection,ToIndicesElement}

"""
    ToIndexStyle

`ToIndexStyle` specifies how `to_index(axis, inds)` should convert a provided
argument indices into the native indexing of structure. `ToIndexStyle(typeof(axis), tyepof(inds))`
determines whether [`ToKeysCollection`](@ref), [`ToKeysElement`](@ref), [`ToIndicesCollection`](@ref),
or [`ToIndicesElement`](@ref) is returned.
"""
@inline function ToIndexStyle(::Type{A}, ::Type{I}) where {A,I}
    if is_collection(I)
        if is_key_type(I)
            return ToKeysCollection()
        else
            return ToIndicesCollection()
        end
    else
        if is_key_type(I)
            return ToKeysElement()
        else
            return ToIndicesElement()
        end
    end
end


# ensure that everything goes through an initial search step
check_for_function(::ToCollection, x::Function) = x
check_for_function(::ToCollection, x) = in(x)

check_for_function(::ToElement, x::Function) = x
check_for_function(::ToElement, x) = isequal(x)

# retrieve values or keys
keys_or_values(::ToKeys) = keys
keys_or_values(::ToIndices) = values

# choose find_all or find_first filter function
choose_filter(::ToCollection) = find_all
choose_filter(::ToElement) = find_first

