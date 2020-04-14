
#=
Type Hierarchy for combining axes
1. Axis
2. AbstractAxis
3. SimpleAxis
4. AbstractUnitRange
=#

Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:AbstractAxis,Y<:Axis} = promote_rule(Y, X)
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:Axis,Y<:AbstractAxis}
    return Axis{
        promote_type(keytype(X), keytype(Y)),
        promote_type(valtype(X), valtype(Y)),
        _promote_rule(keys_type(X), keys_type(Y)),
        _promote_rule(values_type(X),values_type(Y))
    }
end
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:Axis,Y<:Axis}
    return Axis{
        promote_type(keytype(X), keytype(Y)),
        promote_type(valtype(X), valtype(Y)),
        _promote_rule(keys_type(X), keys_type(Y)),
        _promote_rule(values_type(X),values_type(Y))
    }
end

Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:SimpleAxis,Y<:Axis} = promote_rule(Y, X)
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:Axis,Y<:SimpleAxis}
    return Axis{
        promote_type(keytype(X), keytype(Y)),
        promote_type(valtype(X), valtype(Y)),
        _promote_rule(keys_type(X), keys_type(Y)),
        _promote_rule(values_type(X),values_type(Y))
    }
end

Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:AbstractAxis,Y<:SimpleAxis} = promote_rule(Y, X)
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:SimpleAxis,Y<:AbstractAxis}
    return SimpleAxis{promote_type(valtype(X),valtype(Y)),_promote_rule(values_type(X),values_type(Y))}
end
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:SimpleAxis,Y<:SimpleAxis}
    return SimpleAxis{promote_type(valtype(X),valtype(Y)),_promote_rule(values_type(X),values_type(Y))}
end

Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:AbstractUnitRange,Y<:SimpleAxis} = promote_rule(Y, X)
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:SimpleAxis,Y<:AbstractUnitRange}
    return SimpleAxis{promote_type(valtype(X),valtype(Y)),_promote_rule(values_type(X),values_type(Y))}
end

Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:AbstractUnitRange,Y<:Axis} = promote_rule(Y, X)
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:Axis,Y<:AbstractUnitRange}
    return Axis{keytype(X), promote_type(valtype(X),valtype(Y)), keys_type(X), _promote_rule(values_type(X),values_type(Y))}
end

# unfortunately, we need these to avoid ambiguities
Base.promote_rule(::Type{UnitRange{T1}}, ::Type{Y}) where {T1,Y<:SimpleAxis} = promote_rule(Y,UnitRange{T1})
Base.promote_rule(::Type{UnitRange{T1}}, ::Type{Y}) where {T1,Y<:Axis} = promote_rule(Y,UnitRange{T1})

function _promote_rule(::Type{X}, ::Type{Y}) where {X,Y}
    out = promote_rule(X, Y)
    return out <: Union{} ? promote_rule(Y, X) : out
end

function StaticRanges.same_type(::Type{X}, ::Type{Y}) where {X<:AbstractAxis,Y<:AbstractAxis}
    return (X.name === Y.name)  & # TODO there should be a better way of doing this
       same_type(keys_type(X), keys_type(Y)) &
       same_type(values_type(X), values_type(Y))
end

Base.UnitRange(a::AbstractAxis) = UnitRange(values(a))

promote_axis_collections(x::X, y::X) where {X} = x


#=
Problem: String, Symbol, Second, etc. don't promote neatly with Int (default key value)
Solution: Symbol(element), Second(element) for promotion
Exception: String(element) doesn't work so string(element) has to be used
=#
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

