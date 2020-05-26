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

