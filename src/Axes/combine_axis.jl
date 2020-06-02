
# TODO document combine_indices
#=
    combine_indices(x, y)

=#
combine_indices(x, y) = _combine_indices(indices(x), indices(y))
_combine_indices(x::X, y::Y) where {X,Y} = promote_type(X, Y)(x)

# LinearIndices indicates that keys are not formally defined so the collection
# that isn't LinearIndices is used. If both are LinearIndices then take the underlying
# OneTo as the new keys.
combine_keys(x, y) = _combine_keys(keys(x), keys(y))
_combine_keys(x, y) = promote_axis_collections(x, y)
_combine_keys(x,                y::LinearIndices) = x
_combine_keys(x::LinearIndices, y               ) = y
_combine_keys(x::LinearIndices, y::LinearIndices) = first(y.indices)

@inline function combine_axis(x::AbstractAxis, y::AbstractAxis, inds=combine_indices(x, y))
    if is_indices_axis(x)
        if is_indices_axis(y)
            return unsafe_reconstruct(x, inds)
        else
            return unsafe_reconstruct(y, keys(y), inds)
        end
    else
        if is_indices_axis(y)
            return unsafe_reconstruct(x, keys(x), inds)
        else
            return unsafe_reconstruct(y, combine_keys(x, y), inds)
        end
    end
end

@inline function combine_axis(x, y::AbstractAxis, inds=combine_indices(x, y))
    if is_indices_axis(y)
        return unsafe_reconstruct(y, inds)
    else
        return unsafe_reconstruct(y, keys(y), inds)
    end
end

@inline function combine_axis(x::AbstractAxis, y, inds=combine_indices(x, y))
    if is_indices_axis(x)
        return unsafe_reconstruct(x, inds)
    else
        return unsafe_reconstruct(x, keys(x), inds)
    end
end


# TODO I still really don't like this solution but the result seems better than Any
# alternative I've seen out there
#=
Problem: String, Symbol, Second, etc. don't promote neatly with Int (default key value)
Solution: Symbol(element), Second(element) for promotion
Exception: String(element) doesn't work so string(element) has to be used
=#

promote_axis_collections(x::X, y::X) where {X} = x

function promote_axis_collections(x::LinearIndices{1}, y::Y) where {Y}
    return promote_axis_collections(x.indices[1], y)
end
function promote_axis_collections(x::X, y::LinearIndices{1}) where {X}
    return promote_axis_collections(x, y.indices[1])
end
function promote_axis_collections(x::X, y::Y) where {X,Y}
    if promote_rule(X, Y) <: Union{}
        Z = promote_rule(Y, X)
    else
        Z = promote_rule(X, Y)
    end

    if Z <: Union{}
        Tx = eltype(X)
        Ty = eltype(Y)
        Tnew = promote_type(Tx, Ty)
        if Tnew == Any
            if is_key(Tx)
                if Tx <: AbstractString
                    return promote_axis_collections(x, string.(y))
                else
                    return promote_axis_collections(x, Tx.(y))
                end
            else
                if is_key(Ty)
                    if Ty <: AbstractString
                        return promote_axis_collections(string.(x), y)
                    else
                        return promote_axis_collections(Ty.(x), y)
                    end
                else
                    error("No method available for promoting keys of type $Tx and $Ty.")
                end
            end
        else
            return promote_axis_collections(Tnew.(x), y)
        end
    else
        return Z(x)
    end
end

