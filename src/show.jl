

function Base.show(io::IO,
    m::MIME"text/plain",
    A::AbstractAxisIndices{T,N};
    axnames=ntuple(i -> "axis $i", N),
    tf=array_text_format,
    formatter=ft_printf("%5.3f"),
    kwargs...
   ) where {T,N}
    println(io, "$N-dimensional $(typeof(A).name.name){$T,$N,...} with axes:")
    for (name, val) in zip(axnames, axes(A))
        print(io, "    :$name, ")
        show(IOContext(io, :limit=>true), val)
        println(io)
    end
    pretty_array(io, parent(A), axes_keys(A); tf=tf, formatter=formatter, kwargs...)
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

function pretty_array(io::IO, a::AbstractArray, key_names::Tuple; kwargs...)
    limit::Bool = get(io, :limit, false)
    if isempty(a)
        return
    end
    tailinds = tail(tail(axes(a)))
    keyinds = tail(tail(key_names))
    nd = ndims(a)-2
    for I in CartesianIndices(tailinds)
        idxs = I.I
        if limit
            for i = 1:nd
                ii = idxs[i]
                ind = tailinds[i]
                if length(ind) > 10
                    if ii == ind[firstindex(ind)+3] && all(d-> idxs[d] == first(tailinds[d]), 1:i-1)
                        for j=i+1:nd
                            szj = length(axes(a, j+2))
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

        print(io, "[:, :, ")
        for i in 1:(nd-1)
            print(io, "$(keyinds[i][idxs[i]]), ")
        end
        println(io, keyinds[end][idxs[end]], "] =")
        slice = view(a, axes(a,1), axes(a,2), idxs...)
        pretty_array(io, slice, keyinds;  kwargs...)

        print(io, idxs == map(last,tailinds) ? "" : "\n\n")
        @label skip
    end
end

function pretty_array(io::IO, x::AbstractMatrix, key_names::Tuple; kwargs...)
    pretty_table(io, x, last(key_names); kwargs...)
end

function pretty_array(io::IO, x::AbstractVector, key_names::Tuple; kwargs...)
    pretty_table(io, x; kwargs...)
end

