
const ReinterpretAxisArray{T,N,S,A<:AbstractAxisArray{S,N}} = ReinterpretArray{T,N,S,A}

function Base.axes(A::ReinterpretAxisArray{T,N,S}) where {T,N,S}
    paxs = axes(parent(A))
    axis_1 = first(paxs)
    len = div(length(axis_1) * sizeof(S), sizeof(T))
    return tuple(resize_last(axis_1, len), tail(paxs)...)
end

const ReinterpretNamedAxisArray{T,N,S,L,A<:NamedAxisArray{L,S,N}} = ReinterpretArray{T,N,S,A}

function Base.axes(A::ReinterpretNamedAxisArray{T,N,S}) where {T,N,S}
    paxs = axes(parent(A))
    axis_1 = first(paxs)
    len = div(length(axis_1) * sizeof(S), sizeof(T))
    return tuple(resize_last(axis_1, len), tail(paxs)...)
end

#=
function size(a::ReinterpretArray{T,N,S} where {N}) where {T,S}
    psize = size(a.parent)
    size1 = div(psize[1]*sizeof(S), sizeof(T))
    tuple(size1, tail(psize)...)
end
=#
