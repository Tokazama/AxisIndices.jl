
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

#= TODO get rid of or develop these further

    name_format = Symbol(name, :_format)
    name_format_doc = """
        $name_format(x, default)

    Returns the appropriate `DataFormat` for $name.
    """

    to_name_format = Symbol(:to_, name, :_format)
    to_name_format_doc = """
        $to_name_format(dst, src [, default=getdim_error])

    Returns $name data from `src` in a format that is compatible with `dst`.
    `default` refers to a default dimension if data from `dst` or `src` requires
    data in an array format but doesn't specify dimension that corresponds to $name.
    """

=#

# I have to abuse @pure here to get type inference to propagate to the axes methods
# So `condition` also has to be pure, which shouldn't be hard because it should basically
# just be comparing symbols

macro def_naxis(name, name_dim)
    nname = Symbol(:n, name)
    nname_doc = """
        $nname(x) -> Int

    Returns the size along the dimension corresponding to the $name.
    """

    esc(quote
        @doc $nname_doc
        @inline $nname(x) = Base.size(x, $name_dim(x))
    end)
end


macro def_axis_keys(name, name_dims)
    name_keys = Symbol(name, :_keys)
    name_keys_doc = """
        $name_keys(x)

    Returns the keys corresponding to the $name axis
    """
    esc(quote
        @doc $name_keys_doc
        @inline $name_keys(x) = keys(axes(x, $name_dims(x)))
    end)
end



macro def_axis_indices(name, name_dim)
    name_indices = Symbol(name, :_indices)
    name_indices_doc = """
        $name_indices(x)

    Returns the indices corresponding to the $name axis
    """
    esc(quote
        @doc $name_indices_doc
        @inline $name_indices(x) = indices(axes(x, $name_dim(x)))
    end)
end


# TODO I'm not sure this is the best name for this one
macro def_axis_type(name, name_dim)
    name_type = Symbol(name, :_axis_type)
    name_type_doc = """
        $name_type(x)

    Returns the key type corresponding to the $name axis.
    """

    esc(quote
        @doc $name_type_doc
        @inline $name_type(x) = keytype(axes(x, $name_dim(x)))
    end)
end

macro def_selectdim(name, name_dim)
    name_selectdim = Symbol(:select_, name, :dim)
    name_selectdim_doc = """
        $name_selectdim(x, i)

    Return a view of all the data of `x` where the index for the $name dimension equals `i`.
    """

    esc(quote
        @doc $name_selectdim_doc
        @inline $name_selectdim(x, i) = selectdim(x, $name_dim(x), i)

    end)
end

macro def_eachslice(name, name_dim)
    each_name = Symbol(:each_, name)
    each_name_doc = """
        $each_name(x)

    Create a generator that iterates over the $name dimensions `A`, returning views that select
    all the data from the other dimensions in `A`.
    """
    esc(quote
        @doc $each_name_doc
        @inline $each_name(x) = eachslice(x, dims=$name_dim(x))
    end)
end

"""
    @defdim name condition

Produces a series of methods for conveniently manipulating dimensions with
specific names. `condition` is a method that returns `true` or `false` when
given a name of a  dimension. For example, the following would produce methods
for manipulating and accessing dimensions with the name `:time`.

```julia
julia> is_time(x::Symbol) = x === :time

julia> @defdim time is_time

```

`name` is used to complete the following method names

* `name_dim(x)`: returns the dimension number of dimension
* `nname(x)`: returns the number of elements stored along the dimension
* `has_name_dim(x)`: returns `true` or `false`, indicating if the dimension is present
* `name_axis(x)`: returns the axis corresponding to the dimension.
* `name_indices(x)`: returns the indices corresponding to the dimension.
* `name_keys(x)`: returns the keys corresponding to the dimension
* `name_axis_type(x)`: returns the type of the axis corresponding to the dimension
* `select_name_dim(x, i)`: equivalent to `selectdim(x, name_dim(x), i)`
* `each_name(x)`: equivalent to `eachslice(x, name_dim(x))`

!!! warning
    `@defdim` should be considered experimental and subject to change

"""
macro defdim(
    name,
    condition,
    def_naxis::Bool=true,
    def_axis_keys::Bool=true,
    def_axis_indices::Bool=true,
    def_axis_type::Bool=true,
    def_selectdim::Bool=true,
    def_eachslice::Bool=true,
)

    dim_noerror_name = Symbol(:dim_noerror_, name)

    name_dim = Symbol(name, :dim)
    name_dim_doc = """
        $name_dim(x) -> Int

    Returns the dimension corresponding to $name.
    """

    has_name_dim = Symbol(:has_, name, :dim)
    has_name_dim_doc = """
        $has_name_dim(x) -> Bool

    Returns `true` if `x` has a dimension corresponding to $name.
    """

    name_axis = Symbol(name, :_axis)
    name_axis_doc = """
        $name_axis(x)

    Returns the axis corresponding to the $name dimension.
    """

    name_axis_itr = """
        $name_axis(x, size[; first_pad=nothing, last_pad=nothing, stride=nothing, dilation=nothing])

    Returns an `AxisIterator` along the $name axis.
    """

    err_msg = "Method $(Symbol(condition)) is not true for any dimensions of "

    esc(quote
        Base.@pure function $dim_noerror_name(x::Tuple{Vararg{Symbol,N}}) where {N}
            for i in Base.OneTo(N)
                $condition(getfield(x, i)) && return i
            end
            return 0
        end

        @doc $name_dim_doc
        @inline function $name_dim(x)
            d = $dim_noerror_name(dimnames(x))
            if d === 0
                throw(ArgumentError($err_msg * repr(x)))
            else
                return d
            end
        end

        @doc $has_name_dim_doc
        @inline $has_name_dim(x) = !($dim_noerror_name(dimnames(x)) === 0)

        @doc $name_axis_doc
        @inline $name_axis(x) = axes(x, $name_dim(x))

        @doc $name_axis_itr
        @inline $name_axis(x, sz; kwargs...) = AxisIterator(axes(x, $name_dim(x)), sz; kwargs...)

        if $def_naxis
            Interface.@def_naxis($name, $name_dim)
        end

        if $def_axis_keys
            Interface.@def_axis_keys($name, $name_dim)
        end

        if $def_axis_indices
            Interface.@def_axis_indices($name, $name_dim)
        end

        if $def_axis_type
            Interface.@def_axis_type($name, $name_dim)
        end

        if $def_selectdim
            Interface.@def_selectdim($name, $name_dim)
        end

        if $def_eachslice
            Interface.@def_eachslice($name, $name_dim)
        end

        nothing
    end)
end

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
