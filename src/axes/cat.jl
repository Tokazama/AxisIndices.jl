
maybe_first(x::Tuple) = first(x)
maybe_first(x::Tuple{}) = nothing
maybe_tail(x::Tuple) = tail(x)
maybe_tail(x::Tuple{}) = ()

cat_axes(dims::Tuple, x) = x
@inline cat_axes(dims::Tuple, x, y, zs...) = cat_axes(dims, _cat_axes(dims, x, y), zs...)
_cat_axes(::Tuple{}, x::Tuple, y::Tuple) = ()
@inline function _cat_axes(dims::Tuple, x::Tuple, y::Tuple)
    return (
        cat_axis(first(dims), maybe_first(x), maybe_first(y)),
        _cat_axes(tail(dims), maybe_tail(x), maybe_tail(y))...
    )
end

# TODO handle combine AxisOffset and AxisOrigin

function cat_axis(indicator, x::OffsetAxis, y)
    xo, xp = strip_offset(x)
    yo, yp = strip_offset(y)
    return initialize(xo, cat_axis(indicator, xp, yp))
end
function cat_axis2(indicator, x, y::OffsetAxis)
    xo, xp = strip_offset(x)
    yo, yp = strip_offset(y)
    return initialize(yo, cat_axis(indicator, xp, yp))
end


function cat_axis(indicator, x::CenteredAxis, y)
    xo, xp = strip_offset(x)
    yo, yp = strip_offset(y)
    return initialize(xo, cat_axis(indicator, xp, yp))
end
function cat_axis2(indicator, x, y::CenteredAxis)
    xo, xp = strip_offset(x)
    yo, yp = strip_offset(y)
    return initialize(yo, cat_axis(indicator, xp, yp))
end

cat_axis(indicator, x, y) = cat_axis2(indicator, x, y)
cat_axis2(indicator, x, y) = _final_cat_axis(indicator, x, y)
# when resizing axes for concatenation we have to account for what is known at compile time
# if we don't know the dimensions being concatenated we don't know their sizes
function _final_cat_axis(indicator::Bool, x, y)
    if indicator
        return static(1):(length(x) + length(y))
    else
        return static(1):length(x)
    end
end
_final_cat_axis(::True, x, y) = static(1):(staatic_length(x) + static_length(y))
_final_cat_axis(::False, x, y) = _combine_length(static_length(x), static_length(y))


# TODO cat - specialize concatenation based on type of keys
function cat_axis(indicator, x::KeyedAxis, y)
    xp, xaxis = strip_keys(x)
    yp, yaxis = strip_keys(y)
    return _Axis(cat_keys(indicator, xp, yp), cat_axis(indicator, xaxis, yaxis))
end
function cat_axis2(indicator, x, y::KeyedAxis)
    xp, xaxis = strip_keys(x)
    yp, yaxis = strip_keys(y)
    return _Axis(cat_keys(indicator, xp, yp), cat_axis(indicator, xaxis, yaxis))
end
cat_keys(::True, k1, k2) = LazyVCat(k1, k2)
cat_keys(::False, k1, k2) = k1
function cat_keys(indicator::Bool, k1, k2)
    if indicator
        return LazyVCat(k1, k2[static(1):length(k2)])
    else
        return LazyVCat(k1, empty(k2))
    end
end

# PaddedAxis
function cat_axis(indicator, x::PaddedAxis, y)
    xp, xaxis = strip_pads(x)
    yp, yaxis = strip_pads(y)
    return cat_axis(indicator, cat_pads(xp, yp), cat_axis(indicator, xaxis, yaxis))
end
function cat_axis2(indicator, x, y::PaddedAxis)
    xp, xaxis = strip_pads(x)
    yp, yaxis = strip_pads(y)
    return cat_axis(indicator, cat_pads(xp, yp), cat_axis(indicator, xaxis, yaxis))
end

cat_pads(x, y) = static(1):(first_pad(x) + last_pad(x) + first_pad(y) + last_pad(y))
cat_pads(::Nothing, y) = static(1):(first_pad(y) + last_pad(y))
cat_pads(x, ::Nothing) = static(1):(first_pad(x) + last_pad(x))
cat_pads(::Nothing, ::Nothing) = static(1):static(0)


# TODO cat AxisStruct
function cat_axis(indicator, x::StructAxis, y)
    xp, xaxis = strip_keys(x)
    yp, yaxis = strip_keys(y)
    return _Axis(cat_keys(indicator, xp, yp), cat_axis(indicator, xaxis, yaxis))
end
function cat_axis2(indicator, x, y::StructAxis)
    xp, xaxis = strip_keys(x)
    yp, yaxis = strip_keys(y)
    return _Axis(cat_keys(indicator, xp, yp), cat_axis(indicator, xaxis, yaxis))
end

