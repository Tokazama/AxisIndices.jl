
Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:AbstractAxis,Y<:Axis} = promote_rule(Y, X)
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:Axis,Y<:AbstractAxis}
    return Axis{
        promote_type(keytype(X), keytype(Y)),
        promote_type(valtype(X), valtype(Y)),
        promote_type(_keys_type(X), _keys_type(Y)),
        promote_type(parent_type(X), parent_type(Y))
    }
end
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:Axis,Y<:Axis}
    return Axis{
        promote_type(keytype(X), keytype(Y)),
        promote_type(valtype(X), valtype(Y)),
        promote_type(_keys_type(X), _keys_type(Y)),
        promote_type(parent_type(X), parent_type(Y))
    }
end

Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:SimpleAxis,Y<:Axis} = promote_rule(Y, X)
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:Axis,Y<:SimpleAxis}
    return Axis{
        promote_type(keytype(X), keytype(Y)),
        promote_type(valtype(X), valtype(Y)),
        _keys_type(X),
        promote_type(parent_type(X), parent_type(Y))
    }
end

Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:AbstractAxis,Y<:SimpleAxis} = promote_rule(Y, X)
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:SimpleAxis,Y<:AbstractAxis}
    return SimpleAxis{
        promote_type(valtype(X),valtype(Y)),
        promote_type(parent_type(X), parent_type(Y))
    }
end
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:SimpleAxis,Y<:SimpleAxis}
    return SimpleAxis{
        promote_type(valtype(X),valtype(Y)),
        promote_type(parent_type(X),parent_type(Y))
    }
end

function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:AbstractUnitRange,Y<:SimpleAxis}
    return promote_rule(Y, X)
end
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:SimpleAxis,Y<:AbstractUnitRange}
    return SimpleAxis{
        promote_type(valtype(X),valtype(Y)),
        promote_type(parent_type(X), parent_type(Y))
    }
end

Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:AbstractUnitRange,Y<:Axis} = promote_rule(Y, X)
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:Axis,Y<:AbstractUnitRange}
    return Axis{
        keytype(X),
        promote_type(valtype(X),valtype(Y)),
        _keys_type(X),
        promote_type(parent_type(X), parent_type(Y))
    }
end

# unfortunately, we need these to avoid ambiguities
function Base.promote_rule(::Type{UnitRange{T1}}, ::Type{Y}) where {T1,Y<:SimpleAxis}
    return promote_rule(Y,UnitRange{T1})
end
function Base.promote_rule(::Type{UnitRange{T1}}, ::Type{Y}) where {T1,Y<:Axis}
    return promote_rule(Y,UnitRange{T1})
end

# TODO delete this?
function StaticRanges.same_type(::Type{X}, ::Type{Y}) where {X<:AbstractAxis,Y<:AbstractAxis}
    return (X.name === Y.name)  & # TODO there should be a better way of doing this
       same_type(_keys_type(X), _keys_type(Y)) &
       same_type(parent_type(X), indices_type(Y))
end

