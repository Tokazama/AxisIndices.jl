
"""
    Axis(k[, v=OneTo(length(k))])

Subtypes of `AbstractAxis` that maps keys to values. The first argument specifies
the keys and the second specifies the values. If only one argument is specified
then the values span from 1 to the length of `k`.

## Examples

The value for all of these is the same.
```jldoctest axis_examples
julia> using AxisIndices

julia> x = Axis(2.0:11.0)  # when only one argument is specified assume it's the keys
Axis(2.0:1.0:11.0 => SimpleAxis(1:10))

julia> y = Axis(1:10)
Axis(1:10 => SimpleAxis(1:10))
```

Standard indexing returns the same values
```jldoctest axis_examples
julia> x[2]
2

julia> x[2] == y[2]
true

julia> x[1:2]
Axis(2.0:1.0:3.0 => SimpleAxis(1:2))

julia> y[1:2]
Axis(1:2 => SimpleAxis(1:2))

julia> x[1:2] == y[1:2]
true
```

Functions that return `true` or `false` may be used to search the keys for their
corresponding index. The following is equivalent to the previous example.
```julia
julia> x[==(3.0)]
2

julia> x[3.0] ==  # 3.0 is the 2nd key of x
       y[==(2)]   # 2 is the 2nd key of z
true

julia> x[<(4.0)]  # all keys less than 4.0 are 2.0:3.0 which correspond to values 1:2
Axis(2.0:1.0:3.0 => SimpleAxis(1:2))

julia> y[<=(3.0)]  # all keys less than or equal to 3.0 are 2.0:3.0 which correspond to values 1:2
Axis(2.0:1.0:3.0 => SimpleAxis(1:2))

julia> z[<(3)]  # all keys less than or equal to 3 are 1:2 which correspond to values 1:2
Axis(1:2 => SimpleAxis(1:2))

julia> x[<(4.0)] == y[<=(3.0)] == z[<(3)]
true
```
Notice that `==` returns a single value instead of a collection of all elements
where the key was found to be true. This is because all keys must be unique so
there can only ever be one element returned.
"""
struct Axis{K,I,Ks,Inds<:AbstractUnitRange{I}} <: AbstractAxis{I,Inds}
    keys::Ks
    parent::Inds

    function Axis{K,I,Ks,Inds}(
        ks::Ks,
        inds::Inds;
        checks=AxisArrayChecks()
    ) where {K,I,Ks<:AbstractVector{K},Inds<:AbstractUnitRange{I}}
        check_axis_length(ks, inds, checks)
        check_unique_keys(ks, checks)
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

    function Axis{K,I,Ks,Inds}(axis::SimpleAxis) where {K,I,Ks,Inds}
        return new{K,I,Ks,Inds}(axis, axis)
    end

    function Axis{K,I,Ks,Inds}(axis::AbstractAxis) where {K,I,Ks,Inds}
        return new{K,I,Ks,Inds}(Ks(keys(axis)), Inds(parent(axis)))
    end

    function Axis{K,I,Ks,Inds}(axis::Axis{K,I,Ks,Inds}) where {K,I,Ks,Inds}
        if can_change_size(axis)
            return copy(axis)
        else
            return axis
        end
    end

    # Axis{K,I}
    function Axis{K,I}() where {K,I}
        ks = Vector{K}()
        inds = SimpleAxis()
        return new{K,I,typeof(ks),typeof(inds)}()
    end

    function Axis{K,I}(ks::AbstractVector; checks=AxisArrayChecks, kwargs...) where {K,I}
        c = checked_axis_lengths(checks)
        if can_change_size(ks)
            return Axis{K,I}(ks, SimpleAxis(OneToMRange{I}(length(ks))); checks=c, kwargs...)
        else
            return Axis{K,I}(ks, compose_axis(indices(ks), NoChecks); checks=c, kwargs...)
        end
    end
    function Axis{K,I}(ks::AbstractVector, inds::AbstractAxis; kwargs...) where {K,I}
        if eltype(ks) <: K
            if eltype(inds) <: I
                return Axis{K,I,typeof(ks),typeof(inds)}(ks, inds; kwargs...)
            else
                return Axis{K,I}(ks, AbstractUnitRange{I}(inds); kwargs...)
            end
        else
            return Axis{K,I}(AbstractVector{K}(ks), inds; kwargs...)
        end
    end
    function Axis{K,I}(ks::AbstractVector, inds::AbstractUnitRange; kwargs...) where {K,I}
        return Axis{K,I}(ks, compose_axis(inds, NoChecks); kwargs...)
    end

    # Axis
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

    function Axis(ks::AbstractVector, inds::AbstractAxis; kwargs...)
        return Axis{eltype(ks),eltype(inds),typeof(ks),typeof(inds)}(ks, inds; kwargs...)
    end

    function Axis(ks::AbstractVector, inds::AbstractUnitRange; kwargs...)
        return Axis(ks, compose_axis(inds, NoChecks); kwargs...)
    end

    function Axis(ks::AbstractVector; checks=AxisArrayChecks(), kwargs...)
        c = checked_axis_lengths(checks)
        if can_change_size(ks)
            return Axis(ks, SimpleAxis(OneToMRange(length(ks))); checks=c)
        else
            return Axis(ks, compose_axis(static_first(eachindex(ks)):static_length(ks), NoChecks); checks=c)
        end
    end
end

## interface
Base.keys(axis::Axis) = getfield(axis, :keys)
@inline Base.getproperty(axis::Axis, k::Symbol) = getproperty(parent(axis), k)

function ArrayInterface.unsafe_reconstruct(axis::Axis{K,I,Ks,Inds}, inds; keys=nothing, kwargs...) where {K,I,Ks,Inds}
    if keys === nothing
        ks = Base.keys(axis)
        p = parent(axis)
        kindex = firstindex(ks)
        pindex = first(p)
        if kindex === pindex
            return Axis(
                @inbounds(ks[inds]),
               inds;
               checks=NoChecks
            )
        else
            return Axis(@inbounds(ks[inds .+ (pindex - kindex)]), inds; checks=NoChecks)
            #=
        else
            f = (offsets(parent(axis), 1) - offsets(ks, 1))
            ks = ks[(first(inds) - f):(last(inds) - f)]
            return Axis(ks, unsafe_reconstruct(parent(axis), inds); checks=NoChecks)
            =#
        end
    else
        return Axis(keys, inds; checks=NoChecks)
    end
end

## other stuff
function StaticRanges.set_last!(axis::Axis, val)
    can_set_last(axis) || throw(MethodError(set_last!, (axis, val)))
    set_last!(parent(axis), val)
    resize_last!(keys(axis), length(parent(axis)))
    return axis
end

function StaticRanges.set_last(axis::Axis, val)
    vs = set_last(parent(axis), val)
    return unsafe_reconstruct(axis, resize_last(keys(axis), length(vs)); keys=vs)
end

function StaticRanges.set_first(axis::Axis, val)
    vs = set_first(parent(axis), val)
    return unsafe_reconstruct(axis, vs; keys=resize_first(keys(axis), length(vs)))
end

function StaticRanges.set_first!(axis::Axis, val)
    can_set_first(axis) || throw(MethodError(set_first!, (axis, val)))
    set_first!(parent(axis), val)
    resize_first!(keys(axis), length(parent(axis)))
    return axis
end

function maybe_unsafe_reconstruct(axis::Axis, inds::AbstractUnitRange{I}; keys=nothing) where {I<:Integer}
    if keys === nothing
        return unsafe_reconstruct(axis, SimpleAxis(inds); keys=@inbounds(Base.keys(axis)[inds]))
    else
        return unsafe_reconstruct(axis, SimpleAxis(inds); keys=keys)
    end
end
function maybe_unsafe_reconstruct(axis::Axis, inds::AbstractArray)
    if keys === nothing
        axs = (unsafe_reconstruct(axis, SimpleAxis(eachindex(inds))),)
    elseif allunique(inds)
        axs = (unsafe_reconstruct(axis, SimpleAxis(eachindex(inds)); keys=@inbounds(keys(axis)[inds])),)
    else  # not all indices are unique so will result in non-unique keys
        axs = (SimpleAxis(eachindex(inds)),)
    end
    return AxisArray{eltype(axis),ndims(inds),typeof(inds),typeof(axs)}(inds, axs)
end

@inline function Base.length(axis::Axis{K,I,Ks,Inds}) where {K,I,Ks,Inds}
    if known_length(Ks) === nothing
        return length(parent(axis))
    else
        return known_length(Ks)
    end
end

function StaticRanges.set_length!(axis::Axis, len)
    can_set_length(axis) || error("Cannot use set_length! for instances of typeof $(typeof(axis)).")
    set_length!(parent(axis), len)
    set_length!(keys(axis), len)
    return axis
end

function StaticRanges.set_length(axis::Axis, len)
    return unsafe_reconstruct(
        axis,
        set_length(parent(axis), len);
        keys=set_length(keys(axis), len)
    )
end

for f in (:grow_last!, :grow_first!, :shrink_last!, :shrink_first!)
    @eval begin
        function StaticRanges.$f(axis::Axis, n::Integer)
            can_set_length(axis) ||  throw(MethodError($f, (axis, n)))
            StaticRanges.$f(keys(axis), n)
            StaticRanges.$f(parent(axis), n)
            return axis
        end
    end
end

for f in (:grow_last, :grow_first, :shrink_last, :shrink_first, :resize_first, :resize_last)
    @eval begin
        @inline function StaticRanges.$f(axis::Axis, n::Integer)
            return unsafe_reconstruct(
                axis,
                StaticRanges.$f(parent(axis), n);
                keys = StaticRanges.$f(keys(axis), n)
            )
        end

    end
end

@inline function StaticRanges.shrink_last(axis::Axis, n::AbstractUnitRange{<:Integer})
    return unsafe_reconstruct(axis, n; keys=shrink_last(keys(axis), length(axis) - length(n)))
end
@inline function StaticRanges.shrink_first(axis::Axis, n::AbstractUnitRange{<:Integer})
    return unsafe_reconstruct(axis, n; keys=shrink_first(keys(axis), length(axis) - length(n)))
end
function StaticRanges.grow_last(axis::Axis, n::AbstractUnitRange{<:Integer})
    return unsafe_reconstruct(axis, n; keys=grow_last(keys(axis), length(n) - length(axis)),)
end
function StaticRanges.grow_first(axis::Axis, n::AbstractUnitRange{<:Integer})
    return unsafe_reconstruct(axis, n;keys=grow_first(keys(axis), length(n) - length(axis)))
end
function StaticRanges.resize_last(axis::Axis, n::AbstractUnitRange{<:Integer})
    return unsafe_reconstruct(axis, n; keys=resize_last(keys(axis), length(n)))
end
function StaticRanges.resize_first(axis::Axis, n::AbstractUnitRange{<:Integer})
    return unsafe_reconstruct(axis, n; keys=resize_first(keys(axis), length(n)))
end

function Base.pop!(axis::Axis)
    can_set_last(axis) || throw(MethodError(pop!, axis))
    pop!(keys(axis))
    return pop!(parent(axis))
end

function Base.popfirst!(axis::Axis)
    can_set_last(axis) || throw(MethodError(pop!, axis))
    popfirst!(keys(axis))
    return popfirst!(parent(axis))
end

function push_key!(axis::Axis, key)
    push!(keys(axis), key)
    grow_last!(parent(axis), 1)
    return nothing
end

function popfirst_axis!(axis::Axis)
    if StaticRanges.can_set_first(axis)
        StaticRanges.shrink_first!(keys(axis), 1)
    else
        shrink_last!(keys(axis), 1)
    end
    shrink_last!(parent(axis), 1)
    return nothing
end

_keys_type(::Type{T}) where {Ks,T<:Axis{<:Any,<:Any,Ks,<:Any}} = Ks

Base.keytype(::Type{T}) where {K,I,T<:Axis{K,I}} = K
function StaticRanges.can_set_length(::Type{T}) where {K,I,Ks,Inds,T<:Axis{K,I,Ks,Inds}}
    return can_set_length(Ks) & can_set_length(Inds)
end
function StaticRanges.can_set_last(::Type{T}) where {K,I,Ks,Inds,T<:Axis{K,I,Ks,Inds}}
    return can_set_last(Ks) & can_set_last(Inds)
end
function StaticRanges.can_set_first(::Type{T}) where {K,I,Ks,Inds,T<:Axis{K,I,Ks,Inds}}
    return can_set_first(Ks) & can_set_first(Inds)
end

@propagate_inbounds function Base.getindex(axis::Axis, arg::AbstractUnitRange{I}) where {I<:Integer}
    @boundscheck checkbounds(axis, arg)
    ks = Base.keys(axis)
    p = parent(axis)
    kindex = firstindex(ks)
    pindex = first(p)
    if kindex === pindex
        return Axis(
            @inbounds(ks[arg]),
            @inbounds(getindex(p, arg));
            checks=NoChecks
        )
    else
        return Axis(
            @inbounds(ks[arg .+ (kindex - pindex)]),
            @inbounds(getindex(p, arg));
            checks=NoChecks
        )
    end
end

print_axis(io::IO, axis::Axis) = print(io, "Axis($(keys(axis)) => $(parent(axis)))")

