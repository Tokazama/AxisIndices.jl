
abstract type IndexerStyle end

# returns collection
struct ToCollection <: IndexerStyle end
const to_collection = ToCollection()

# returns element
struct ToElement <: IndexerStyle end
const to_element = ToElement()

IndexerStyle(::T) where {T} = IndexerStyle(T)
IndexerStyle(s::IndexerStyle) = s
IndexerStyle(::Type{T}) where {T} = to_element
IndexerStyle(::Type{T}) where {T<:F2Eq} = to_element
IndexerStyle(::Type{T}) where {T<:CartesianIndex} = to_element
IndexerStyle(::Type{T}) where {T<:Function} = to_collection
IndexerStyle(::Type{T}) where {T<:AbstractArray} = to_collection
IndexerStyle(::Type{T}) where {T<:Interval} = to_collection
IndexerStyle(::Type{T}) where {T<:AbstractDict} = to_collection
IndexerStyle(::Type{T}) where {T<:AbstractSet} = to_collection
IndexerStyle(::Type{T}) where {T<:Tuple} = to_collection
# FIXME This bit has all sorts of stuff that scares me
# 1. This isn't in Compat.jl yet so I can't just depend on it.
# 2. Compat dependencies often give me errors when updating packages
# 3. An anonymous function has a name based on its place in code, therefore we
#    have to derive the name programmatically because it can change between
#    versions of Julia
if length(methods(isapprox, Tuple{Any})) == 0
    Base.isapprox(y; kwargs...) = x -> isapprox(x, y; kwargs...)
end
const IsApproxFix = typeof(isapprox(Any)).name.wrapper
IndexerStyle(::Type{T}) where {T<:IsApproxFix} = ToElement()

# unkown indexer styles are propagated so that if it's not properly implemented
# an error is eventually thrown
IndexerStyle(x, y) = IndexerStyle(IndexerStyle(x), IndexerStyle(y))
IndexerStyle(x::ToElement,    y::ToElement   ) = to_element
IndexerStyle(x::ToCollection, y::ToCollection) = to_collection
IndexerStyle(x::ToElement,    y::ToCollection) = to_collection
IndexerStyle(x::ToCollection, y::ToElement   ) = IndexerStyle(y, x)
IndexerStyle(x::IndexerStyle, y::ToCollection) = x
IndexerStyle(x::IndexerStyle, y::ToElement   ) = x
IndexerStyle(x::ToCollection, y::IndexerStyle) = y
IndexerStyle(x::ToElement,    y::IndexerStyle) = y

# FIXME yes, this abuses @pure but I couldn't get it to work any other way
combine(::T) where {T} = _combine(T)
Base.@pure function _combine(::Type{T}) where {T <: Tuple}
    out = to_element
    for i in T.parameters
        out = IndexerStyle(out, i)
    end
    return out
end

#@inline combine(x::Tuple{T}) where {T} = IndexerStyle(T)
#@inline combine(x::Tuple{T,Vararg{Any}}) where {T} = IndexerStyle(IndexerStyle(T), tail(x))

