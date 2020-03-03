
function row_formatter(
    data;
    bold=true,
    kwargs...
)

    return Highlighter(
        f = (data, i, j) -> j == 1,
        crayon = Crayon(; bold=bold, kwargs...)
    )
end

function Base.show(io::IO,
    m::MIME"text/plain",
    A::AbstractAxisIndices{T,N},
    key_names::Tuple=axes_keys(A),
    dnames=ntuple(i -> "dim$i", N),
    pre_rowname="",
    post_rowname="",
    row_colname="",
    vec_colname="",
    tf=array_text_format,
    formatter=ft_printf("%5.3f"),
    kwargs...
) where {T,N}

    println(io, "$N-dimensional $(typeof(A).name.name){$T,$N,$(parent_type(A))...}")
    return pretty_array(
        io,
        parent(A),
        key_names; 
        dnames=dnames,
        vec_colname=vec_colname,
        row_colname=row_colname,
        post_rowname=post_rowname,
        pre_rowname=pre_rowname,
        tf=tf,
        formatter=formatter,
        kwargs...
    )
end

const array_text_format = TextFormat(
    up_right_corner = ' ',
    up_left_corner = ' ',
    bottom_left_corner=' ',
    bottom_right_corner= ' ',
    up_intersection= ' ',
    left_intersection= ' ',
    right_intersection= ' ',
    middle_intersection= ' ',
    bottom_intersection= ' ',
    column= ' ',
    left_border= ' ',
    right_border= ' ',
    row= ' ',
    top_line=false,
    header_line=false,
    bottom_line=false
)

function pretty_array(
    io::IO,
    A::AbstractArray{T,N},
    key_names::Tuple=map(keys, axes(A));
    dnames=ntuple(i -> "dim$i", N),
    pre_rowname="( ",
    post_rowname=" )",
    row_colname="",
    vec_colname="",
    tf=array_text_format,
    formatter=ft_printf("%5.3f"),
    kwargs...
) where {T,N}

    limit::Bool = get(io, :limit, false)
    if isempty(A)
        return
    end
    tailinds = tail(tail(axes(A)))
    keyinds = tail(tail(key_names))
    nd = ndims(A)-2
    for I in CartesianIndices(tailinds)
        idxs = I.I
        if limit
            for i = 1:nd
                ii = idxs[i]
                ind = tailinds[i]
                if length(ind) > 10
                    if ii == ind[firstindex(ind)+3] && all(d-> idxs[d] == first(tailinds[d]), 1:i-1)
                        for j=i+1:nd
                            szj = length(axes(A, j+2))
                            indj = tailinds[j]
                            if szj > 10 && first(indj)+2 < idxs[j] <= last(indj)-3
                                @goto skip
                            end
                        end
                        #println(io, idxs)
                        print(io, "...\n\n")
                        @goto skip
                    end
                    if ind[firstindex(ind) + 2] < ii <= ind[end - 3]
                        @goto skip
                    end
                end
            end
        end

        print(io, "[$(dnames[1]), $(dnames[2]), ")
        for i in 1:(nd-1)
            print(io, "$(dnames[i])[$(keyinds[i][idxs[i]])], ")
        end
        println(io, "$(dnames[end])[", keyinds[end][idxs[end]], "]] =")
        pretty_array(
            io,
            view(A, axes(A,1), axes(A,2), idxs...),
            keyinds;
            dnames=dnames,
            vec_colname=vec_colname,
            row_colname=row_colname,
            post_rowname=post_rowname,
            pre_rowname=pre_rowname,
            tf=tf,
            formatter=formatter,
            kwargs...
        )
        print(io, idxs == map(last,tailinds) ? "" : "\n\n")
        @label skip
    end
end

function pretty_array(
    io::IO,
    x::AbstractVecOrMat,
    key_names::Tuple;
    dnames=("dim1", "dim2"),
    row_colname="",
    vec_colname="",
    pre_rowname="( ",
    post_rowname=" )",
    kwargs...
   )
    if ndims(x) == 1
        data = combine_rows_to_matrix(x, first(key_names), pre_rowname, post_rowname)
        return pretty_table(
            io,
            data,
            [row_colname, ""];
            highlighters=row_formatter(data),
            kwargs...
        )
    else
        data = combine_rows_to_matrix(x, first(key_names), pre_rowname, post_rowname)
        return pretty_table(
            io,
            data,
            vcat(row_colname, string.(last(key_names)));
            highlighters=row_formatter(data),
            kwargs...
        )
    end
end

function combine_rows_to_matrix(x, key_names::LinearIndices, pre_rowname, post_rowname)
    return combine_rows_to_matrix(x, key_names.indices[1], pre_rowname, post_rowname)
end

function combine_rows_to_matrix(x, key_names, pre_rowname, post_rowname)
    return hcat(
        [pre_rowname * string(k) * post_rowname for k in key_names],
        string.(x)
    )
end

