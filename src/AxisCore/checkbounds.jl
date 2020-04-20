
Base.checkbounds(x::AbstractAxis, i) = checkbounds(Bool, x, i)

@inline Base.checkbounds(::Type{Bool}, a::AbstractAxis, i) = checkindex(Bool, a, i)

@inline function Base.checkbounds(::Type{Bool}, a::AbstractAxis, i::CartesianIndex{1})
    return checkindex(Bool, a, first(i.I))
end

@inline function Base.checkindex(::Type{Bool}, a::AbstractAxis, i::Integer)
    return StaticRanges.checkindexlo(a, i) & StaticRanges.checkindexhi(a, i)
end

@inline function Base.checkindex(::Type{Bool}, a::AbstractAxis, i::AbstractVector)
    return StaticRanges.checkindexlo(a, i) & StaticRanges.checkindexhi(a, i)
end

@inline function Base.checkindex(::Type{Bool}, a::AbstractAxis, i::AbstractUnitRange)
    return StaticRanges.checkindexlo(a, i) & StaticRanges.checkindexhi(a, i) 
end

@inline function Base.checkindex(::Type{Bool}, x::AbstractAxis, I::Base.Slice)
    return checkindex(Bool, values(x), I)
end

@inline function Base.checkindex(::Type{Bool}, x::AbstractAxis, I::AbstractRange)
    return checkindex(Bool, values(x), I)
end

@inline function Base.checkindex(::Type{Bool}, x::AbstractAxis, I::AbstractVector{Bool})
    return checkindex(Bool, values(x), I)
end

@inline function Base.checkindex(::Type{Bool}, x::AbstractAxis, I::Base.LogicalIndex)
    return checkindex(Bool, values(x), I)
end

