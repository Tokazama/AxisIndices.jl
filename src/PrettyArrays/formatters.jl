
#=
    get_row_filters

Filters for the rows.
=#
get_row_filters(row::AbstractUnitRange) = nothing

#=
    get_col_filters

Filters for the rows.
=#
get_col_filters(row::AbstractUnitRange) = nothing


#=
    get_row_name_alignment

Alignment of the column with the rows name (see the section Alignment).
=#
get_row_name_alignment(row::AbstractUnitRange) = :r

#=
    get_row_name_column_title(x)

Title of the column with the row names. (Default = "")
=#
get_row_name_column_title(row::AbstractUnitRange) = ""

#=
    get_alignment

Select the alignment of the columns.
=#
get_alignment(row::AbstractUnitRange, col::AbstractUnitRange) = :r


#=
    get_cell_alignment(x)

Sets the default `cell_alignment` argument for `prety_array` depending on `x`.
=#
get_cell_alignment(row::AbstractUnitRange, col::AbstractUnitRange) = nothing


"""
    get_formatters(x)

Returns an argument for the `formatters` argument of a `pretty_table` method.
"""
get_formatters(x::AbstractArray{T}) where {T} = nothing


