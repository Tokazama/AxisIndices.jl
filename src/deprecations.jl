
@deprecate axes_keys(x) keys.(axes(x))


#=
function OffsetAxis{I,Inds,F}(f::Integer, inds::AbstractUnitRange) where {I,Inds,F}
    if inds isa Inds && f isa F
        return new{I,Inds,F}(f, inds)
    else
        return OffsetAxis(f, Inds(inds))
    end
end

function OffsetAxis{I,Inds,F}(ks::AbstractUnitRange, inds::AbstractUnitRange) where {I,Inds,F}
    check_axis_length(ks, inds)
    return OffsetAxis{I,Inds,F}(static_first(ks) - static_first(inds), inds)
end

# OffsetAxis{I,Inds}
function OffsetAxis{I,Inds}(f::Integer, inds::AbstractUnitRange) where {I,Inds}
    if inds isa Inds
        return OffsetAxis{I,Inds,typeof(f)}(f, inds)
    else
        return OffsetAxis{I,Inds}(f, Inds(inds))
    end
end
@inline function OffsetAxis{I,Inds}(ks::AbstractUnitRange, inds::AbstractUnitRange) where {I,Inds}
    check_axis_length(ks, inds)
    return OffsetAxis{I,Inds}(static_first(ks) - static_first(inds), inds)
end
@inline function OffsetAxis{I,Inds}(ks::AbstractUnitRange) where {I,Inds}
    f = static_first(ks)
    return OffsetAxis{I}(f - one(f), Inds(OneTo(static_length(ks))))
end

# OffsetAxis{I}
function OffsetAxis{I}(f::Integer, inds::AbstractAxis) where {I}
    return OffsetAxis{I,typeof(inds)}(f, inds)
end
function OffsetAxis{I}(f::Integer, inds::AbstractArray) where {I}
    return OffsetAxis{I}(f, compose_axis(inds))
end
function OffsetAxis{I}(f::AbstractUnitRange, inds::AbstractArray) where {I}
    return OffsetAxis{I}(f, compose_axis(inds))
end 
function OffsetAxis{I}(ks::AbstractUnitRange, inds::AbstractAxis) where {I}
    check_axis_length(ks, inds)
    return OffsetAxis{I}(static_first(ks) - static_first(inds), inds)
end
function OffsetAxis{I}(ks::AbstractUnitRange) where {I}
    f = static_first(ks)
    return OffsetAxis{I}(f - one(f), SimpleAxis(One():static_length(ks)))
end
function OffsetAxis{I}(ks::AbstractUnitRange, inds::AbstractOffsetAxis) where {I}
    check_axis_length(ks, inds)
    p = parent(inds)
    return OffsetAxis{I}(static_first(ks) + static_first(inds) - static_first(p), p)
end
=#


#=
function Axis{K,P}(x::AbstractUnitRange{<:Integer}) where {K,P}
    if x isa Ks
        if x isa Vs
            return new{K,P}(x, x)
        else
            return new{K,P}(x, Vs(x))
        end
    else
        if x isa Vs
            return new{K,P}(Ks(x), x)
        else
            return  new{K,P}(Ks(x), Vs(x))
        end
    end
end
=#

#=
function Axis{K,P}(axis::SimpleAxis) where {K,I,Ks,Inds}
    return new{K,I,Ks,Inds}(axis, axis)
end

function Axis{K,P}(axis::AbstractAxis) where {K,P}
    return new{K,P}(convert(K, keys(axis)), convert(P, axis))
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

function Axis{K,I}(ks::AbstractVector) where {K,I}
    check_unique_keys(ks)
    if can_change_size(ks)
        inds = SimpleAxis(OneToMRange{I}(length(ks)))
    else
        inds = SimpleAxis(indices(ks))
    end
    return new{K,I,typeof(ks),typeof(inds)}()
end
function Axis{K,I}(ks::AbstractVector, inds::AbstractAxis) where {K,I}
    if eltype(ks) <: K
        if eltype(inds) <: I
            return Axis{K,I,typeof(ks),typeof(inds)}(ks, inds)
        else
            return Axis{K,I}(ks, AbstractUnitRange{I}(inds))
        end
    else
        return Axis{K,I}(AbstractVector{K}(ks), inds)
    end
end
function Axis{K,I}(ks::AbstractVector, inds::AbstractUnitRange) where {K,I}
    return Axis{K,I}(ks, compose_axis(inds))
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
=#

#=

    function CenteredAxis{I,Inds,F}(origin::Integer, inds::AbstractAxis) where {I,Inds,F}
        if inds isa Inds && origin isa F
            return new{I,Inds,F}(origin, inds)
        else
            return CenteredAxis(origin, convert(Inds, inds))
        end
    end
    function CenteredAxis{I,Inds,F}(inds::AbstractRange) where {I,Inds,F<:StaticInt}
        return new{I,Inds,F}(F(), inds)
    end
    function CenteredAxis{I,Inds,F}(inds::AbstractRange) where {I,Inds,F}
        return new{I,Inds,F}(F(0), inds)
    end

    function CenteredAxis{I,Inds,F}(origin::Integer, inds::AbstractRange) where {I,Inds,F}
        return CenteredAxis{I,Inds}(origin, inds)
    end

    function CenteredAxis{I,Inds}(inds::AbstractRange) where {I,Inds}
        return CenteredAxis{I,Inds}(Zero(), inds)
    end
    function CenteredAxis{I,Inds}(origin::Integer, inds::AbstractArray) where {I,Inds}
        return CenteredAxis{I,Inds}(origin, compose_axis(inds))
    end
    function CenteredAxis{I,Inds}(origin::Integer, inds::AbstractAxis) where {I,Inds}
        if inds isa Inds
            return CenteredAxis{I,Inds,typeof(origin)}(origin, inds)
        else
            return CenteredAxis{I}(origin, convert(Inds, inds))
        end
    end

    function CenteredAxis{I}(origin::Integer, inds::AbstractArray) where {I}
        return CenteredAxis{I}(origin, compose_axis(inds))
    end
    function CenteredAxis{I}(origin::Integer, inds::AbstractOffsetAxis) where {I}
        return CenteredAxis{I}(origin, parent(inds))
    end
    function CenteredAxis{I}(origin::Integer, inds::AbstractAxis) where {I}
        if eltype(inds) <: I
            return CenteredAxis{I,typeof(inds)}(origin, inds)
        else
            return CenteredAxis{I}(origin, convert(AbstractUnitRange{I}, inds))
        end
    end
    CenteredAxis{I}(inds::AbstractRange) where {I} = CenteredAxis{I}(Zero(), inds)

=#



###
### padded initializers
###

_sym_pad_to_tuple(::Val{N}, sym_pad::Integer) where {N} = ntuple(_ -> (sym_pad, sym_pad), Val(N))
function _sym_pad_to_tuple(::Val{N}, sym_pad::Tuple{Vararg{<:Any,N}}) where {N}
    return map(i -> (i, i), sym_pad)
end
function _pad_to_tuple(::Val{N}, first_pad::Integer, last_pad::Integer) where {N}
    return ntuple(_ -> (first_pad, last_pad), Val(N))
end
function _pad_to_tuple(::Val{N}, first_pad::Integer, last_pad::Tuple{Vararg{<:Any,N}}) where {N}
    return ntuple(i -> (first_pad, getfield(last_pad, i)), Val(N))
end
function _pad_to_tuple(::Val{N}, first_pad::Tuple{Vararg{<:Any,N}}, last_pad::Integer) where {N}
    return ntuple(i -> (getfield(first_pad, i), last_pad), Val(N))
end
function _pad_to_tuple(::Val{N}, first_pad::Tuple{Vararg{<:Any,N}}, last_pad::Tuple{Vararg{<:Any,N}}) where {N}
    return ntuple(i -> (getfield(first_pad, i), getfield(last_pad, i)), Val(N))
end

