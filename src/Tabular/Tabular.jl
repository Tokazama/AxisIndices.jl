
# TODO indexing needs more consistent system
# - get generators working with AxisIndices
module Tabular

using StaticArrays
using AxisIndices.Interface
using AxisIndices.Interface: is_element, to_index

using AxisIndices.Axes

using AxisIndices.Arrays
using AxisIndices.Arrays: unsafe_getindex

using PrettyTables
using Tables
using TableTraits
using TableTraitsUtils

using Base: @propagate_inbounds

export AxisTable, AxisRow

"""
    AbstractAxisTable

Supertype for which tables that utilize an `AbstractAxis` interface for tabular data.
"""
abstract type AbstractAxisTable{T,RA} end

###
### Array Interface
###
@inline Base.eltype(::T) where {T<:AbstractAxisTable} =  AxisRow{T}

Base.axes(x::AbstractAxisTable) = (rowaxis(x), colaxis(x))

function Base.axes(x::AbstractAxisTable, i::Int)
    if i === 1
        return rowaxis(x)
    elseif i === 2
        return colaxis(x)
    else
        return SimpleAxis(Base.OneTo(1))
    end
end

Base.ndims(::T) where {T<:AbstractAxisTable} = ndims(T)
Base.ndims(::Type{<:AbstractAxisTable}) = 2

Base.size(x::AbstractAxisTable) = (length(rowaxis(x)), length(colaxis(x)))

function Base.size(x::AbstractAxisTable, i::Int)
    if i === 1
        return length(rowaxis(x))
    elseif i === 2
        return length(colaxis(x))
    else
        return 1
    end
end

@propagate_inbounds function Base.getindex(x::AbstractAxisTable, arg1, arg2)
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

_unsafe_getindex(x, raxis, caxis, arg1, arg2, i1::Integer, i2::Base.Slice) = AxisRow(i1, x)

@inline function _unsafe_getindex(x, raxis, caxis, arg1, arg2, i1::AbstractVector, i2::Integer)
    return @inbounds(getindex(unsafe_getindex(parent(x), (arg2,), (i2,)), i1))
end

@inline function _unsafe_getindex(x, raxis, caxis, arg1, arg2, i1::AbstractVector, i2::AbstractVector)
    return AxisTable([@inbounds(getindex(unsafe_getindex(parent(x), (arg2,), (i,)), i1)) for i in i2], caxis[i2])
end

@propagate_inbounds function Base.setindex!(x::AbstractAxisTable, vals, arg1, arg2)
    setindex!(getindex(parent(x), to_index(colaxis(x), arg2)), vals, to_index(rowaxis(x), arg1))
end

@inline function Base.iterate(x::AbstractAxisTable, st=1)
    if st > length(x)
        return nothing
    else
        return (AxisRow(st, x), st + 1)
    end
end

Base.length(x::AbstractAxisTable) = length(rowaxis(x))

Interface.rowtype(::Type{<:AbstractAxisTable{T,RA}}) where {T,RA} = RA
Interface.coltype(::Type{<:AbstractAxisTable{T}}) where {T} = rowtype(T)
Interface.colaxis(x::AbstractAxisTable) = axes(parent(x), 1)

###
### Tables Interface
###
Tables.columnaccess(::Type{<:AbstractAxisTable}) = true

# FIXME as soon as PrettyTables.jl updates get rid of Vector
Tables.columnnames(x::AbstractAxisTable) = Vector(colkeys(x))

Tables.istable(::Type{<:AbstractAxisTable}) = true

Tables.columns(x::AbstractAxisTable) = x

Tables.schema(x::AbstractAxisTable) = Tables.schema(typeof(x))
Tables.schema(::Type{T}) where {T<:AbstractAxisTable} = Tables.schema(coltype(T))
@generated Tables.schema(::Type{<:StructAxis{T}}) where {T} = Tables.Schema{Tuple(fieldnames(T)),Tuple{fieldtypes(T)...}}()

"""
    AxisTable

Stores a vector of columns that may be acccessed via the Tables.jl interface.
"""
struct AxisTable{P<:AxisArray{<:Any,1},RA} <: AbstractAxisTable{P,RA}
    parent::P
    rowaxis::RA

    function AxisTable{P,RA}(x::P, raxis::RA) where {P<:AxisArray{<:Any,1},RA<:AbstractAxis}
        if length(x) > 1
            nr = length(raxis)
            for x_i in x
                nr == length(x_i) || error("All columns must be the same length.")
            end
        end
        return new{P,RA}(x, raxis)
    end
end

Base.getproperty(x::AxisTable, i) = getindex(x, :, i)

Base.getproperty(x::AxisTable, i::Symbol) = getindex(x, :, i)

Base.setproperty!(x::AxisTable, i, val) = setindex!(x, val, :, i)

Base.propertynames(x::AxisTable) = colkeys(x)

Base.parent(x::AxisTable) = getfield(x, :parent)

Interface.rowaxis(x::AxisTable) = getfield(x, :rowaxis)

function AxisTable(x::T, raxis::RA) where {T<:AxisArray{<:Any,1},RA<:AbstractAxis}
    return AxisTable{T,RA}(x, raxis)
end

function AxisTable(x::AxisArray{<:AbstractVector,1})
    return AxisTable(x, to_axis(axes(first(x), 1)))
end

AxisTable(; kwargs...) = AxisTable(values(kwargs))

function AxisTable(x::AbstractVector{<:AbstractVector}, ks::AbstractVector)
    return AxisTable(AxisArray(x, ks))
end

function AxisTable(data::NamedTuple)
    axs = (StructAxis{typeof(data)}(),)
    p = SVector(values(data))
    return AxisTable(AxisArray{eltype(p),1,typeof(p),typeof(axs)}(p, axs))
end

function AxisTable(data::AbstractDict{K,<:AbstractVector}) where {K}
    return AxisTable(collect(values(data)), collect(keys(data)))
end

AxisTable(table) = AxisTable(TableTraitsUtils.create_columns_from_iterabletable(table)...)

Tables.materializer(x::AxisTable) = AxisTable

"""
    AxisRow

A view of one row of an `AbstractAxisTable`.
"""
struct AxisRow{P,RA,T<:AbstractAxisTable{P,RA}} <: AbstractAxisTable{P,RA}
    row_index::Int
    parent::T
end

Base.parent(x::AxisRow) = getfield(x, :parent)

row_index(x::AxisRow) = getfield(x, :row_index)

Interface.colaxis(x::AxisRow) = colaxis(parent(x))

# TODO should AxisRow return a rowaxis
#AxisIndices.AxisCore.rowaxis(x::AxisRow) = rowaxis(parent(x))

@propagate_inbounds function Base.getindex(x::AxisRow, col)
    i = to_index(colaxis(x), col)
    return @inbounds(parent(parent(x))[i][row_index(x)])
end

@propagate_inbounds function Base.setindex!(x::AxisRow, val, col)
    i = to_index(colaxis(x), col)
    @inbounds setindex!(parent(parent(x))[i], val, row_index(x))
end

Base.getproperty(x::AxisRow, i) = getindex(x, i)

Base.getproperty(x::AxisRow, i::Symbol) = getindex(x, i)

Base.setproperty!(x::AxisRow, i::Symbol, val) = setindex!(x, val, i)

Base.propertynames(x::AxisRow) = colkeys(x)

###
### Row Interface
###
Tables.rowaccess(::Type{<:AbstractAxisTable}) = true

Tables.rows(x::AbstractAxisTable) = x

Base.show(io::IO, ::MIME"text/plain", x::AxisTable) = pretty_table(io, x)
Base.show(io::IO, ::MIME"text/plain", x::AxisRow) = pretty_table(io, x)

end

