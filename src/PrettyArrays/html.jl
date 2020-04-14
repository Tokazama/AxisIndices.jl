
"""
    get_html_format -> HTMLTableFormat
"""
get_html_format(x) = get_html_format(axes(x, 1), axes(x, 2))
get_html_format(row::AbstractUnitRange, col::AbstractUnitRange) = HTMLTableFormat()

function pretty_html_array(
    io::IO,
    data;
    tf::HTMLTableFormat = html_default,
    highlighters::Union{HTMLHighlighter,Tuple} = (),
    linebreaks::Bool = get_linebreaks(data),
    noheader::Bool = get_noheader(data),
    nosubheader::Bool = get_nosubheader(data),
    show_row_number::Bool = get_show_row_number(data),
    standalone::Bool = get_standalone(data),
)

    pretty_table(
        io,
        data;
        tf=tf,
        highlighters=highlighters,
        linebreaks=linebreaks,
        noheader=noheader,
        nosubheader=nosubheader,
        show_row_number=show_row_number,
        standalone=standalone
    )
end

