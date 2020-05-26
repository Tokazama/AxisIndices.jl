
append_keys!(x::AbstractRange, y) = set_length!(x, length(x) + length(y))
function append_keys!(x, y)
    if eltype(x) <: eltype(y)
        for x_i in x
            if x_i in y
                error("Element $x_i appears in both collections in call to append_axis!(collection1, collection2). All elements must be unique.")
            end
        end
        return append!(x, y)
    else
        return append_axis!(x, promote_axis_collections(y, x))
    end
end

@inline function append_axis!(x, y)
    if !is_indices_axis(x) && !is_indices_axis(y)
        append_keys!(keys(x), keys(y))
        set_length!(values(x), length(x) + length(y))
    else
        set_length!(x, length(x) + length(y))
    end
    return x
end

