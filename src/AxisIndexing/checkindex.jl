
Base.checkbounds(x::AbstractAxis, i) = checkbounds(Bool, x, i)

Base.checkbounds(::Type{Bool}, a::AbstractAxis, i) = checkindex(Bool, a, i)

function Base.checkbounds(::Type{Bool}, a::AbstractAxis, i::CartesianIndex{1})
    return checkindex(Bool, a, first(i.I))
end

function Base.checkindex(::Type{Bool}, a::AbstractAxis, i::Integer)
    return checkindexlo(a, i) & checkindexhi(a, i)
end

function Base.checkindex(::Type{Bool}, a::AbstractAxis, i::AbstractVector)
    return checkindexlo(a, i) & checkindexhi(a, i)
end

function Base.checkindex(::Type{Bool}, a::AbstractAxis, i::AbstractUnitRange)
    return checkindexlo(a, i) & checkindexhi(a, i) 
end

function Base.checkindex(::Type{Bool}, x::AbstractAxis, I::Base.Slice)
    return checkindex(Bool, values(x), I)
end

function Base.checkindex(::Type{Bool}, x::AbstractAxis, I::AbstractRange)
    return checkindex(Bool, values(x), I)
end

function Base.checkindex(::Type{Bool}, x::AbstractAxis, I::AbstractVector{Bool})
    return checkindex(Bool, values(x), I)
end

function Base.checkindex(::Type{Bool}, x::AbstractAxis, I::Base.LogicalIndex)
    return checkindex(Bool, values(x), I)
end

