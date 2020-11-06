
"""
    closest(collection, x)

Find the index of the value in `collection` closest to `x`.
"""
closest(x) = Base.Fix2(closest, x)
function closest(collection, x)
    if eltype(collection) <: Number
        return closest_number(collection, x)
    else
        throw(MethodError("clossest does not work for eltype $(eltype(collection))"))
    end
end

function closest_number(collection, x)
    if issorted(collection)
        return _closest_number_forward(collection, x)
    elseif issorted(collection, order=Base.Reverse)
        return _closest_number_reverse(collection, x)
    else
        return _closest_number_search(collection, x)
    end
end

function _closest_number_forward(collection, x)
    i = findfirst(>(x), collection)
    if i == firstindex(collection)
        return i
    else
        iminone = i - oneunit(i)
        if (x - @inbounds(collection[iminone])) < (@inbounds(collection[i]) - x)
            return iminone
        else
            return i
        end
    end
end

function _closest_number_reverse(collection, x)
    i = findlast(>(x), collection)
    if i == lastindex(collection)
        return i
    else
        ipone = i + oneunit(i)
        if (x - @inbounds(collection[ipone])) < (@inbounds(collection[i]) - x)
            return ipone
        else
            return i
        end
    end
end

function _closest_number_search(collection, x)
    p = pairs(collection)
    i, ival = first(p)
    cmpval = abs(ival - x)
    @inbounds for (k,v) in p
        tmp_cmpval = abs(v - x)
        if (tmp_cmpval < cmpval)
            cmpval = tmp_cmpval
            i = k
        end
    end
    return i
end

@propagate_inbounds function ArrayInterface.to_index(::IndexAxis, axis, arg::Base.Fix2{typeof(closest),<:Any})
    idx = arg(keys(axis))
    @boundscheck if idx === nothing
        throw(BoundsError(axis, arg))
    end
    return Int(idx)
end
function Base.checkindex(::Type{Bool}, axis::AbstractAxis, arg::Base.Fix2{typeof(closest),<:Any})
    return arg(keys(axis)) !== nothing
end

