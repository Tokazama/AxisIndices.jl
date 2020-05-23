
# TODO indexing needs more consistent system
# - get generators working with AxisIndices
module AxisTables

using AxisIndices
using AxisIndices.AxisCore
using StaticArrays
using AxisIndices.AxisCore: is_element, unsafe_getindex
using PrettyTables

using Tables
using TableTraits
using TableTraitsUtils

using Base: @propagate_inbounds

export AxisTable, AxisRow

abstract type AbstractAxisTable end

###
### Array Interface
###
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
    return get_index(parent(x), rowaxis(x), colaxis(x), arg1, arg2)
end

@propagate_inbounds function get_index(data, raxis, caxis, arg1, arg2)
    return _unsafe_getindex(data, raxis, caxis, arg1, arg2, to_index(raxis, arg1), to_index(caxis, arg2))
end

@inline function _unsafe_getindex(data, raxis, caxis, arg1, arg2, i1::Integer, i2::Integer)
    return unsafe_getindex(unsafe_getindex(data, (arg2,), (i2,)), (arg1,), (i1,))
end

@inline function _unsafe_getindex(data, raxis, caxis, arg1, arg2, i1::Integer, i2::AbstractVector)
    return [unsafe_getindex(unsafe_getindex(data, (arg2,), (i,)), (arg1,), (i1,)) for i in i2]
end

@inline function _unsafe_getindex(data, raxis, caxis, arg1, arg2, i1::AbstractVector, i2::Integer)
    return @inbounds(getindex(unsafe_getindex(data, (arg2,), (i2,)), i1))
end

@inline function _unsafe_getindex(data, raxis, caxis, arg1, arg2, i1::AbstractVector, i2::AbstractVector)
    return AxisTable([@inbounds(getindex(unsafe_getindex(data, (arg2,), (i,)), i1)) for i in i2], caxis[i2])
end

@inline function Base.iterate(x::AbstractAxisTable, st=1)
    if st > length(x)
        return nothing
    else
        return (AxisRow(st, x), st + 1)
    end
end

Base.length(x::AbstractAxisTable) = length(rowaxis(x))

AxisIndices.AxisCore.colaxis(x::AbstractAxisTable) = axes(parent(x), 1)

###
### AxisTable
###
struct AxisTable{T<:AbstractVector,V<:AbstractVector{T},RA<:AbstractAxis,CA} <: AbstractAxisTable
    parent::AxisIndicesArray{T,1,V,Tuple{CA}}
    rowaxis::RA

    function AxisTable{T,V,RA,CA}(x::AxisIndicesArray{T,1,V,Tuple{CA}}, raxis::RA) where {T,V,RA<:AbstractAxis,CA}
        if length(x) > 1
            nr = length(raxis)
            for x_i in x
                nr == length(x_i) || error("All columns must be the same length.")
            end
        end
        return new{T,V,RA,CA}(x, raxis)
    end

end

Base.getproperty(x::AxisTable, i) = getindex(x, :, i)

Base.getproperty(x::AxisTable, i::Symbol) = getindex(x, :, i)

Base.setproperty!(x::AxisTable, i, val) = setindex!(x, val, :, i)

Base.propertynames(x::AxisTable) = colkeys(x)

Base.parent(x::AxisTable) = getfield(x, :parent)

AxisIndices.AxisCore.rowaxis(x::AxisTable) = getfield(x, :rowaxis)

function AxisTable(x::AxisIndicesArray{T,1,V,Tuple{CA}}, raxis::RA) where {T,V,RA<:AbstractAxis,CA}
    return AxisTable{T,V,RA,CA}(x, raxis)
end

function AxisTable(x::AxisIndicesArray{<:AbstractVector,1})
    return AxisTable(x, AxisIndices.AxisCore.to_axis(axes(first(x), 1)))
end

AxisTable(; kwargs...) = AxisTable(values(kwargs))

function AxisTable(x::AbstractVector{<:AbstractVector}, ks::AbstractVector)
    return AxisTable(AxisIndicesArray(x, ks))
end

function AxisTable(data::NamedTuple)
    axs = (StructAxis{typeof(data)}(),)
    p = SVector(values(data))
    return AxisTable(AxisIndicesArray{eltype(p),1,typeof(p),typeof(axs)}(p, axs))
end

function AxisTable(data::AbstractDict{K,<:AbstractVector}) where {K}
    return AxisTable(collect(values(data)), collect(keys(data)))
end

AxisTable(table) = AxisTable(TableTraitsUtils.create_columns_from_iterabletable(table)...)

Tables.istable(::Type{<:AxisTable}) = true

# FIXME
Tables.schema(x::AxisTable{T}) where {T} = Tables.Schema(colkeys(x), fill(T, size(x, 2)))

###
### Column Interface
###
Tables.columnaccess(::Type{<:AbstractAxisTable}) = true

Tables.columns(x::AbstractAxisTable) = x
# required Tables.AbstractColumns object methods
function Tables.getcolumn(x::AbstractAxisTable, ::Type{T}, col::Int, nm::Symbol) where {T}
    return getindex(x, :, col)
end

Tables.getcolumn(x::AbstractAxisTable, nm::Symbol) = getindex(x, :, nm)
Tables.getcolumn(x::AbstractAxisTable, i::Int) = getindex(x, :, i)
Tables.getcolumn(x::AbstractAxisTable, i) = getindex(x, :, i)

Tables.columnnames(x::AbstractAxisTable) = colkeys(x)

Base.eltype(x::A) where {A<:AbstractAxisTable} = AxisRow{A}

# FIXME This is suppose to be AxisRow
#Base.eltype(::Type{<:AxisTable{T}}) where {T} = T

###
### Row Interface
###
Tables.rowaccess(::Type{<:AbstractAxisTable}) = true

Tables.rows(x::AbstractAxisTable) = x

struct AxisRow{P<:AbstractAxisTable}
    row_index::Int
    parent::P
end

AxisIndices.AxisCore.colaxis(x::AxisRow) = colaxis(parent(x))

AxisIndices.AxisCore.rowaxis(x::AxisRow) = rowaxis(parent(x))

@propagate_inbounds function Base.getindex(x::AxisRow, col)
    return get_row_index(parent(parent(x)), rowaxis(x), colaxis(x), row_index(x), col)
end

@propagate_inbounds function get_row_index(data, rax, cax, i1, i2)
    return _get_row_index(data, rax, cax, i1, to_index(cax, i2))
end

Base.parent(x::AxisRow) = getfield(x, :parent)

row_index(x::AxisRow) = getfield(x, :row_index)

Tables.getcolumn(x::AxisRow, ::Type, col::Int, nm::Symbol) = getindex(x, col)
Tables.getcolumn(x::AxisRow, i::Integer) = getindex(parent(x), row_index(x), i)
Tables.getcolumn(x::AxisRow, i::Symbol) = getindex(parent(x), row_index(x), i)
Tables.getcolumn(x::AxisRow, i) = getindex(x, i)

Tables.columnnames(x::AxisRow) = Tables.columnames(parent(x))

Tables.materializer(x::AxisTable) = AxisTable

Base.show(io::IO, ::MIME"text/plain", x::AxisTable) = pretty_table(io, x)

end

