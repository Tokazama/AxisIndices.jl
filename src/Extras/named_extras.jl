
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

# TODO this should be defined in NamedDims
@inline function NamedDims.dimnames(::Type{Base.PermutedDimsArray{T,N,permin,permout,A}}) where {T,N,permin,permout,A}
    dn = dimnames(A)
    return map(i -> getfield(dn, i), permin)
end
@inline function NamedDims.dimnames(::Type{Base.ReinterpretArray{T,N,S,A}}) where {T,N,S,A}
    return dimnames(A)
end
NamedDims.dimnames(::Type{ReadonlyMappedArray{T,N,A,F}}) where {T,N,A,F} = dimnames(A)
NamedDims.dimnames(::Type{MappedArray{T,N,A,F,Finv}}) where {T,N,A,F,Finv} = dimnames(A)
function NamedDims.dimnames(::Type{ReadonlyMultiMappedArray{T,N,AAs,F}}) where {T,N,AAs,F}
    return _multi_array_dimnames(AAs)
end
function NamedDims.dimnames(::Type{MultiMappedArray{T,N,AAs,F,Finv}}) where {T,N,AAs,F,Finv}
    return _multi_array_dimnames(AAs, ntuple(_ -> :_, Val(N)))
end

@inline function _multi_array_dimnames(::Type{T}, dnames::Tuple{Vararg{Symbol}}) where {T}
    for T_i in T.parameters
        dnames = NamedDims.unify_names_longest(dnames, dimnames(T_i))
    end
    return dnames
end

#=_multi_array_dimnames(::Tuple{T}) where {T} = dimnames(T)
_multi_array_dimnames(::Tuple{T1,T2}) where {T1,T2} = NamedDims.unify_names_longest(dimnames(T1), dimnames(T2))
@inline function _multi_array_dimnames(x::Tuple{T1,T2,Vararg{Any}}) where {T1,T2}
    return NamedDims.unify_names_longest(dimnames(T1), _multi_array_dimnames(tail(x)))
end
=#

