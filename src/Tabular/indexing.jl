
###
### getindex
###
@propagate_inbounds function Base.getindex(x::AbstractTable, arg1, arg2)
    return get_index(x, rowaxis(x), colaxis(x), arg1, arg2)
end

@propagate_inbounds function get_index(x, raxis, caxis, arg1, arg2)
    return _unsafe_getindex(x, raxis, caxis, arg1, arg2, to_index(raxis, arg1), to_index(caxis, arg2))
end

@inline function _unsafe_getindex(x, raxis, caxis, arg1, arg2, i1::Integer, i2::Integer)
    return unsafe_getindex(unsafe_getindex(parent(x), (arg2,), (i2,)), (arg1,), (i1,))
end

@inline function _unsafe_getindex(x, raxis, caxis, arg1, arg2, i1::Integer, i2::AbstractVector)
    return [unsafe_getindex(unsafe_getindex(parent(x), (arg2,), (i,)), (arg1,), (i1,)) for i in i2]
end

_unsafe_getindex(x, raxis, caxis, arg1, arg2, i1::Integer, i2::Base.Slice) = TableRow(i1, x)

@inline function _unsafe_getindex(x, raxis, caxis, arg1, arg2, i1::AbstractVector, i2::Integer)
    return @inbounds(getindex(unsafe_getindex(parent(x), (arg2,), (i2,)), i1))
end

@inline function _unsafe_getindex(x, raxis, caxis, arg1, arg2, i1::Base.Slice, i2::Integer)
    return @inbounds(unsafe_getindex(parent(x), (arg2,), (i2,)))
end

@inline function _unsafe_getindex(x, raxis, caxis, arg1, arg2, i1::AbstractVector, i2::AbstractVector)
    return Table([@inbounds(getindex(unsafe_getindex(parent(x), (arg2,), (i,)), i1)) for i in i2], caxis[i2])
end


###
### setindex!
###

_nrows_equals_indices_length(raxis, ::Colon) = true
_nrows_equals_indices_length(raxis, arg) = length(to_index(raxis, arg)) == length(raxis)


function unsafe_pushcol!(x::AbstractTable, caxis, key, vals::AbstractVector)
    is_dynamic(caxis) || error("Columns may only be dynamically add to tables with a dynamic column axis.")
    is_dynamic(x) || error("Columns may only be dynamically add to tables with dynamic column storage.")
    Axes.push_key!(caxis, key)
    push!(parent(x), vals)
    return nothing
end

@propagate_inbounds function set_index!(x, raxis, caxis, vals, arg1, arg2)
    if is_element(arg2) && is_key(arg2)
        if checkindex(Bool, caxis, arg2)
        elseif _nrows_equals_indices_length(raxis, arg1) # might be creating new column
            if isempty(x)
                set_length!(raxis, length(vals))
            end
            unsafe_pushcol!(x, caxis, arg2, vals)
        else
            error("Cannot create new column $arg2 because length of provided column is not the same as the number of rows.")
        end
    else
        setindex!(getindex(parent(x), to_index(colaxis(x), arg2)), vals, to_index(rowaxis(x), arg1))
    end
end

@propagate_inbounds function Base.setindex!(x::AbstractTable, vals, arg1, arg2)
    set_index!(x, rowaxis(x), colaxis(x), vals, arg1, arg2)
end
