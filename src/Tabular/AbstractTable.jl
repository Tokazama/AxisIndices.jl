
"""
    AbstractTable

Supertype for which tables that utilize an `AbstractAxis` interface for tabular data.
"""
abstract type AbstractTable{P,CA,RA} end

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
@inline function Base.iterate(x::AbstractTable, st=1)
    if st > length(x)
        return nothing
    else
        return (TableRow(st, x), st + 1)
    end
end

Base.length(x::AbstractTable) = length(rowaxis(x))

Interface.rowtype(::Type{<:AbstractTable{P,RA,CA}}) where {P,RA,CA} = RA
Interface.coltype(::Type{<:AbstractTable{P,RA,CA}}) where {P,RA,CA} = CA

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

Tables.rowaccess(::Type{<:AbstractTable}) = true

Tables.rows(x::AbstractTable) = x

Base.isempty(x::AbstractTable) = length(colaxis(x)) == 0 || length(rowaxis(x)) == 0

function Base.show(io::IO, ::MIME"text/plain", x::AbstractTable)
    print(io, "Table")
    if !isempty(x)
        print(io, "\n")
        pretty_table(io, x)
    end
end

StaticRanges.Staticness(::Type{<:AbstractTable{P}}) where {P} = StaticRanges.Staticness(P)

