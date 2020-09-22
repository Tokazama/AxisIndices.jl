
"""
    has_dimnames(x) -> Bool

Returns `true` if `x` has names for each dimension.
"""
has_dimnames(::T) where {T} = has_dimnames(T)
has_dimnames(::Type{T}) where {T} = false
has_dimnames(::Type{T}) where {T<:NamedDimsArray} = true
has_dimnames(::Type{Base.ReinterpretArray{T,N,T2,P}}) where {T,N,T2,P} = has_dimnames(P)
has_dimnames(::Type{Base.PermutedDimsArray{T,N,permin,permout,A}}) where {T,N,permin,permout,A} = has_dimnames(A)

has_dimnames(::Type{ReadonlyMappedArray{T,N,A,F}}) where {T,N,A,F} = has_dimnames(A)
has_dimnames(::Type{MappedArray{T,N,A,F,Finv}}) where {T,N,A,F,Finv} = has_dimnames(A)
function has_dimnames(::Type{ReadonlyMultiMappedArray{T,N,AAs,F}}) where {T,N,AAs,F}
    return _multi_array_has_dimnames(AAs)
end
function has_dimnames(::Type{MultiMappedArray{T,N,AAs,F,Finv}}) where {T,N,AAs,F,Finv}
    return _multi_array_has_dimnames(AAs)
end

# FIXME this doesn't account for when there are incompatable names from multiple arrays
@inline function _multi_array_has_dimnames(::Type{T}) where {T}
    for T_i in T.parameters
        has_dimnames(T_i) && return true
    end
    return false
end

"""
    named_axes(A) -> NamedTuple{names}(axes)

Returns a `NamedTuple` where the names are the dimension names and each indice
is the corresponding dimensions's axis. If dimnesion names are not defined for `x`
default names are returned. `x` should have an `axes` method.

```jldoctest
julia> using AxisIndices

julia> A = reshape(1:24, 2,3,4);

julia> named_axes(A)
(dim_1 = Base.OneTo(2), dim_2 = Base.OneTo(3), dim_3 = Base.OneTo(4))

julia> named_axes(NamedAxisArray{(:a, :b, :c)}(A))
(a = SimpleAxis(Base.OneTo(2)), b = SimpleAxis(Base.OneTo(3)), c = SimpleAxis(Base.OneTo(4)))
```
"""
function named_axes(x::AbstractArray{T,N}) where {T,N}
    if has_dimnames(x)
        return NamedTuple{dimnames(x)}(axes(x))
    else
        return NamedTuple{default_names(Val(N))}(axes(x))
    end
end

@generated default_names(::Val{N}) where {N} = :($(ntuple(i -> Symbol(:dim_, i), N)))
