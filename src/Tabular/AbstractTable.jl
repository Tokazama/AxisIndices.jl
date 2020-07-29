
"""
    AbstractTable

Supertype for which tables that utilize an `AbstractAxis` interface for tabular data.
"""
abstract type AbstractTable{P,CA,RA} end

StaticRanges.axes_type(::Type{<:AbstractTable{P,CA,RA}}) where {P,CA,RA} = Tuple{CA,RA}

function StaticRanges.is_dynamic(::Type{<:AbstractTable{P,CA,RA}}) where {P,CA,RA}
    return is_dynamic(CA) || is_dynamic(RA)
end

function StaticRanges.is_static(::Type{<:AbstractTable{P,CA,RA}}) where {P,CA,RA}
    return is_static(CA) && is_static(RA)
end

function StaticRanges.is_fixed(::Type{<:AbstractTable{P,CA,RA}}) where {P,CA,RA}
    return !(is_dynamic(CA) || is_static(RA))
end




###
### Array Interface
###
@inline Base.eltype(::T) where {T<:AbstractTable} =  TableRow{T}

Base.axes(x::AbstractTable) = (row_axis(x), col_axis(x))

function Base.axes(x::AbstractTable, i::Int)
    if i === 1
        return row_axis(x)
    elseif i === 2
        return col_axis(x)
    else
        return SimpleAxis(Base.OneTo(1))
    end
end

Base.ndims(::T) where {T<:AbstractTable} = ndims(T)
Base.ndims(::Type{<:AbstractTable}) = 2

Base.size(x::AbstractTable) = (length(row_axis(x)), length(col_axis(x)))

function Base.size(x::AbstractTable, i::Int)
    if i === 1
        return length(row_axis(x))
    elseif i === 2
        return length(col_axis(x))
    else
        return 1
    end
end
@inline function Base.iterate(x::AbstractTable, st=1)
    if st > length(x)
        return nothing
    else
        return (TableRow(st, x), st + 1)
    end
end

Base.length(x::AbstractTable) = length(row_axis(x))

Interface.row_type(::Type{<:AbstractTable{P,RA,CA}}) where {P,RA,CA} = RA
Interface.col_type(::Type{<:AbstractTable{P,RA,CA}}) where {P,RA,CA} = CA

###
### Tables Interface
###
Tables.columnaccess(::Type{<:AbstractTable}) = true

# FIXME as soon as PrettyTables.jl updates get rid of Vector
Tables.columnnames(x::AbstractTable) = Vector(col_keys(x))

Tables.istable(::Type{<:AbstractTable}) = true

Tables.columns(x::AbstractTable) = x

Tables.schema(x::AbstractTable) = Tables.schema(typeof(x))
Tables.schema(::Type{T}) where {T<:AbstractTable} = Tables.schema(col_type(T))
@generated function Tables.schema(::Type{<:StructAxis{T}}) where {T}
    return Tables.Schema{Tuple(fieldnames(T)),Tuple{fieldtypes(T)...}}()
end

Tables.rowaccess(::Type{<:AbstractTable}) = true

Tables.rows(x::AbstractTable) = x

Base.isempty(x::AbstractTable) = length(col_axis(x)) == 0 || length(row_axis(x)) == 0

function Base.show(io::IO, ::MIME"text/plain", x::AbstractTable)
    print(io, "Table")
    if !isempty(x)
        print(io, "\n")
        pretty_table(io, x)
    end
end


