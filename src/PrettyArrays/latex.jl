

function pretty_latex_array(
    io,
    data;
    tf::LatexTableFormat = latex_default,
    cell_alignment::Dict{Tuple{Int,Int},Symbol} = Dict{Tuple{Int,Int},Symbol}(),
    highlighters::Union{LatexHighlighter,Tuple} = (),
    hlines::AbstractVector{Int} = Int[],
    longtable_footer::Union{Nothing,AbstractString} = nothing,
    noheader::Bool = false,
    nosubheader::Bool = false,
    show_row_number::Bool = false,
    table_type::Symbol = :tabular,
    vlines::Union{Symbol,AbstractVector} = :none,
    # Deprecated
    formatter = nothing
)

    return pretty_table(
        io,
        data;
        tf=tf,
        cell_alignment=cell_alignment,
        highlighters=highlighters,
        hlines=hlines,
        longtable_footer=longtable_footer,
        noheader=noheader,
        nosubheader=nosubheader,
        show_row_number=show_row_number,
        table_type=table_type,
        vlines=vlines,
    )
end

