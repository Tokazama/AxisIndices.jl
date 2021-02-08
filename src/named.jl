

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
    return _multi_array_dimnames(AAs, ntuple(_ -> :_, Val(N)))
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

ArrayInterface.parent_type(::Type{<:NamedDimsArray{L,T,N,A}}) where {L,T,N,A} = A

has_dimnames(x) = has_dimnames(typeof(x))
has_dimnames(::Type{T}) where {T<:NamedDimsArray} = true
function has_dimnames(::Type{T}) where {T}
    if parent_type(T) <: T
        return false
    else
        return has_dimnames(parent_type(T))
    end
end
function Metadata.attach_metadata(data::NamedDimsArray, m::Metadata.METADATA_TYPES)
    return NamedDimsArray{dimnames(data)}(attach_metadata(parent(data), m))
end

"""
    NamedAxisArray(parent::AbstractArray; kwargs...) = NamedAxisArray(parent, kwargs)
    NamedAxisArray(parent::AbstractArray, axes::NamedTuple{L,AbstractAxes})

Type alias for `NamedDimsArray` whose parent array is an `AxisArray`. If key word
arguments are provided then each key word becomes the name of a dimension and its
assigned value is sent to the corresponding axis when constructing the underlying
`AxisArray`.

## Examples
```jldoctest
julia> using AxisIndices

julia> A = NamedAxisArray{(:x, :y, :z)}(reshape(1:24, 2, 3, 4), ["a", "b"], ["one", "two", "three"], 2:5)
2×3×4 NamedDimsArray(AxisArray(reshape(::UnitRange{Int64}, 2, 3, 4)
  • axes:
     x = ["a", "b"]
     y = ["one", "two", "three"]
     z = 2:5
))
[:, :, 2] =
       "one"   "two"   "three"
  "a"  1       3       5
  "b"  2       4       6

[:, :, 3] =
       "one"   "two"    "three"
  "a"  7        9       11
  "b"  8       10       12

[:, :, 4] =
       "one"    "two"    "three"
  "a"  13       15       17
  "b"  14       16       18

[:, :, 5] =
       "one"    "two"    "three"
  "a"  19       21       23
  "b"  20       22       24

julia> B = A["a", :, :]
3×4 NamedDimsArray(AxisArray(::Matrix{Int64}
  • axes:
     y = ["one", "two", "three"]
     z = 2:5
))
           2  3   4   5
  "one"    1   7  13  19
  "two"    3   9  15  21
  "three"  5  11  17  23

julia> C = B["one",:]
4-element NamedDimsArray(AxisArray(::Vector{Int64}
  • axes:
     z = 2:5
))
     1
  2   1
  3   7
  4  13
  5  19

```
"""
const NamedAxisArray{L,T,N,P,AI} = NamedDimsArray{L,T,N,AxisArray{T,N,P,AI}}

NamedAxisArray{L}(x::AxisArray) where {L} = NamedDimsArray{L}(x)

function NamedAxisArray{L}(x::AbstractArray, axs::Tuple) where {L}
    return NamedAxisArray{L}(AxisArray(x, axs))
end

function NamedAxisArray{L}(x::AbstractArray, args::AbstractVector...) where {L}
    return NamedAxisArray{L}(x, args)
end

function NamedAxisArray(x::AbstractArray, axs::NamedTuple{L}) where {L}
    return NamedAxisArray{L}(x, values(axs))
end

function NamedAxisArray{L,T,N}(init::ArrayInitializer, axs::Tuple) where {L,T,N}
    return NamedAxisArray{L}(AxisArray{T,N}(init, axs))
end

function NamedAxisArray{L,T,N}(init::ArrayInitializer, args::AbstractVector...) where {L,T,N}
    return NamedAxisArray{L,T,N}(init, args)
end

function NamedAxisArray{L,T}(init::ArrayInitializer, axs::Tuple) where {L,T}
    return NamedAxisArray{L}(AxisArray{T}(init, axs))
end

function NamedAxisArray{L,T}(init::ArrayInitializer, args::AbstractVector...) where {L,T}
    return NamedAxisArray{L,T}(init, args)
end

NamedAxisArray(x::AbstractArray; kwargs...) = NamedAxisArray(x, kwargs.data)

for f in (:getindex, :view, :dotview)
    @eval begin
        @propagate_inbounds function Base.$f(A::NamedAxisArray; named_inds...)
            inds = NamedDims.order_named_inds(A; named_inds...)
            return Base.$f(A, inds...)
        end

        @propagate_inbounds function Base.$f(a::NamedAxisArray, raw_inds...)
            inds = to_indices(parent(a), raw_inds)  # checkbounds happens within to_indices
            data = @inbounds(Base.$f(parent(a), inds...))
            data isa AbstractArray || return data # Case of scalar output
            L = NamedDims.remaining_dimnames_from_indexing(dimnames(a), inds)
            if L === ()
                # Cases that merge dimensions down to vector like `mat[mat .> 0]`,
                # and also zero-dimensional `view(mat, 1,1)`
                return data
            else
                return NamedDimsArray{L}(data)
            end
        end
    end
end

Base.getindex(A::NamedAxisArray, ::Ellipsis) = A

const ReinterpretNamedAxisArray{T,N,S,L,A<:NamedAxisArray{L,S,N}} = ReinterpretArray{T,N,S,A}

function Base.axes(A::ReinterpretNamedAxisArray{T,N,S}) where {T,N,S}
    paxs = axes(parent(A))
    axis_1 = first(paxs)
    len = div(length(axis_1) * sizeof(S), sizeof(T))
    return tuple(StaticRanges.resize_last(axis_1, len), tail(paxs)...)
end

function Base.BroadcastStyle(a::AxisArrayStyle{A}, b::NamedDims.NamedDimsStyle{B}) where {A,B}
    return NamedDims.NamedDimsStyle(a, B())
end
function Base.BroadcastStyle(a::NamedDims.NamedDimsStyle{M}, b::AxisArrayStyle{B}) where {B,M}
    return NamedDims.NamedDimsStyle(M(), b)
end

function Base.show(io::IO, ::MIME"text/plain", X::NamedDimsArray{<:Any,<:Any,<:Any,<:Union{<:AxisArray,Metadata.MetaArray}})
    if isempty(X) && (get(io, :compact, false) || X isa Vector)
        return show(io, X)
    end
    # 0) show summary before setting :compact
    summary(io, X)
    isempty(X) && return
    Base.show_circular(io, X) && return

    # 1) compute new IOContext
    if !haskey(io, :compact) && length(axes(X, 2)) > 1
        io = IOContext(io, :compact => true)
    end
    if get(io, :limit, false) && eltype(X) === Method
        # override usual show method for Vector{Method}: don't abbreviate long lists
        io = IOContext(io, :limit => false)
    end

    if get(io, :limit, false) && displaysize(io)[1]-4 <= 0
        return print(io, " …")
    else
        println(io)
    end

    # 2) update typeinfo
    #
    # it must come after printing the summary, which can exploit :typeinfo itself
    # (e.g. views)
    # we assume this function is always called from top-level, i.e. that it's not nested
    # within another "show" method; hence we always print the summary, without
    # checking for current :typeinfo (this could be changed in the future)
    io = IOContext(io, :typeinfo => eltype(X))

    # 2) show actual content
    recur_io = IOContext(io, :SHOWN_SET => X)
    Base.print_array(recur_io, parent(X))
end
function Base.summary(io::IO, x::NamedDimsArray{<:Any,<:Any,<:Any,<:Union{<:AxisArray,Metadata.MetaArray}})
    return Base.showarg(io, x, true)
end

function Base.showarg(io::IO, x::NamedDimsArray{<:Any,<:Any,<:Any,<:AxisArray}, toplevel)
    if toplevel
        print(io, Base.dims2string(length.(axes(x))), " ")
    end

    print(io, "NamedDimsArray(")
    print(io, "AxisArray(")
    Base.showarg(io, parent(parent(x)), false)
    print(io, "\n")
    print_axes_summary(io, NamedTuple{dimnames(x)}(axes(x)))
    print(io, "\n))")
end

function Base.showarg(io::IO, x::NamedDimsArray{<:Any,<:Any,<:Any,<:Metadata.MetaArray}, toplevel)
    if toplevel
        print(io, Base.dims2string(length.(axes(x))), " ")
    end
    print(io, "NamedDimsArray(")
    print(io, "attach_metadata(")

    if parent_type(parent_type(x)) <: AxisArray
        print(io, "AxisArray(")
        Base.showarg(io, parent(parent(parent(x))), false)
        print(io, "\n")
        print_axes_summary(io, NamedTuple{dimnames(x)}(axes(x)))
        print(io, "\n)")
    else
        Base.showarg(io, parent(x), false)
    end
    print(io, ", ", Metadata.showarg_metadata(x))
    println(io)
    Metadata.metadata_summary(io, x)
    print(io, "\n)") # closing bracket on attach_metadata
    print(io, ")")   # closing bracket on NamedDimsArray
end

