
function _pretty_print(io::IO, k, color)
    if get(io, :color, false)
        printstyled(io, k; color=color)
    else
        print(io, k)
    end
end

function _get_key(axis, i)
    if i isa StaticInt
        return Int(i)
    else
        return i
    end
end
_get_key(axis::Axis, i) = keys(axis)[findfirst(==(i), eachindex(axis))]
_get_key(axis::StructAxis, i) = keys(axis)[findfirst(==(i), eachindex(axis))]

# this makes it so we don't print StaticInt

function Base.alignment(
    io::IO,
    X::AxisVecOrMat,
    rows::AbstractVector,
    cols::AbstractVector,
    cols_if_complete::Integer,
    cols_otherwise::Integer,
    sep::Integer
)

    a = Tuple{Int, Int}[]
    for j in cols # need to go down each column one at a time
        l, r = alignment(io, _get_key(axes(X, 2), j))
        #=
        l = 0
        r = length(sprint(show, "text/plain", , context=io, sizehint=0))
        =#
        for i in rows # plumb down and see what largest element sizes are
            if isassigned(X,i,j)
                aij = alignment(io, X[i,j])
            else
                aij = undef_ref_alignment
            end
            l = max(l, aij[1]) # left characters
            r = max(r, aij[2]) # right characters
        end
        push!(a, (l, r)) # one tuple per column of X, pruned to screen width
        if length(a) > 1 && sum(map(sum,a)) + sep*length(a) >= cols_if_complete
            pop!(a) # remove this latest tuple if we're already beyond screen width
            break
        end
    end
    if 1 < length(a) < length(axes(X,2))
        while sum(map(sum,a)) + sep * length(a) >= cols_otherwise
            pop!(a)
        end
    end
    return a
end

function print_col_keys(
    io::IO,
    X::AbstractVecOrMat,
    A::Vector,
    cols::AbstractVector,
    sep::AbstractString
)

    for (k, j) = enumerate(cols)
        k > length(A) && break
        x = _get_key(axes(X, 2), j)
        a = alignment(io, x)::Tuple{Int,Int}

        # First try 3-arg show
        sx = sprint(show, "text/plain", x, context=io, sizehint=0)

        # If the output contains line breaks, try 2-arg show instead.
        if occursin('\n', sx)
            sx = sprint(show, x, context=io, sizehint=0)
        end

        _pretty_print(io, sx, 63)
        if j == axes(X, 2)[end]
            print(io, repeat(" ", A[k][1] - a[1]))
        else
            print(io, repeat(" ", (A[k][1]-a[1]) + (A[k][2]-a[2])))
        end

        if k < length(A)
            print(io, sep)
        end
    end
end

function print_row_key(io, axis, i, a, pre, post)
    sx = sprint(show, "text/plain", _get_key(axis, i), context=io, sizehint=0)
    print(io, pre)
    _pretty_print(io, sx, 63)
    print(io, repeat(" ", a + length(post) - length(sx)))
end

function row_alignment(io, row)
    a = 0
    for i in row
        a = max(a, length(sprint(show, "text/plain", _get_key(row, i), context=io, sizehint=0)))
    end
    return a
end

function Base.print_matrix(
    io::IO,
    X::AxisVecOrMat,
    pre::AbstractString = " ",  # pre-matrix string
    sep::AbstractString = "  ", # separator between elements
    post::AbstractString = "  ",  # post-matrix string
    hdots::AbstractString = "  \u2026  ",
    vdots::AbstractString = "\u22ee",
    ddots::AbstractString = "  \u22f1  ",
    hmod::Integer = 5, vmod::Integer = 5
)

    hmod, vmod = Int(hmod)::Int, Int(vmod)::Int
    if !(get(io, :limit, false)::Bool)
        screenheight = screenwidth = typemax(Int)
    else
        sz = displaysize(io)::Tuple{Int,Int}
        screenheight, screenwidth = sz[1] - 4, sz[2]
    end
    screenwidth -= length(pre)::Int + length(post)::Int
    presp = repeat(" ", length(pre)::Int)  # indent each row to match pre string
    postsp = ""
    @assert Base.textwidth(hdots) == Base.textwidth(ddots)
    sepsize = length(sep)::Int
    rowsA = UnitRange{Int}(axes(X,1))
    colsA = UnitRange{Int}(axes(X,2))
    m, n = length(rowsA), length(colsA)
    # To figure out alignments, only need to look at as many rows as could
    # fit down screen. If screen has at least as many rows as A, look at A.
    # If not, then we only need to look at the first and last chunks of A,
    # each half a screen height in size.
    halfheight = div(screenheight, 2)
    if m > screenheight
        rowsA = [rowsA[(0:halfheight - 1) .+ firstindex(rowsA)];
                 rowsA[(end-div(screenheight - 1, 2) + 1):end]]
    end
    # Similarly for columns, only necessary to get alignments for as many
    # columns as could conceivably fit across the screen
    maxpossiblecols = div(screenwidth, 1+sepsize)
    if n > maxpossiblecols
        colsA = [colsA[(0:maxpossiblecols - 1) .+ firstindex(colsA)];
                 colsA[(end - maxpossiblecols + 1):end]]
    end
    A = alignment(io, X, rowsA, colsA, screenwidth, screenwidth, sepsize)
    # Nine-slicing is accomplished using print_matrix_row repeatedly
    if m <= screenheight # rows fit vertically on screen
        if n <= length(A) # rows and cols fit so just print whole matrix in one piece
            rA = row_alignment(io, axes(X, 1))
            print(io, " " * repeat(" ", rA + length(pre) + length(post)))  # print space before column keys
            print_col_keys(io, X, A, colsA, sep)
            println(io)
            for i in rowsA
                print(io, i == first(rowsA) ? pre : presp)
                print_row_key(io, axes(X, 1), i, rA, pre, post)
                print_matrix_row(io, X, A, i, colsA, sep)
                print(io, i == last(rowsA) ? post : postsp)
                if i != last(rowsA)
                    println(io)
                end
            end
        else # rows fit down screen but cols don't, so need horizontal ellipsis
            c = div(screenwidth-length(hdots)::Int+1,2)+1  # what goes to right of ellipsis
            Ralign = reverse(alignment(io, X, rowsA, reverse(colsA), c, c, sepsize)) # alignments for right
            c = screenwidth - sum(map(sum, Ralign)) - (length(Ralign)-1)*sepsize - length(hdots)::Int
            Lalign = alignment(io, X, rowsA, colsA, c, c, sepsize) # alignments for left of ellipsis
            rA = row_alignment(io, axes(X, 1))
            print(io, " " * repeat(" ", rA + length(pre) + length(post)))  # print space before column keys
            print_col_keys(io, X, Lalign, colsA[1:length(Lalign)], sep)
            print(io, repeat(" ", length(hdots)::Int))
            print_col_keys(io, X, Ralign, (n - length(Ralign)) .+ colsA, sep)
            println(io)
            for i in rowsA
                print(io, i == first(rowsA) ? pre : presp)
                print_row_key(io, axes(X, 1), i, rA, pre, post)
                print_matrix_row(io, X, Lalign, i, colsA[1:length(Lalign)], sep)
                print(io, (i - first(rowsA)) % hmod == 0 ? hdots : repeat(" ", length(hdots)::Int))
                print_matrix_row(io, X, Ralign, i, (n - length(Ralign)) .+ colsA, sep)
                print(io, i == last(rowsA) ? post : postsp)
                if i != last(rowsA)
                    println(io)
                end
            end
        end
    else # rows don't fit so will need vertical ellipsis
        if n <= length(A) # rows don't fit, cols do, so only vertical ellipsis
            rA = row_alignment(io, axes(X, 1))
            print(io, " " * repeat(" ", rA + length(pre) + length(post)))  # print space before column keys
            print_col_keys(io, X, A, colsA, sep)
            println(io)
            for i in rowsA
                print_row_key(io, axes(X, 1), i, rA, pre, post)
                print(io, i == first(rowsA) ? pre : presp)
                print_matrix_row(io, X, A, i, colsA, sep)
                print(io, i == last(rowsA) ? post : postsp)
                if i != rowsA[end] || i == rowsA[halfheight]; println(io); end
                if i == rowsA[halfheight]
                    print(io, i == first(rowsA) ? pre : presp)
                    Base.print_matrix_vdots(io, vdots, A, sep, vmod, 1, false)
                    print(io, i == last(rowsA) ? post : postsp * '\n')
                end
            end
        else # neither rows nor cols fit, so use all 3 kinds of dots
            c = div(screenwidth - length(hdots)::Int + 1,2) + 1
            Ralign = reverse(alignment(io, X, rowsA, reverse(colsA), c, c, sepsize))
            c = screenwidth - sum(map(sum,Ralign)) - (length(Ralign)-1)*sepsize - length(hdots)::Int
            Lalign = alignment(io, X, rowsA, colsA, c, c, sepsize)
            r = mod((length(Ralign) - n + 1),vmod) # where to put dots on right half
            rA = row_alignment(io, axes(X, 1))
            print(io, " " * repeat(" ", rA + length(pre) + length(post)))  # print space before column keys
            print_col_keys(io, X, Lalign, colsA[1:length(Lalign)], sep)
            print(io, repeat(" ", length(hdots)::Int))
            print_col_keys(io, X, Ralign, (n - length(Ralign)) .+ colsA, sep)
            println(io)
            for i in rowsA
                print_row_key(io, axes(X, 1), i, rA, pre, post)
                print(io, i == first(rowsA) ? pre : presp)
                print_matrix_row(io, X, Lalign, i, colsA[1:length(Lalign)], sep)
                print(io, (i - first(rowsA)) % hmod == 0 ? hdots : repeat(" ", length(hdots)::Int))
                print_matrix_row(io, X, Ralign, i, (n-length(Ralign)).+colsA, sep)
                print(io, i == last(rowsA) ? post : postsp)
                if i != rowsA[end] || i == rowsA[halfheight]; println(io); end
                if i == rowsA[halfheight]
                    print(io, i == first(rowsA) ? pre : presp)
                    Base.print_matrix_vdots(io, vdots, Lalign, sep, vmod, 1, true)
                    print(io, " " * repeat(" ", rA + length(pre) + length(post)))  # print space before column keys
                    print(io, ddots)
                    Base.print_matrix_vdots(io, vdots, Ralign, sep, vmod, r, false)
                    print(io, i == last(rowsA) ? post : postsp * '\n')
                end
            end
        end
        if isempty(rowsA)
            print(io, pre)
            print(io, vdots)
            length(colsA) > 1 && print(io, "    ", ddots)
            print(io, post)
        end
    end
end

function print_axes_summary(io::IO, axs::NamedTuple{L}) where {L}
    compact_io = IOContext(io, :compact => true)
    lft_pad =lpad(' ', 5)
    print(io, lpad("$(lpad(Char(0x2022), 3)) axes:", 0))
    for i in OneTo(length(axs))
        println(compact_io)
        print(compact_io, lft_pad)
        _pretty_print(compact_io, "$(L[i]) = ", 129)
        _pretty_print(compact_io, axs[i], 63)
    end
end

function print_axes_summary(io::IO, axs::Tuple)
    compact_io = IOContext(io, :compact => true)
    lft_pad =lpad(' ', 5)
    print(io, lpad("$(lpad(Char(0x2022), 3)) axes:", 0))
    for i in OneTo(length(axs))
        println(compact_io)
        print(compact_io, lft_pad)
        _pretty_print(compact_io, "$i = ", 129)
        _pretty_print(compact_io, axs[i], 63)
    end
end

function Base.show_nd(io::IO, a::AxisArray, print_matrix::Function, label_slices::Bool)
    limit::Bool = get(io, :limit, false)
    if isempty(a)
        return
    end
    tailinds = tail(tail(axes(a)))
    nd = ndims(a)-2
    for I in CartesianIndices(tailinds)
        idxs = I.I
        if limit
            for i = 1:nd
                ii = idxs[i]
                ind = tailinds[i]
                if length(ind) > 10
                    if ii == ind[firstindex(ind)+3] && all(d->idxs[d]==first(tailinds[d]),1:i-1)
                        for j=i+1:nd
                            szj = length(axes(a, j+2))
                            indj = tailinds[j]
                            if szj>10 && first(indj)+2 < idxs[j] <= last(indj)-3
                                @goto skip
                            end
                        end
                        #println(io, idxs)
                        print(io, "...\n\n")
                        @goto skip
                    end
                    if ind[firstindex(ind)+2] < ii <= ind[end-3]
                        @goto skip
                    end
                end
            end
        end
        if label_slices
            _pretty_print(io, "[:, :, ", 129)
            for i = 1:(nd-1)
                _pretty_print(io, "$(_get_key(axes(a, i), idxs[i])), ", 63)
            end
            _pretty_print(io, "$(_get_key(axes(a, ndims(a)), idxs[end]))", 63)
            _pretty_print(io, "] =", 129)
            println(io)
        end
        slice = view(a, axes(a,1), axes(a,2), idxs...)
        Base.print_matrix(io, slice)
        print(io, idxs == map(last,tailinds) ? "" : "\n\n")
        @label skip
    end
end

function Base.show(io::IO, ::MIME"text/plain", X::AxisArray)
    if isempty(X) && (get(io, :compact, false) || X isa Vector)
        return show(io, X)
    end
    # 0) show summary before setting :compact
    summary(io, X)
    isempty(X) && return
    Base.show_circular(io, X) && return

    # 1) compute new IOContext
    if !haskey(io, :compact) && length(axes(X, 2)) > 1
        io = IOContext(io, :compact => true)
    end
    if get(io, :limit, false) && eltype(X) === Method
        # override usual show method for Vector{Method}: don't abbreviate long lists
        io = IOContext(io, :limit => false)
    end

    if get(io, :limit, false) && displaysize(io)[1]-4 <= 0
        return print(io, " …")
    else
        println(io)
    end

    # 2) update typeinfo
    #
    # it must come after printing the summary, which can exploit :typeinfo itself
    # (e.g. views)
    # we assume this function is always called from top-level, i.e. that it's not nested
    # within another "show" method; hence we always print the summary, without
    # checking for current :typeinfo (this could be changed in the future)
    io = IOContext(io, :typeinfo => eltype(X))

    # 2) show actual content
    recur_io = IOContext(io, :SHOWN_SET => X)
    Base.print_array(recur_io, X)
end

function Base.showarg(io::IO, x::AxisArray, toplevel)
    if toplevel
        print(io, Base.dims2string(length.(axes(x))), " ")
    end

    print(io, "AxisArray(")
    Base.showarg(io, parent(x), false)
    print(io, "\n")
    print_axes_summary(io, axes(x))
    print(io, "\n)")
end

Base.summary(io::IO, x::AxisArray) = Base.showarg(io, x, true)

