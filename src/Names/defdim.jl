
function getdim_error(x, condition::Symbol)
    throw(ArgumentError("Specified name ($(repr(condition))) does not match any dimension names for $(repr(x)))"))
end

function getdim_error(x, condition::Function)
    throw(ArgumentError("Method $(Symbol(condition)) is not true for any dimensions of $(repr(x)))"))
end

# I have to abuse @pure here to get type inference to propagate to the axes methods
# So `condition` also has to be pure, which shouldn't be hard because it should basically
# just be comparing symbols
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

    name_selectdim = Symbol(:select_, name, :dim)
    name_selectdim_doc = """
        $name_selectdim(x, i)

    Return `x` view of all the data of `x` where the index for the $name dimension equals `i`.
    """

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
                AxisIndices.Names.getdim_error(x, $condition)
            else
                return d
            end
        end

        @doc $nname_doc
        $nname(x) = Base.size(x, $name_dim(x))

        @doc $has_name_dim_doc
        $has_name_dim(x) = !($dim_noerror_name(dimnames(x)) === 0)

        @doc $name_axis_doc
        $name_axis(x) = axes(x, $name_dim(x))

        @doc $name_keys_doc
        $name_keys(x) = keys($name_axis(x))

        @doc $name_indices_doc
        $name_indices(x) = values($name_axis(x))

        @doc $name_type_doc
        $name_type(x) = keytype($name_axis(x))

        @doc $name_selectdim_doc
        $name_selectdim(x, i) = selectdim(x, $name_dim(x), i)

        nothing
    end)
end

