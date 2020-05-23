
function pretty_array_text(
    io,
    data::AbstractMatrix,
    row=axes(data, 1),
    col=axes(data, 2);
    #alignment=get_alignment(row, col),
    #cell_alignment=get_cell_alignment(row, col),
    border_crayon::Crayon =text_border_crayon(row, col),
    header_crayon::Union{Crayon,Vector{Crayon}} = text_header_crayon(col),
    subheader_crayon::Union{Crayon,Vector{Crayon}} = text_subheader_crayon(row, col),
    text_crayon::Crayon = get_text_crayon(row, col),
    #autowrap::Bool = get_autowrap(row, col),
    body_hlines::Vector{Int} = get_body_hlines(row, col),
    body_hlines_format::Union{Nothing,NTuple{4,Char}} = get_body_hlines_format(row, col),
    #crop::Symbol = get_crop(row, col),
    #columns_width::Union{Integer,AbstractVector{Int}} = get_columns_width(row, col),
    #highlighters::Union{Highlighter,Tuple} = text_highlighters(row, col),
    #linebreaks::Bool = get_linebreaks(row, col),
    #noheader::Bool = get_noheader(row, col),
    #nosubheader::Bool = get_nosubheader(row, col),
    rownum_header_crayon::Crayon = text_rownum_header_crayon(row),
    row_name_crayon::Crayon = text_row_name_crayon(row),
    #row_name_column_title=get_row_name_column_title(row),
    row_name_header_crayon::Crayon = text_row_name_header_crayon(row),
    #same_column_size::Bool = get_same_column_size(row, col),
    show_row_number::Bool = false,
    sortkeys::Bool = false,
    tf::TextFormat = text_format(row, col),
    hlines::Union{Nothing,Symbol,AbstractVector} = get_hlines(row, col),
    vlines::Union{Nothing,Symbol,AbstractVector} = get_vlines(row, col),
    formatters=get_formatters(data),
    kwargs...
)
    pretty_table(
        io,
        data,
        keys(col);
        #alignment=alignment,
        #cell_alignment=cell_alignment,
        row_names=keys(row),
        #row_name_column_title=row_name_column_title,
        border_crayon=border_crayon,
        header_crayon=header_crayon,
        subheader_crayon=subheader_crayon,
        rownum_header_crayon=rownum_header_crayon,
        text_crayon=text_crayon,
        #autowrap=autowrap,
        body_hlines=body_hlines,
        body_hlines_format=body_hlines_format,
        #crop=crop,
        #columns_width=columns_width,
        #highlighters=highlighters,
        #linebreaks=linebreaks,
        #noheader=noheader,
        #nosubheader=nosubheader,
        row_name_crayon=row_name_crayon,
        row_name_header_crayon=row_name_header_crayon,
        #same_column_size=same_column_size,
        tf=tf,
        hlines=hlines,
        vlines=vlines,
        formatters=formatters,
        kwargs...
    )
end

# this is necessary because otherwise pretty_table treats data as a matrix where
# each element is a field of the tuple element

function pretty_array_text(
    io,
    data::AbstractVector{T},
    row=axes(data, 1);
    kwargs...
) where {T<:NamedTuple}

    return pretty_array_text(io, reshape(data, :, 1), row, Base.OneTo(1); kwargs...)
end

function pretty_array_text(
    io,
    data::AbstractVector,
    row=axes(data, 1);
    col=Base.OneTo(1),
    #alignment=get_alignment(row, col),
    #cell_alignment=get_cell_alignment(row, col),
    border_crayon::Crayon =text_border_crayon(row, col),
    header_crayon::Union{Crayon,Vector{Crayon}} = text_header_crayon(col),
    subheader_crayon::Union{Crayon,Vector{Crayon}} = text_subheader_crayon(row, col),
    text_crayon::Crayon = get_text_crayon(row, col),
    #autowrap::Bool = get_autowrap(row, col),
    body_hlines::Vector{Int} = get_body_hlines(row, col),
    body_hlines_format::Union{Nothing,NTuple{4,Char}} = get_body_hlines_format(row, col),
    #crop::Symbol = get_crop(row, col),
    #columns_width::Union{Integer,AbstractVector{Int}} = get_columns_width(row, col),
    #highlighters::Union{Highlighter,Tuple} = text_highlighters(row, col),
    #linebreaks::Bool = get_linebreaks(row, col),
    #noheader::Bool = get_noheader(row, col),
    #nosubheader::Bool = get_nosubheader(row, col),
    rownum_header_crayon::Crayon = text_rownum_header_crayon(row),
    row_name_crayon::Crayon = text_row_name_crayon(row),
    #row_name_column_title=get_row_name_column_title(row),
    row_name_header_crayon::Crayon = text_row_name_header_crayon(row),
    #same_column_size::Bool = get_same_column_size(row, col),
    show_row_number::Bool = false,
    sortkeys::Bool = false,
    tf::TextFormat = text_format(row, col),
    hlines::Union{Nothing,Symbol,AbstractVector} = get_hlines(row, col),
    vlines::Union{Nothing,Symbol,AbstractVector} = get_vlines(row, col),
    formatters=get_formatters(data),
    kwargs...
)
    pretty_table(
        io,
        data,
        [""];
        #alignment=alignment,
        #cell_alignment=cell_alignment,
        row_names=keys(row),
        #row_name_column_title=row_name_column_title,
        border_crayon=border_crayon,
        header_crayon=header_crayon,
        subheader_crayon=subheader_crayon,
        rownum_header_crayon=rownum_header_crayon,
        text_crayon=text_crayon,
        #autowrap=autowrap,
        body_hlines=body_hlines,
        body_hlines_format=body_hlines_format,
        #crop=crop,
        #columns_width=columns_width,
        #highlighters=highlighters,
        #linebreaks=linebreaks,
        #noheader=noheader,
        #nosubheader=nosubheader,
        row_name_crayon=row_name_crayon,
        row_name_header_crayon=row_name_header_crayon,
        #same_column_size=same_column_size,
        tf=tf,
        hlines=hlines,
        vlines=vlines,
        formatters=formatters,
        kwargs...
    )
end

text_format(row, col) = TextFormat(borderless, hlines=Symbol[])
text_rownum_header_crayon(row) = Crayon(bold = true)

#=
    text_highlighters(row, col) -> Tuple

An instance of `Highlighter` or a tuple with a list of text highlighters (see the
section `Text highlighters`)

text_highlighters(row::AbstractUnitRange, col::AbstractUnitRange) = ()
=#

#=
    text_row_name_crayon(x) -> Crayon
=#
text_row_name_crayon(row::AbstractUnitRange) = Crayon(bold = true)

#=
    text_header_crayon(x) -> Crayon

Crayon to print the header.
=#
text_header_crayon(col::AbstractUnitRange) = Crayon(bold = true)

#=
    rownum_header_crayon

Crayon for the header of the column with the row numbers.
=#
text_row_name_header_crayon(row::AbstractUnitRange) = Crayon(bold = true)

#=
    subheaders_crayon(row, col)

Crayon to print sub-headers.
=#
text_subheader_crayon(row, col) = Crayon(foreground = :dark_gray)

#=
    get_text_crayon(row, col) -> Crayon

Crayon to print default text.
=#
get_text_crayon(row, col) = Crayon()


#=
    get_autowrap(x) -> Bool

If `true`, then the text will be wrapped on spaces to fit the column. Notice that
this function requires `linebreaks = true` and the column must have a fixed size
(see `columns_width`).

get_autowrap(row::AbstractUnitRange, col::AbstractUnitRange) = false
=#

#=
    text_border_crayon(row, col)

Sets default for `Crayon` that prints border.
=#
text_border_crayon(row::AbstractUnitRange, col::AbstractUnitRange) = Crayon()


#=
    get_vlines

This variable controls where the vertical lines will be drawn.
It can be `nothing`, `:all`, `:none` or a vector of integers.
=#
get_vlines(row::AbstractUnitRange, col::AbstractUnitRange) = nothing

#=
    get_hlines(row, col)

This variable controls where the horizontal lines will be drawn.
It can be `nothing`, `:all`, `:none` or a vector of integers.
=#
get_hlines(row::AbstractUnitRange, col::AbstractUnitRange) = nothing

#=
    get_linebreaks(x) -> Bool

If `true`, then `\\n` will break the line inside the cells. (**Default** = `false`)

get_linebreaks(row::AbstractUnitRange, col::AbstractUnitRange) = false
=#

#=
    get_noheader(x) -> Bool

If `true`, then the header will not be printed. Notice that all keywords and
parameters related to the header and sub-headers will be ignored. (**Default** = `false`)

get_noheader(row::AbstractUnitRange, col::AbstractUnitRange) = false
=#

#=
    get_nosubheader -> Bool

If `true`, then the sub-header will not be printed, *i.e.* the header will contain
only one line. Notice that this option has no effect if `noheader = true`.
(**Default** = `false`)

get_nosubheader(row::AbstractUnitRange, col::AbstractUnitRange) = false
=#

#=
    get_same_column_size -> Bool

If `true`, then all the columns will have the same size. (**Default** = `false`)

get_same_column_size(row::AbstractUnitRange, col::AbstractUnitRange) = false
=#

#=
    get_columns_width(row, col)

A set of integers specifying the width of each column. If the width is equal or
lower than 0, then it will be automatically computed to fit the large cell in
the column. If it is a single integer, then this number will be used as the size
of all columns. (**Default** = 0)

get_columns_width(row::AbstractUnitRange, col::AbstractUnitRange) = 0
=#

#=
    get_crop(row, col)

Select the printing behavior when the data is bigger than the available screen
size (see `screen_size`). It can be `:both` to crop on vertical and horizontal
direction, `:horizontal` to crop only on horizontal direction, `:vertical` to
crop only on vertical direction, or `:none` to do not crop the data at all.
=#
#get_crop(row::AbstractUnitRange, col::AbstractUnitRange) = :both

#=

    get_body_hlines_format(row, col)

A tuple of 4 characters specifying the format of the
horizontal lines that will be drawn by `body_hlines`.
The characters must be the left intersection, the middle
intersection, the right intersection, and the row. If it
is `nothing`, then it will use the same format specified
in `tf`. (**Default** = `nothing`)
=#
get_body_hlines_format(row::AbstractUnitRange, col::AbstractUnitRange) = nothing

#=
    get_body_hlines(x)

A vector of `Int` indicating row numbers in which an additional horizontal line
should be drawn after the row. Notice that numbers lower than 1 and equal or
higher than the number of printed rows will be neglected. This vector will be
appended to the one in `hlines`, but the indices here are related to the printed
rows of the body. Thus, if `1` is added to `body_hlines`, then a horizontal line
will be drawn after the first data row. (**Default** = `Int[]`)
=#
get_body_hlines(row::AbstractUnitRange, col::AbstractUnitRange) = Int[]

