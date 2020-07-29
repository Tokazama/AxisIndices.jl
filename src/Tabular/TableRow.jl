
"""
    TableRow

A view of one row of an `AbstractTable`.
"""
struct TableRow{P,RA,CA,T<:AbstractTable{P,RA,CA}} <: AbstractTable{P,RA,CA}
    row_index::Int
    parent::T
end

Base.parent(x::TableRow) = getfield(x, :parent)

row_index(x::TableRow) = getfield(x, :row_index)

Interface.col_axis(x::TableRow) = col_axis(parent(x))

# TODO should TableRow return a row_axis
#AxisIndices.AxisCore.row_axis(x::TableRow) = row_axis(parent(x))

@propagate_inbounds function Base.getindex(x::TableRow, col)
    i = to_index(col_axis(x), col)
    return @inbounds(parent(parent(x))[i][row_index(x)])
end

@propagate_inbounds function Base.setindex!(x::TableRow, val, col)
    i = to_index(col_axis(x), col)
    @inbounds setindex!(parent(parent(x))[i], val, row_index(x))
end

Base.getproperty(x::TableRow, i) = getindex(x, i)

Base.getproperty(x::TableRow, i::Symbol) = getindex(x, i)

Base.setproperty!(x::TableRow, i::Symbol, val) = setindex!(x, val, i)

Base.propertynames(x::TableRow) = col_keys(x)

Base.show(io::IO, ::MIME"text/plain", x::TableRow) = pretty_table(io, x)

