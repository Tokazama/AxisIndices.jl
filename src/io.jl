# This file is for I/O methods

###
### read/write
###
function Base.unsafe_convert(::Type{Ptr{T}}, x::AbstractAxisIndices{T}) where {T}
    return Base.unsafe_convert(Ptr{T}, parent(x))
end

function Base.read!(io::IO, a::AbstractAxisIndices)
    read!(io, parent(a))
    return a
end

Base.write(io::IO, a::AbstractAxisIndices) = write(io, parent(a))

###
### show AbstractAxis
###
function Base.show(io::IO, ::MIME"text/plain", a::AbstractAxis)
    print(io, "$(typeof(a).name)($(keys(a)) => $(values(a)))")
end

function Base.show(io::IO, a::AbstractAxis)
    print(io, "$(typeof(a).name)($(keys(a)) => $(values(a)))")
end

function Base.show(io::IO, ::MIME"text/plain", a::SimpleAxis)
    print(io, "SimpleAxis($(values(a)))")
end

function Base.show(io::IO, a::SimpleAxis)
    print(io, "SimpleAxis($(values(a)))")
end

###
### show AbstractAxisIndices
###
function row_formatter(
    data;
    bold=true,
    kwargs...
)
    return Highlighter(f = (data, i, j) -> j == 1, crayon = Crayon(; bold=bold, kwargs...))
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
    tf=text_matrix,
    formatter=ft_round(3),
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

const text_matrix = TextFormat(
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
    A::AbstractArray{T,N},
    key_names::Tuple=map(keys, axes(A));
    dnames=ntuple(i -> "dim$i", N),
    pre_rowname="",
    post_rowname="",
    row_colname="",
    vec_colname="",
    backend=:text,
    tf=ifelse(backend == :text, text_matrix, ifelse(backend == :html, html_matrix, latex_simple)),
    formatter=ft_printf("%5.3f"),
    kwargs...
) where {T,N}

    return pretty_array(
        stdout,
        parent(A),
        key_names;
        dnames=dnames,
        vec_colname=vec_colname,
        row_colname=row_colname,
        post_rowname=post_rowname,
        pre_rowname=pre_rowname,
        tf=tf,
        formatter=formatter,
        kwargs...)
end

function pretty_array(
    io::IO,
    A::AbstractArray{T,N},
    key_names::Tuple=map(keys, axes(A));
    backend=:text,
    dnames=ntuple(i -> "dim$i", N),
    pre_rowname="",
    post_rowname="",
    row_colname="",
    vec_colname="",
    tf=ifelse(backend == :text, text_matrix, ifelse(backend == :html, html_matrix, latex_simple)),
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
            (key_names[1], key_names[2]);
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
    pre_rowname="",
    post_rowname="",
    formatter=ft_printf("%5.3f"),
    kwargs...
   )
    data = combine_rows_to_matrix(
        apply_formatter(x, formatter),
        first(key_names),
        pre_rowname,
        post_rowname
    )
 
    if ndims(x) == 1
       return pretty_table(
            io,
            data,
            [row_colname, vec_colname];
            highlighters=row_formatter(data),
            kwargs...
        )
    else
        return pretty_table(
            io,
            data,
            vcat(row_colname, last(key_names));
            highlighters=row_formatter(data),
            kwargs...
        )
    end
end

function combine_rows_to_matrix(x::AbstractArray{<:AbstractString}, key_names::LinearIndices, pre_rowname, post_rowname)
    return combine_rows_to_matrix(x, key_names.indices[1], pre_rowname, post_rowname)
end

function combine_rows_to_matrix(x::AbstractArray{<:AbstractString}, key_names, pre_rowname, post_rowname)
    return hcat([pre_rowname * string(k) * post_rowname for k in key_names], x)
end

function apply_formatter(data::AbstractVector, formatter)
    vec(apply_formatter(permutedims(data), formatter))
end

function apply_formatter(data::AbstractMatrix, formatter)
    m, n = size(data)
    out = Matrix{String}(undef, (m, n))
    @inbounds for i in 1:n
        for j in 1:m
            if haskey(formatter, i)
                fi = formatter[i]
            else
                if haskey(formatter, 0)
                    fi = formatter[0]
                else
                    fi = nothing
                end
            end
            if fi == nothing
                out_ij = nothing
            else
                out_ij = fi(data[j,i], j)
            end
            if ismissing(out_ij)
                out[j, i] = "missing"
            elseif out_ij == nothing
                out[j, i] = "nothing"
            else
                out[j, i] = "$out_ij"
            end
        end
    end
    return out
end

