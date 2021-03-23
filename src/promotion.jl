
Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:AbstractAxis,Y<:Axis} = promote_rule(Y, X)
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:Axis,Y<:AbstractAxis}
    return Axis{
        promote_type(keys_type(X), keys_type(Y)),
        promote_type(parent_type(X), parent_type(Y))
    }
end
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:Axis,Y<:Axis}
    return Axis{
        promote_type(keys_type(X), keys_type(Y)),
        promote_type(parent_type(X), parent_type(Y))
    }
end

Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:SimpleAxis,Y<:Axis} = promote_rule(Y, X)
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:Axis,Y<:SimpleAxis}
    return Axis{keys_type(X),promote_type(parent_type(X), parent_type(Y))}
end

Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:AbstractAxis,Y<:SimpleAxis} = promote_rule(Y, X)
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:SimpleAxis,Y<:AbstractAxis}
    return SimpleAxis{promote_type(parent_type(X), parent_type(Y))}
end
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:SimpleAxis,Y<:SimpleAxis}
    return SimpleAxis{promote_type(parent_type(X),parent_type(Y))}
end

function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:AbstractUnitRange,Y<:SimpleAxis}
    return promote_rule(Y, X)
end
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:SimpleAxis,Y<:AbstractUnitRange}
    return SimpleAxis{promote_type(parent_type(X), parent_type(Y))}
end

Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:AbstractUnitRange,Y<:Axis} = promote_rule(Y, X)
function Base.promote_rule(::Type{X}, ::Type{Y}) where {X<:Axis,Y<:AbstractUnitRange}
    return Axis{keys_type(X), promote_type(parent_type(X), parent_type(Y))}
end

# unfortunately, we need these to avoid ambiguities
function Base.promote_rule(::Type{UnitRange{T1}}, ::Type{Y}) where {T1,Y<:SimpleAxis}
    return promote_rule(Y,UnitRange{T1})
end
function Base.promote_rule(::Type{UnitRange{T1}}, ::Type{Y}) where {T1,Y<:Axis}
    return promote_rule(Y,UnitRange{T1})
end

