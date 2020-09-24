
"""
    Axis(k[, v=OneTo(length(k))])

Subtypes of `AbstractAxis` that maps keys to values. The first argument specifies
the keys and the second specifies the values. If only one argument is specified
then the values span from 1 to the length of `k`.

## Examples

The value for all of these is the same.
```jldoctest axis_examples
julia> using AxisIndices

julia> x = Axis(2.0:11.0, 1:10)
Axis(2.0:1.0:11.0 => 1:10)

julia> y = Axis(2.0:11.0)  # when only one argument is specified assume it's the keys
Axis(2.0:1.0:11.0 => Base.OneTo(10))

julia> z = Axis(1:10)
Axis(1:10 => Base.OneTo(10))
```

Standard indexing returns the same values
```jldoctest axis_examples
julia> x[2]
2

julia> x[2] == y[2] == z[2]
true

julia> x[1:2]
Axis(2.0:1.0:3.0 => 1:2)

julia> y[1:2]
Axis(2.0:1.0:3.0 => 1:2)

julia> z[1:2]
Axis(1:2 => 1:2)

julia> x[1:2] == y[1:2] == z[1:2]
true
```

Functions that return `true` or `false` may be used to search the keys for their
corresponding index. The following is equivalent to the previous example.
```jldoctest axis_examples
julia> x[==(3.0)]
2

julia> x[==(3.0)] ==       # 3.0 is the 2nd key of x
       y[isequal(3.0)] ==  # 3.0 is the 2nd key of y
       z[==(2)]            # 2 is the 2nd key of z
true

julia> x[<(4.0)]  # all keys less than 4.0 are 2.0:3.0 which correspond to values 1:2
Axis(2.0:1.0:3.0 => 1:2)

julia> y[<=(3.0)]  # all keys less than or equal to 3.0 are 2.0:3.0 which correspond to values 1:2
Axis(2.0:1.0:3.0 => 1:2)

julia> z[<(3)]  # all keys less than or equal to 3 are 1:2 which correspond to values 1:2
Axis(1:2 => 1:2)

julia> x[<(4.0)] == y[<=(3.0)] == z[<(3)]
true
```
Notice that `==` returns a single value instead of a collection of all elements
where the key was found to be true. This is because all keys must be unique so
there can only ever be one element returned.
"""
struct Axis{K,I,Ks,Inds<:AbstractUnitRange{I}} <: AbstractAxis{K,I}
    keys::Ks
    parent_indices::Inds

    function Axis{K,I,Ks,Inds}(
        ks::Ks,
        inds::Inds,
        check_unique::Bool=true,
        check_length::Bool=true
    ) where {K,I,Ks<:AbstractVector{K},Inds<:AbstractUnitRange{I}}
        check_unique && check_axis_unique(ks, inds)
        check_length && check_axis_length(ks, inds)
        return new{K,I,Ks,Inds}(ks, inds)
    end

    function Axis{K,V,Ks,Vs}(x::AbstractUnitRange{<:Integer}) where {K,V,Ks,Vs}
        if x isa Ks
            if x isa Vs
                return Axis{K,V,Ks,Vs}(x, x)
            else
                return  Axis{K,V,Ks,Vs}(x, Vs(x))
            end
        else
            if x isa Vs
                return Axis{K,V,Ks,Vs}(Ks(x), x)
            else
                return  Axis{K,V,Ks,Vs}(Ks(x), Vs(x))
            end
        end
    end

    # Axis{K,I}
    function Axis{K,I}() where {K,I}
        return new{K,I,Vector{K},OneToMRange{I}}(Vector{K}(),OneToMRange{I}(0))
    end

    function Axis{K,I,Ks,Inds}(axis::AbstractAxis) where {K,I,Ks,Inds}
        return Axis{K,I,Ks,Inds}(Ks(keys(axis)), Inds(parentindices(axis)), false, false)
    end

    function Axis{K,I,Ks,Inds}(axis::Axis{K,I,Ks,Inds}) where {K,I,Ks,Inds}
        if can_change_size(axis)
            return copy(axis)
        else
            return axis
        end
    end

    function Axis(axis::AbstractAxis)
        if can_change_size(axis)
            return axis
        else
            return copy(axis)
        end
    end

    Axis{K}() where {K} = Axis{K,Int}()

    Axis() = Axis{Any}()

    Axis(x::Pair) = Axis(x.first, x.second)

    function Axis(ks, inds, check_unique::Bool=true, check_length::Bool=true)
        return Axis{eltype(ks),eltype(inds),typeof(ks),typeof(inds)}(ks, inds, check_unique, check_length)
    end

    function Axis(ks, check_unique::Bool=true)
        if can_change_size(ks)
            return Axis(ks, OneToMRange(length(ks)), check_unique, false)
        else
            len = known_length(ks)
            if len isa Nothing
                return return Axis(ks, OneTo(length(ks)), check_unique, false)
            else
                return Axis(ks, OneToSRange(len), false)
            end
        end
    end
end


Base.keys(axis::Axis) = getfield(axis, :keys)

ArrayInterface.parent_type(::Type{T}) where {Inds,T<:Axis{<:Any,<:Any,<:Any,Inds}} = Inds

Base.parentindices(axis::Axis) = getfield(axis, :parent_indices)

"""
    IndexAxis

Index style for mapping keys to an array's parent indices.
"""
struct IndexAxis <: IndexStyle end

@propagate_inbounds function to_index(S::IndexAxis, axis, arg)
    if is_key(axis, arg)
        ks = to_index_keys(axis, drop_marker(arg))
        return @inbounds(to_index(parentindices(axis), ks))
    else
        return to_index(parentindices(axis), arg)
    end
end

@propagate_inbounds function to_index_keys(axis, arg::CartesianIndex{1})
    return to_index_keys(axis, first(arg.I))
end
to_index_keys(axis, arg::Function) = findall(arg, keys(axis))

@propagate_inbounds function to_index_keys(axis, arg)
    if arg isa keytype(axis)
        idx = findfirst(==(arg), keys(axis))
    else
        idx = findfirst(==(keytype(axis)(arg)), keys(axis))
    end
    @boundscheck if idx isa Nothing
        throw(BoundsError(axis, arg))
    end
    return Int(idx)
end

@propagate_inbounds function to_index_keys(axis, arg::Union{<:Equal,Approx})
    idx = findfirst(arg, keys(axis))
    @boundscheck if idx isa Nothing
        throw(BoundsError(axis, arg))
    end
    return Int(idx)
end

@propagate_inbounds function to_index_keys(axis, arg::AbstractVector)
    return map(arg_i -> to_index_keys(axis, arg_i), arg)
    #=
    inds = Vector{Int}(undef, length(arg))
    ks = keys(axis)
    i = 1
    for arg_i in arg
        idx = to_index_key(axis, arg_i)
        @inbounds(setindex!(inds, idx, i))
        i += 1
    end
    return inds
    =#
end

@propagate_inbounds function to_index_keys(axis, arg::AbstractRange)
    if eltype(arg) <: keytype(axis)
        inds = find_all(in(arg), keys(axis))
    else
        inds = find_all(in(AbstractRange{keytype(axis)}(arg)), keys(axis))
    end
    # if `inds` is same length as `arg` then all of `arg` was found and is inbounds
    @boundscheck if length(inds) != length(arg)
        throw(BoundsError(axis, arg))
    end
    return inds
end

Base.IndexStyle(::Type{T}) where {T<:Axis} = IndexAxis()
function unsafe_reconstruct(::IndexAxis, axis, arg, inds)
    if is_key(axis, arg) && (arg isa AbstractVector)
        ks = arg
    else
        ks = @inbounds(getindex(keys(axis), inds))
    end
    return Axis(ks, unsafe_reconstruct(parentindices(axis), arg, inds), false, false)
end

function unsafe_reconstruct(::IndexAxis, axis, inds)
    return Axis(
        @inbounds(getindex(keys(axis), inds)),
        unsafe_reconstruct(parentindices(axis), arg, inds),
        false,
        false
    )
end

