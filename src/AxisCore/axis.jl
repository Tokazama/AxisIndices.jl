
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
struct Axis{K,V,Ks,Vs<:AbstractUnitRange{V}} <: AbstractAxis{K,V,Ks,Vs}
    keys::Ks
    values::Vs

    function Axis{K,V,Ks,Vs}(ks::Ks, vs::Vs, check_unique::Bool=true, check_length::Bool=true) where {K,V,Ks,Vs}
        if check_unique
            allunique(ks) || error("All keys must be unique.")
            allunique(vs) || error("All values must be unique.")
        end

        if check_length
            length(ks) == length(vs) || error("Length of keys and values must be equal, got length(keys) = $(length(ks)) and length(values) = $(length(vs)).")
        end

        eltype(Ks) <: K || error("keytype of keys and keytype do no match, got $(eltype(Ks)) and $K")
        eltype(Vs) <: V || error("valtype of values and valtype do no match, got $(eltype(Vs)) and $V")
        return new{K,V,Ks,Vs}(ks, vs)
    end
end

function Axis(ks, vs, check_unique::Bool=true, check_length::Bool=true)
    if is_static(vs)
        return _axis(as_static(ks), as_static(vs), check_unique, check_length)
    elseif is_fixed(vs)
        return _axis(as_fixed(ks), as_fixed(vs), check_unique, check_length)
    else  # is_dynamic
        return _axis(as_dynamic(ks), as_dynamic(vs), check_unique, check_length)
    end
    return 
end

function _axis(ks, vs, check_unique, check_length)
    return Axis{eltype(ks),eltype(vs),typeof(ks),typeof(vs)}(ks, vs, check_unique, check_length)
end

function Axis(ks, check_unique::Bool=true)
    if is_static(ks)
        return Axis(ks, OneToSRange(length(ks)), check_unique, false)
    elseif is_fixed(ks)
        return Axis(ks, OneTo(length(ks)), check_unique, false)
    else  # is_dynamic
        return Axis(ks, OneToMRange(length(ks)), check_unique, false)
    end
end

Axis(x::Pair) = Axis(x.first, x.second)

Axis(a::AbstractAxis{K,V,Ks,Vs}) where {K,V,Ks,Vs} = Axis{K,V,Ks,Vs}(keys(a), values(a))

Axis{K,V,Ks,Vs}(a::AbstractAxis) where {K,V,Ks,Vs} = Axis{K,V,Ks,Vs}(Ks(keys(a)), Vs(values(a)))

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

# interface
Base.keys(a::Axis) = getfield(a, :keys)

Base.values(a::Axis) = getfield(a, :values)

function StaticRanges.similar_type(
    ::Type{A},
    ks_type::Type=keys_type(A),
    vs_type::Type=values_type(A)
) where {A<:Axis}

    return Axis{eltype(ks_type),eltype(vs_type),ks_type,vs_type}
end

function unsafe_reconstruct(a::Axis, ks::Ks, vs::Vs) where {Ks,Vs}
    return similar_type(a, Ks, Vs)(ks, vs, false, false)
end

