
function StaticRanges._findin(x::AbstractAxis{K,<:Integer}, xo, y::AbstractUnitRange{<:Integer}, yo) where {K}
    return StaticRanges._findin(values(x), xo, y, yo)
end
function StaticRanges._findin(x::AbstractUnitRange{<:Integer}, xo, y::AbstractSimpleAxis{K,<:Integer}, yo) where {K}
    return StaticRanges._findin(x, xo, values(y), yo)
end
function StaticRanges._findin(x::AbstractAxis{K1,<:Integer}, xo, y::AbstractAxis{K2,<:Integer}, yo) where {K1,K2}
    return StaticRanges._findin(values(x), xo, values(y), yo)
end
