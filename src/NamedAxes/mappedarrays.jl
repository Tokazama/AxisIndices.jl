###
### mappedarray
###
function MappedArrays.mappedarray(f, data::NamedDimsArray{L}) where {L}
    return NamedDimsArray{L}(mappedarray(f, parent(data)))
end

function MappedArrays.mappedarray(::Type{T}, data::NamedDimsArray{L}) where {T,L}
    return NamedDimsArray{L}(mappedarray(T, parent(data)))
end

function MappedArrays.mappedarray(f, data::NamedDimsArray...)
    dn = _unify_names(map(dimnames, data))
    return NamedDimsArray{dn}(mappedarray(f, map(parent, data)...))
end

function MappedArrays.mappedarray(::Type{T}, data::NamedDimsArray...) where T
    dn = _unify_names(map(dimnames, data))
    return NamedDimsArray{dn}(mappedarray(T, map(parent, data)...))
end

function MappedArrays.mappedarray(f, finv::Function, data::NamedDimsArray{L}) where {L}
    return NamedDimsArray{L}(mappedarray(f, parent(data)))
end

function MappedArrays.mappedarray(f, finv::Function, data::NamedDimsArray...)
    dn = _unify_names(map(dimnames, data))
    return NamedDimsArray{dn}(mappedarray(f, finv, map(parent, data)...))
end

function MappedArrays.mappedarray(::Type{T}, finv::Function, data::NamedDimsArray...) where T
    dn = _unify_names(map(dimnames, data))
    return NamedDimsArray{dn}(mappedarray(T, finv, map(parent, data)...))
end

function MappedArrays.mappedarray(f, ::Type{Finv}, data::NamedDimsArray...) where Finv
    dn = _unify_names(map(dimnames, data))
    return NamedDimsArray{dn}(mappedarray(f, Finv, map(parent, data)...))
end

function MappedArrays.mappedarray(::Type{T}, ::Type{Finv}, data::NamedDimsArray...) where {T,Finv}
    dn = _unify_names(map(dimnames, data))
    return NamedDimsArray{dn}(mappedarray(T, Finv, map(parent, data)...))
end

_unify_names(x::Tuple{Any}) = first(x)
function _unify_names(x::Tuple{Any,Vararg{Any}})
    return NamedDims.unify_names_longest(first(x), _unify_names(tail(x)))
end

