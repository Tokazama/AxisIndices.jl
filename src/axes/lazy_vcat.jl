
""" LazyVCat """
struct LazyVCat{T1,T2,V1<:AbstractVector{T1},V2<:AbstractVector{T2}} <: AbstractVector{Union{T1,T2}}
    v1::V1
    v2::V2
end

Base.getindex(x::LazyVCat, i) = index_lazy_vcat(x, i)

Base.size(x::LazyVCat) = (length(x.v1) + length(x.v2),)

@propagate_inbounds function index_lazy_vcat(x::LazyVCat, i::Integer)
    l1 = length(x.v1)
    if i > l1
        return getindex(x.v2, i - l1)
    else
        return getindex(x.v1, i)
    end
end

@propagate_inbounds function index_lazy_vcat(x::LazyVCat, i::AbstractRange)
    l1 = length(z.v1)
    if step(i) > 0
        idx = find_first(<(l1), i)
    else
        idx = find_last(>(l1), i)
    end
    if idx === nothing
        return LazyVCat(empty(x.v1), x.v2[i])
    elseif length(i) >= idx
        return LazyVCat(x.v1[i], empty(x.v2))
    else
        return LazyVCat(x.v1[i[static(1):idx]], x.v1[i[(idx + one(idx)):static_length(i)]])
    end
end

@propagate_inbounds function index_lazy_vcat(x::LazyVCat, i::AbstractVector{Bool})
    l1 = static_length(x.v1)
    return LazyVCat(
        x.v1[i[static(1):l1]],
        x.v2[i[(l1 + static(1)):(l1 + static_length(x.v2))]]
    )
end

@propagate_inbounds function index_lazy_vcat(x::LazyVCat, i::AbstractVector)
    out = Vector{eltype(x)}(undef, length(i))
    for ii in eachindex(i)
        val = i[ii]
        @inbounds(setindex!(out[i], val, ii))
    end
    return out
end


