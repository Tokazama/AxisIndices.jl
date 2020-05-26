
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
        _promote_rule(indices_type(X),indices_type(Y))
    }
end
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:Axis,Y<:Axis}
    return Axis{
        promote_type(keytype(X), keytype(Y)),
        promote_type(valtype(X), valtype(Y)),
        _promote_rule(keys_type(X), keys_type(Y)),
        _promote_rule(indices_type(X),indices_type(Y))
    }
end

Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:SimpleAxis,Y<:Axis} = promote_rule(Y, X)
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:Axis,Y<:SimpleAxis}
    return Axis{
        promote_type(keytype(X), keytype(Y)),
        promote_type(valtype(X), valtype(Y)),
        _promote_rule(keys_type(X), keys_type(Y)),
        _promote_rule(indices_type(X),indices_type(Y))
    }
end

Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:AbstractAxis,Y<:SimpleAxis} = promote_rule(Y, X)
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:SimpleAxis,Y<:AbstractAxis}
    return SimpleAxis{promote_type(valtype(X),valtype(Y)),_promote_rule(indices_type(X),indices_type(Y))}
end
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:SimpleAxis,Y<:SimpleAxis}
    return SimpleAxis{promote_type(valtype(X),valtype(Y)),_promote_rule(indices_type(X),indices_type(Y))}
end

Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:AbstractUnitRange,Y<:SimpleAxis} = promote_rule(Y, X)
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:SimpleAxis,Y<:AbstractUnitRange}
    return SimpleAxis{promote_type(valtype(X),valtype(Y)),_promote_rule(indices_type(X),indices_type(Y))}
end

Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:AbstractUnitRange,Y<:Axis} = promote_rule(Y, X)
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:Axis,Y<:AbstractUnitRange}
    return Axis{keytype(X), promote_type(valtype(X),valtype(Y)), keys_type(X), _promote_rule(indices_type(X),indices_type(Y))}
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
       same_type(indices_type(X), indices_type(Y))
end

Base.UnitRange(a::AbstractAxis) = UnitRange(values(a))

