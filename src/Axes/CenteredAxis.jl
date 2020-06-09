# TODO Mutating methods on CenteredAxis need to be specialize to ensure the center
# is maintained

function _construct_centered_keys(::Type{K}, inds) where {K}
    len = length(inds)
    start = K(-div(len, 2))
    stop = K(start + len - 1)
    S = Staticness(inds)
    if is_static(S)
        ks = UnitSRange{K}(start, stop)
    elseif is_fixed(S)
        ks = UnitRange{K}(start, stop)
    else  # is_dynamic(S)
        ks = UnitMRange{K}(start, stop)
    end
end

"""
    CenteredAxis(indices)

Note: the element type of a `CenteredAxis` cannot be unsigned because any instance with
a length greater than 1 will begin at a negative value.
"""
struct CenteredAxis{K,I,Ks,Inds}  <: AbstractOffsetAxis{K,I,Ks,Inds}
    keys::Ks
    indices::Inds

    function CenteredAxis{K,I,Ks,Inds}(ks::Ks, inds::Inds, check_length::Bool=true, ensure_centered::Bool=true) where {K,I,Ks,Inds}
        check_length && check_axis_length(ks, inds)
        if ensure_centered && (abs(first(ks)) - abs(last(ks))) > 1  # FIXME this doesn't handle things like 2:2
            error("keys are not centered around zero.")
        end

        return new{K,I,Ks,Inds}(ks, inds)
    end

    function CenteredAxis{K,I,Ks,Inds}(inds, check_length::Bool=true, ensure_centered::Bool=true) where {K,I,Ks,Inds}
        if is_static(Ks)
            return CenteredAxis{K,I,Ks,Inds}(Ks(), inds, check_length, ensure_centered)
        else
            return CenteredAxis{K,I,Ks,Inds}(Ks(_construct_centered_keys(K, inds)), inds, check_length, ensure_centered)
        end
    end

    # CenteredAxis{K,I}
    function CenteredAxis{K,I}(inds::AbstractIndices) where {K,I}
        if eltype(inds) <: I
            ks = _construct_centered_keys(K, inds)
            return CenteredAxis{K,I,typeof(ks),typeof(inds)}(ks, inds, false, false)
        else
            return CenteredAxis{K,I}(AbstractIndices{I}(inds))

        end
    end

    # CenteredAxis{K}
    CenteredAxis{K}(inds::AbstractIndices{I}) where {K,I} = CenteredAxis{K,I}(inds)

    # CenteredAxis
    CenteredAxis(inds::AbstractIndices{I}) where {I} = CenteredAxis{I}(inds)
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
        return CenteredAxis{eltype(Ks),eltype(Inds),Ks,Inds}
    end
end

function _centered_axis_similar_type(::Type{OneToSRange{T,L}}) where {T,L}
    start = _centered_start_from_len(T, L)
    return CenteredAxis{T,T,UnitSRange{T,start,_centered_stop_from_len_and_start(start, L)},OneToSRange{T,L}}
end

function _centered_axis_similar_type(::Type{UnitSRange{T,B,L}}) where {T,B,L}
    len = L - B + 1
    start = _centered_start_from_len(T, len)
    return CenteredAxis{T,T,UnitSRange{T,start,_centered_stop_from_len_and_start(start, len)},UnitSRange{T,B,L}}
end

function _centered_axis_similar_type(::Type{Inds}) where {Inds}
    I = eltype(Inds)
    return CenteredAxis{I,I,UnitRange{I},Inds}
end

function StaticRanges.similar_type(
    ::Type{<:CenteredAxis},
    ::Type{Ks},
    ::Type{Inds},
) where {Ks,Inds}

    return _centered_axis_similar_type(Ks, Inds)
end

function StaticRanges.similar_type(
    ::Type{<:CenteredAxis},
    ::Type{Ks},
) where {Ks}

    return _centered_axis_similar_type(Ks)
end

function Interface.unsafe_reconstruct(axis::CenteredAxis, inds)
    return CenteredAxis{keytype(axis),eltype(inds)}(inds)
end

function _reset_keys!(axis::CenteredAxis)
    len = length(indices(axis))
    start = K(-div(len, 2))
    stop = K(start + len - 1)
    ks = keys(axis)
    set_first!(ks, start)
    set_last!(ks, stop)
    return nothing
end

