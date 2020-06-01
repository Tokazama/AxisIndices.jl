
function check_rows_length(x::AbstractVector{<:AbstractVector}, raxis::AbstractAxis)
    nr = length(raxis)
    for x_i in x
        length(x_i) == nr || error("All columns must have the same number of rows.")
    end
    return nothing
end

function check_cols_length(x::AbstractVector{<:AbstractVector}, caxis::AbstractAxis)
    length(caxis) == length(x) || error("Column axis must have the same length as the number of columns.")
    return nothing
end

check_cols_type(x::AbstractVector{<:AbstractVector}, caxis::AbstractAxis) = nothing

function check_cols_type(x::AbstractVector{<:AbstractVector}, caxis::StructAxis)
    @inbounds for i in axes(x)
        eltype(x[i]) <: axis_eltype(caxis, i) || error("Specified eltypes and column eltypes don't match.")
    end
    return nothing
end

function _create_colaxis(x::AbstractVector{<:AbstractVector}, caxis::AbstractAxis)
    check_cols_length(x, caxis)
    return caxis
end

function _create_colaxis(x::AbstractVector{<:AbstractVector}, caxis::AbstractVector{Symbol})
    return _create_colaxis(x, to_axis(caxis, indices(x, 1)))
end

function _create_colaxis(x::AbstractVector{<:AbstractVector}, ::Type{T}) where {T}
    return StructAxis{T}(indices(x, 1))
end

function _create_colaxis(x::AbstractVector{<:AbstractVector}, ::Nothing)
    return _create_colaxis(x, rowkeys(x))
end

function _create_colaxis(x::AbstractVector{<:AbstractVector}, caxis::AbstractVector{<:Integer})
    return to_axis([Symbol(:x, col_i) for col_i in caxis], indices(x, 1))
end

# TODO
function _create_rowaxis(x::AbstractVector{<:AbstractVector}, ::Nothing)
    return _create_rowaxis(x, to_axis(axes(first(x), 1)))
end

function _create_rowaxis(x::AbstractVector{<:AbstractVector}, raxis::AbstractAxis)
    check_rows_length(x, raxis)
    return raxis
end

"""
    Table

Stores a vector of columns that may be acccessed via the Tables.jl interface.
"""
struct Table{P<:AbstractVector{<:AbstractVector},RA,CA} <: AbstractTable{P,RA,CA}
    parent::P
    rowaxis::RA
    colaxis::CA

    function Table{P,RA,CA}(x::P, raxis::RA, caxis::CA) where {P,RA,CA}
        check_cols_type(x, caxis)
        return new{P,RA,CA}(x, raxis, caxis)
    end


    function Table(x::AbstractVector{<:AbstractVector}, raxis::AbstractAxis, caxis::AbstractAxis)
        return Table{typeof(x),typeof(raxis),typeof(caxis)}(x, raxis, caxis)
    end

    function Table(x::AbstractMatrix, raxis::AbstractAxis, caxis::AbstractAxis)
        if size(x, 1) != length(raxis)
            error("Got size(data, 1) = $(size(x, 1)) and length(rowaxis) = $(length(raxis))")
        end
        if size(x, 2) != length(caxis)
            error("Got size(data, 2) = $(size(x, 2)) and length(colaxis) = $(length(caxis))")
        end
        data = Vector{Vector{T}}(undef, size(x, 2))
        @inbounds for i in axes(x, 2)
            data[i] = x[:,i]
        end
        Table{Vector{AbstractVector},typeof(raxis),typeof(caxis)}(data, raxis, caxis)
    end

    function Table(x::AbstractVector{<:AbstractVector}; rowaxis=nothing, colaxis=nothing)
        caxis = _create_colaxis(x, colaxis)
        raxis = _create_rowaxis(x, rowaxis)
        return Table{typeof(x),typeof(raxis),typeof(caxis)}(x, raxis, caxis)
    end

    function Table(x::AxisVector{<:Any,<:AbstractVector{<:AbstractVector}}; rowaxis=nothing, colaxis=nothing)
        caxis = _create_colaxis(x, colaxis)
        raxis = _create_rowaxis(x, rowaxis)
        return Table{parent_type(x),typeof(raxis),typeof(caxis)}(parent(x), raxis, caxis)
    end

    function Table(x::AxisArray{<:AbstractVector,1})
        return Table(parent(x), to_axis(axes(first(x), 1)), axes(x, 1))
    end

    Table(data::NamedTuple) = Table([d for d in data], [keys(data)...])

    function Table(data::NamedTuple{(),Tuple{}})
        Table{Vector{AbstractVector},
              SimpleAxis{Int,OneToMRange{Int}},
              Axis{Symbol,Int,Vector{Symbol},OneToMRange{Int}}
        }(
            AbstractVector[],
            SimpleAxis(OneToMRange(0)),
            Axis(Symbol[], OneToMRange(0))
        )
    end

    Table(; kwargs...) = Table(values(kwargs))

    function Table(data::AbstractDict{K,<:AbstractVector}) where {K}
        ks = K[]
        new_data = AbstractVector[]
        for (k,v) in data
            push!(ks, k)
            push!(new_data, v)
        end
        caxis = Axis(ks)
        raxis = _create_rowaxis(new_data, nothing)
        return Table{typeof(new_data),typeof(raxis),typeof(caxis)}(new_data, raxis, caxis)
    end

    function Table(data::Pair{K,<:AbstractVector}...) where {K}
        ks = K[]
        new_data = AbstractVector[]
        for p_i in data
            k, v = p_i
            push!(ks, k)
            push!(new_data, v)
        end
        caxis = Axis(ks)
        raxis = _create_rowaxis(new_data, nothing)
        return Table{typeof(new_data),typeof(raxis),typeof(caxis)}(new_data, raxis, caxis)
    end

    Table(table) = Table(TableTraitsUtils.create_columns_from_iterabletable(table)...)

end

Base.parent(x::Table) = getfield(x, :parent)

Interface.rowaxis(x::Table) = getfield(x, :rowaxis)

Interface.colaxis(x::Table) = getfield(x, :colaxis)

Base.getproperty(x::Table, i) = getindex(x, :, i)

Base.getproperty(x::Table, i::Symbol) = getindex(x, :, i)

Base.setproperty!(x::Table, i::Symbol, val) = setindex!(x, val, :, i)

Base.propertynames(x::Table) = colkeys(x)

Table(x::AbstractVector{<:AbstractVector}, ks::AbstractVector) = Table(AxisArray(x, ks))

Tables.materializer(x::Table) = Table

