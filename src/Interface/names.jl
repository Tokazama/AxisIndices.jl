
"""
    has_dimnames(x) -> Bool

Returns `true` if `x` has names for each dimension.
"""
has_dimnames(::T) where {T} = has_dimnames(T)
has_dimnames(::Type{T}) where {T} = false
has_dimnames(::Type{T}) where {T<:NamedDimsArray} = true

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
macro defdim(name, condition)

    dim_noerror_name = Symbol(:dim_noerror_, name)

    name_dim = Symbol(name, :dim)
    name_dim_doc = """
        $name_dim(x) -> Int

    Returns the dimension corresponding to the $name.
    """

    nname = Symbol(:n, name)
    nname_doc = """
        $nname(x) -> Int

    Returns the size along the dimension corresponding to the $name.
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

    name_indices = Symbol(name, :_indices)
    name_indices_doc = """
        $name_indices(x)

    Returns the indices corresponding to the $name axis
    """

    name_keys = Symbol(name, :_keys)
    name_keys_doc = """
        $name_keys(x)

    Returns the keys corresponding to the $name axis
    """

    name_type = Symbol(name, :_axis_type)
    name_type_doc = """
        $name_type(x)

    Returns the key type corresponding to the $name axis.
    """

    name_selectdim = Symbol(:select_, name, :dim)
    name_selectdim_doc = """
        $name_selectdim(x, i)

    Return a view of all the data of `x` where the index for the $name dimension equals `i`.
    """

    each_name = Symbol(:each_, name)
    each_name_doc = """
        $each_name(x)

    Create a generator that iterates over the $name dimensions `A`, returning views that select
    all the data from the other dimensions in `A`.
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

        @doc $nname_doc
        @inline $nname(x) = Base.size(x, $name_dim(x))

        @doc $has_name_dim_doc
        @inline $has_name_dim(x) = !($dim_noerror_name(dimnames(x)) === 0)

        @doc $name_axis_doc
        @inline $name_axis(x) = axes(x, $name_dim(x))

        @doc $name_keys_doc
        @inline $name_keys(x) = keys($name_axis(x))

        @doc $name_indices_doc
        @inline $name_indices(x) = values($name_axis(x))

        @doc $name_type_doc
        @inline $name_type(x) = keytype($name_axis(x))

        @doc $name_selectdim_doc
        @inline $name_selectdim(x, i) = selectdim(x, $name_dim(x), i)

        @doc $each_name_doc
        @inline $each_name(x) = eachslice(x, dims=$name_dim(x))

        nothing
    end)
end

