
# TODO indexing needs more consistent system
# - get generators working with AxisIndices
module Tabular

using StaticArrays

using AxisIndices.Styles

using AxisIndices.Interface

using AxisIndices.Axes

using AxisIndices.Arrays
using AxisIndices.Arrays: unsafe_getindex

using PrettyTables
using Tables
using TableTraits
using TableTraitsUtils

using Base: @propagate_inbounds

export Table, TableRow

"""
    AbstractTable

Supertype for which tables that utilize an `AbstractAxis` interface for tabular data.
"""
abstract type AbstractTable{T,RA} end

###
### Array Interface
###
@inline Base.eltype(::T) where {T<:AbstractTable} =  TableRow{T}

Base.axes(x::AbstractTable) = (rowaxis(x), colaxis(x))

function Base.axes(x::AbstractTable, i::Int)
    if i === 1
        return rowaxis(x)
    elseif i === 2
        return colaxis(x)
    else
        return SimpleAxis(Base.OneTo(1))
    end
end

Base.ndims(::T) where {T<:AbstractTable} = ndims(T)
Base.ndims(::Type{<:AbstractTable}) = 2

Base.size(x::AbstractTable) = (length(rowaxis(x)), length(colaxis(x)))

function Base.size(x::AbstractTable, i::Int)
    if i === 1
        return length(rowaxis(x))
    elseif i === 2
        return length(colaxis(x))
    else
        return 1
    end
end

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

@inline function _unsafe_getindex(x, raxis, caxis, arg1, arg2, i1::AbstractVector, i2::AbstractVector)
    return Table([@inbounds(getindex(unsafe_getindex(parent(x), (arg2,), (i,)), i1)) for i in i2], caxis[i2])
end

@propagate_inbounds function Base.setindex!(x::AbstractTable, vals, arg1, arg2)
    setindex!(getindex(parent(x), to_index(colaxis(x), arg2)), vals, to_index(rowaxis(x), arg1))
end

@inline function Base.iterate(x::AbstractTable, st=1)
    if st > length(x)
        return nothing
    else
        return (TableRow(st, x), st + 1)
    end
end

Base.length(x::AbstractTable) = length(rowaxis(x))

Interface.rowtype(::Type{<:AbstractTable{T,RA}}) where {T,RA} = RA
Interface.coltype(::Type{<:AbstractTable{T}}) where {T} = rowtype(T)
Interface.colaxis(x::AbstractTable) = axes(parent(x), 1)

###
### Tables Interface
###
Tables.columnaccess(::Type{<:AbstractTable}) = true

# FIXME as soon as PrettyTables.jl updates get rid of Vector
Tables.columnnames(x::AbstractTable) = Vector(colkeys(x))

Tables.istable(::Type{<:AbstractTable}) = true

Tables.columns(x::AbstractTable) = x

Tables.schema(x::AbstractTable) = Tables.schema(typeof(x))
Tables.schema(::Type{T}) where {T<:AbstractTable} = Tables.schema(coltype(T))
@generated Tables.schema(::Type{<:StructAxis{T}}) where {T} = Tables.Schema{Tuple(fieldnames(T)),Tuple{fieldtypes(T)...}}()

"""
    Table

Stores a vector of columns that may be acccessed via the Tables.jl interface.
"""
struct Table{P<:AxisVector,RA} <: AbstractTable{P,RA}
    parent::P
    rowaxis::RA

    function Table{P,RA}(x::P, raxis::RA) where {P<:AxisArray{<:Any,1},RA<:AbstractAxis}
        if length(x) > 1
            nr = length(raxis)
            for x_i in x
                nr == length(x_i) || error("All columns must be the same length.")
            end
        end
        return new{P,RA}(x, raxis)
    end
end

Base.getproperty(x::Table, i) = getindex(x, :, i)

Base.getproperty(x::Table, i::Symbol) = getindex(x, :, i)

Base.setproperty!(x::Table, i, val) = setindex!(x, val, :, i)

Base.propertynames(x::Table) = colkeys(x)

Base.parent(x::Table) = getfield(x, :parent)

Interface.rowaxis(x::Table) = getfield(x, :rowaxis)

function Table(x::T, raxis::RA) where {T<:AxisArray{<:Any,1},RA<:AbstractAxis}
    return Table{T,RA}(x, raxis)
end

function Table(x::AxisArray{<:AbstractVector,1})
    return Table(x, to_axis(axes(first(x), 1)))
end

Table(; kwargs...) = Table(values(kwargs))

Table(x::AbstractVector{<:AbstractVector}, ks::AbstractVector) = Table(AxisArray(x, ks))

function Table(data::NamedTuple)
    axs = (StructAxis{typeof(data)}(),)
    p = SVector(values(data))
    return Table(AxisArray{eltype(p),1,typeof(p),typeof(axs)}(p, axs))
end

function Table(data::AbstractDict{K,<:AbstractVector}) where {K}
    return Table(collect(values(data)), collect(keys(data)))
end

Table(table) = Table(TableTraitsUtils.create_columns_from_iterabletable(table)...)

Tables.materializer(x::Table) = Table

"""
    TableRow

A view of one row of an `AbstractTable`.
"""
struct TableRow{P,RA,T<:AbstractTable{P,RA}} <: AbstractTable{P,RA}
    row_index::Int
    parent::T
end

Base.parent(x::TableRow) = getfield(x, :parent)

row_index(x::TableRow) = getfield(x, :row_index)

Interface.colaxis(x::TableRow) = colaxis(parent(x))

# TODO should TableRow return a rowaxis
#AxisIndices.AxisCore.rowaxis(x::TableRow) = rowaxis(parent(x))

@propagate_inbounds function Base.getindex(x::TableRow, col)
    i = to_index(colaxis(x), col)
    return @inbounds(parent(parent(x))[i][row_index(x)])
end

@propagate_inbounds function Base.setindex!(x::TableRow, val, col)
    i = to_index(colaxis(x), col)
    @inbounds setindex!(parent(parent(x))[i], val, row_index(x))
end

Base.getproperty(x::TableRow, i) = getindex(x, i)

Base.getproperty(x::TableRow, i::Symbol) = getindex(x, i)

Base.setproperty!(x::TableRow, i::Symbol, val) = setindex!(x, val, i)

Base.propertynames(x::TableRow) = colkeys(x)

###
### Row Interface
###
Tables.rowaccess(::Type{<:AbstractTable}) = true

Tables.rows(x::AbstractTable) = x

Base.show(io::IO, ::MIME"text/plain", x::Table) = pretty_table(io, x)
Base.show(io::IO, ::MIME"text/plain", x::TableRow) = pretty_table(io, x)

end

