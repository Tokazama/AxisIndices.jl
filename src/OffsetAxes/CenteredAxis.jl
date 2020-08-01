# TODO Mutating methods on CenteredAxis need to be specialize to ensure the center
# is maintained

"""
    CenteredAxis(indices)

A `CenteredAxis` takes `indices` and provides a user facing set of keys centered around zero.
The `CenteredAxis` is a subtype of `AbstractOffsetAxis` and its keys are treated as the predominant indexing style.
Note that the element type of a `CenteredAxis` cannot be unsigned because any instance with a length greater than 1 will begin at a negative value.

## Examples

A `CenteredAxis` sends all indexing arguments to the keys and only maps to the indices when `to_index` is called.
```jldoctest
julia> using AxisIndices

julia> axis = CenteredAxis(1:10)
CenteredAxis(-5:4 => 1:10)

julia> axis[10]  # the indexing goes straight to keys and is centered around zero
ERROR: BoundsError: attempt to access 10-element CenteredAxis(-5:4 => 1:10) at index [10]
[...]

julia> axis[-5]
-5

julia> AxisIndices.to_index(axis, -5)
1

```
"""
struct CenteredAxis{I,Ks,Inds}  <: AbstractOffsetAxis{I,Ks,Inds}
    keys::Ks
    indices::Inds

    function CenteredAxis{I,Ks,Inds}(ks::Ks, inds::Inds, check_length::Bool=true, ensure_centered::Bool=true) where {I,Ks,Inds}
        if ks isa Ks
            if inds isa Inds
                check_length && check_axis_length(ks, inds)
                if ensure_centered && (abs(first(ks)) - abs(last(ks))) > 1  # FIXME this doesn't handle things like 2:2
                    error("keys are not centered around zero.")
                end
                return new{I,Ks,Inds}(ks, inds)
            else
                return CenteredAxis{I}(ks, Inds(inds), check_length, ensure_centered)
            end
        else
            if inds isa Inds
                return CenteredAxis{I}(Ks(ks), inds, check_length, ensure_centered)
            else
                return CenteredAxis{I}(Ks(ks), Inds(inds), check_length, ensure_centered)
            end
        end
    end

    function CenteredAxis{I,Ks,Inds}(inds::AbstractUnitRange) where {I,Ks,Inds}
        len = length(inds)
        start = I(-div(len, 2))
        return CenteredAxis{I,Ks,Inds}(Ks(start, I(start + len - 1)), inds, false, false)
    end

    # CenteredAxis{K,I}
    function CenteredAxis{I}(inds::AbstractUnitRange) where {I}
        if eltype(inds) <: I
            len = length(inds)
            start = I(-div(len, 2))
            stop = I(start + len - 1)
            if is_static(inds)
                ks =  UnitSRange{I}(start, stop)
            elseif is_fixed(inds)
                ks =  UnitRange{I}(start, stop)
            else
                ks =  UnitMRange{I}(start, stop)
            end
            return CenteredAxis{I,typeof(ks),typeof(inds)}(ks, inds, false, false)
        else
            return CenteredAxis{I}(AbstractUnitRange{I}(inds))
        end
    end

    # CenteredAxis
    CenteredAxis(inds::AbstractUnitRange{I}) where {I} = CenteredAxis{I}(inds)
end

Base.keys(axis::CenteredAxis) = getfield(axis, :keys)

Base.values(axis::CenteredAxis) = getfield(axis, :indices)


### centered_start
centered_start(::Type{T}, x::AbstractUnitRange) where {T} = _centered_start_from_len(T, length(x))
_centered_start_from_len(::Type{T}, len) where {T} = T(-div(len, 2))

### centered_stop
@inline function centered_stop(::Type{T}, x::AbstractUnitRange) where {T}
    len = length(x)
    return _centered_stop_from_len_and_start(_centered_start_from_len(T, len), len)
end
_centered_stop_from_len_and_start(start::T, len) where {T} = T(start + len - 1)

function StaticRanges.similar_type(::A, vs_type::Type=indices_type(A)) where {A<:CenteredAxis}
    return similar_type(A, vs_type)
end

function _centered_axis_similar_type(::Type{Ks}, ::Type{Inds}) where {Ks,Inds}
    if Ks <: OneToUnion
        error("CenteredAxis cannot have keys that start at one, got keys of type $Ks")
    else
        return CenteredAxis{eltype(Inds),Ks,Inds}
    end
end

function _centered_axis_similar_type(::Type{OneToSRange{T,L}}) where {T,L}
    start = _centered_start_from_len(T, L)
    return CenteredAxis{T,UnitSRange{T,start,_centered_stop_from_len_and_start(start, L)},OneToSRange{T,L}}
end

function _centered_axis_similar_type(::Type{UnitSRange{T,B,L}}) where {T,B,L}
    len = L - B + 1
    start = _centered_start_from_len(T, len)
    return CenteredAxis{T,UnitSRange{T,start,_centered_stop_from_len_and_start(start, len)},UnitSRange{T,B,L}}
end

function _centered_axis_similar_type(::Type{Inds}) where {Inds}
    I = eltype(Inds)
    return CenteredAxis{I,UnitRange{I},Inds}
end

function StaticRanges.similar_type(
    ::Type{<:CenteredAxis},
    ::Type{Ks},
    ::Type{Inds},
) where {Ks,Inds}

    return _centered_axis_similar_type(Ks, Inds)
end

function StaticRanges.similar_type(::Type{<:CenteredAxis}, ::Type{Ks}) where {Ks}
    return _centered_axis_similar_type(Ks)
end

Interface.unsafe_reconstruct(axis::CenteredAxis, inds) = CenteredAxis{eltype(inds)}(inds)

function _reset_keys!(axis::CenteredAxis{K}) where {K}
    len = length(indices(axis))
    start = K(-div(len, 2))
    stop = K(start + len - 1)
    ks = keys(axis)
    set_first!(ks, start)
    set_last!(ks, stop)
    return nothing
end

"""
    center(inds::AbstractUnitRange{<:Integer}) -> CenteredAxis(inds)

Shortcut for creating [`CenteredAxis`](@ref).

## Examples
```jldoctest
julia> using AxisIndices

julia> AxisArray(ones(3), center)
3-element AxisArray{Float64,1}
 • dim_1 - -1:1

  -1   1.0
   0   1.0
   1   1.0

```
"""
center(inds) = CenteredAxis(inds)
