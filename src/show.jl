
# 63 = royal blue
#print_row_key(io, axis, i) = printstyled(io, "$i ", color=63, bold=true)
#print_row_key(io, axis::Axis, i) = printstyled(io, "$(keys(axis)[i]) ", color=63, bold=true)
#=
    row_key = get_key(axes(X, i), i)
    printstyled(io, "$row_key", color=63, bold=true)
=#
#print_col_keys(io, axis, args...) = nothing

_get_key(axis, i) = i
_get_key(axis::Axis, i) = keys(axis)[findfirst(==(i), eachindex(axis))]

#=
function print_col_keys(
    io::IO,
    axis,
    a,     # result from row_alignment
    A::Vector,
    cols::AbstractVector,
    sep,   # separator between elements
    pre,   # pre key pad
    post   # post key pad
)

    print(io, repeat(" ", length(pre)))
    print(io, repeat(" ", a))
    print(io, repeat(" ", length(post)))
    for (k, j) = enumerate(cols)
        if k > length(A)
            break
        else
            a = alignment(io, j)::Tuple{Int,Int}
            # First try 3-arg show
            sx = sprint(show, "text/plain", axis[j], context=io, sizehint=0)
            if occursin('\n', sx)
                sx = sprint(show, x, context=io, sizehint=0)
            end
            l = repeat(" ", A[k][1] - a[1]) # pad on left and right as needed
            if j == axis[end]
                r = ""
            else
                r = repeat(" ", A[k][2] - a[2])
            end
            print(io, l)
            prettysx = replace_in_print_matrix(X, i, j, sx)
            printstyled(io, prettysx, color=63, bold=true)
            print(io, r)
            if k < length(A)
                print(io, sep)
            end
        end
    end
    println(io)
end
=#

function print_col_keys(
    io::IO,
    X::AxisVecOrMat,
    A::Vector,
    cols::AbstractVector,
    sep::AbstractString
)

    for (k, j) = enumerate(cols)
        if k > length(A)
            break
        else
            x = _get_key(axes(X, 2), j)
            a = alignment(io, x)::Tuple{Int,Int}

            # First try 3-arg show
            sx = sprint(show, "text/plain", x, context=io, sizehint=0)

            # If the output contains line breaks, try 2-arg show instead.
            if occursin('\n', sx)
                sx = sprint(show, x, context=io, sizehint=0)
            end
            l = repeat(" ", A[k][1]-a[1]) # pad on left and right as needed
            if j == axes(X, 2)[end]
                r = ""
            else
                r = repeat(" ", A[k][2]-a[2])
            end
            print(io, l)
            printstyled(io, x, color=63, bold=true)
            print(io, r)
            if k < length(A)
                print(io, sep)
            end
        end
    end
    println(io)
end

function print_row_key(io, axis, i, a, pre, post)
    sx = sprint(show, "text/plain", i, context=io, sizehint=0)
    print(io, pre)
    printstyled(io, sx, color=63, bold=true)
    print(io, post)
end

function row_alignment(io, row)
    a = 0
    for i in keys(row)
        a = max(a, length(sprint(show, i, context=io, sizehint=0)))
    end
    return a
end

function Base.print_matrix(
    io::IO,
    X::AxisVecOrMat,
    pre::AbstractString = " ",  # pre-matrix string
    sep::AbstractString = "  ", # separator between elements
    post::AbstractString = "",  # post-matrix string
    hdots::AbstractString = "  \u2026  ",
    vdots::AbstractString = "\u22ee",
    ddots::AbstractString = "  \u22f1  ",
    hmod::Integer = 5, vmod::Integer = 5
)
    pre_key_string = "  "
    post_key_string = "  "
    pre_col_string = repeat(" ", length(pre) + length(pre_key_string) + length(pre_key_string))

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
    halfheight = div(screenheight,2)
    if m > screenheight
        rowsA = [rowsA[(0:halfheight-1) .+ firstindex(rowsA)]; rowsA[(end-div(screenheight-1,2)+1):end]]
    end
    # Similarly for columns, only necessary to get alignments for as many
    # columns as could conceivably fit across the screen
    maxpossiblecols = div(screenwidth, 1+sepsize)
    if n > maxpossiblecols
        colsA = [colsA[(0:maxpossiblecols-1) .+ firstindex(colsA)]; colsA[(end-maxpossiblecols+1):end]]
    end
    A = alignment(io, X, rowsA, colsA, screenwidth, screenwidth, sepsize)
    # Nine-slicing is accomplished using print_matrix_row repeatedly
    if m <= screenheight # rows fit vertically on screen
        if n <= length(A) # rows and cols fit so just print whole matrix in one piece
            rA = row_alignment(io, axes(X, 1))
            print(io, pre_col_string * repeat(" ", rA))  # print space before column keys
            print_col_keys(io, X, A, colsA, sep)
            for i in rowsA
                print(io, i == first(rowsA) ? pre : presp)
                print_row_key(io, axes(X, 1), i, rA, pre_key_string, post_key_string)
                print_matrix_row(io, X, A, i, colsA, sep)
                print(io, i == last(rowsA) ? post : postsp)
                if i != last(rowsA); println(io); end
            end
        else # rows fit down screen but cols don't, so need horizontal ellipsis
            c = div(screenwidth-length(hdots)::Int+1,2)+1  # what goes to right of ellipsis
            Ralign = reverse(alignment(io, X, rowsA, reverse(colsA), c, c, sepsize)) # alignments for right
            c = screenwidth - sum(map(sum,Ralign)) - (length(Ralign)-1)*sepsize - length(hdots)::Int
            Lalign = alignment(io, X, rowsA, colsA, c, c, sepsize) # alignments for left of ellipsis
            rA = row_alignment(io, axes(X, 1))
            print(io, pre_col_string * repeat(" ", rA))  # print space before column keys
            print_col_keys(io, X, A, colsA, sep)
            for i in rowsA
                print(io, i == first(rowsA) ? pre : presp)
                print_row_key(io, axes(X, 1), i, rA, pre_key_string, post_key_string)
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
            print(io, pre_col_string * repeat(" ", rA))  # print space before column keys
            print_col_keys(io, X, A, colsA, sep)
            for i in rowsA
                print_row_key(io, axes(X, 1), i, rA, pre_key_string, post_key_string)
                print(io, i == first(rowsA) ? pre : presp)
                print_matrix_row(io, X, A, i, colsA, sep)
                print(io, i == last(rowsA) ? post : postsp)
                if i != rowsA[end] || i == rowsA[halfheight]; println(io); end
                if i == rowsA[halfheight]
                    print(io, i == first(rowsA) ? pre : presp)
                    print_matrix_vdots(io, vdots, A, sep, vmod, 1, false)
                    print(io, i == last(rowsA) ? post : postsp * '\n')
                end
            end
        else # neither rows nor cols fit, so use all 3 kinds of dots
            c = div(screenwidth - length(hdots)::Int + 1,2) + 1
            Ralign = reverse(alignment(io, X, rowsA, reverse(colsA), c, c, sepsize))
            c = screenwidth - sum(map(sum,Ralign)) - (length(Ralign)-1)*sepsize - length(hdots)::Int
            Lalign = alignment(io, X, rowsA, colsA, c, c, sepsize)
            r = mod((length(Ralign)-n+1),vmod) # where to put dots on right half
            rA = row_alignment(io, axes(X, 1))
            print(io, pre_col_string * repeat(" ", rA))  # print space before column keys
            print_col_keys(io, X, A, colsA, sep)
            for i in rowsA
                print_row_key(io, axes(X, 1), i, rA, pre_key_string, post_key_string)
                print(io, i == first(rowsA) ? pre : presp)
                print_matrix_row(io, X, Lalign, i, colsA[1:length(Lalign)], sep)
                print(io, (i - first(rowsA)) % hmod == 0 ? hdots : repeat(" ", length(hdots)::Int))
                print_matrix_row(io, X,Ralign,i,(n-length(Ralign)).+colsA,sep)
                print(io, i == last(rowsA) ? post : postsp)
                if i != rowsA[end] || i == rowsA[halfheight]; println(io); end
                if i == rowsA[halfheight]
                    print(io, i == first(rowsA) ? pre : presp)
                    print_matrix_vdots(io, vdots, Lalign, sep, vmod, 1, true)
                    print(io, ddots)
                    print_matrix_vdots(io, vdots, Ralign, sep, vmod, r, false)
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

function Base.summary(io::IO, a::AxisArray)
    print(io, Base.dims2string(length.(axes(a))), " ")
    print(io, "AxisArray(")
    Base.showarg(io, parent(a), false)
    print(io, ")")
    print(io, "\n")
    compact_io = IOContext(io, :compact => true)
    lft_pad =lpad(' ', 5)
    print(io, lpad("$(lpad(Char(0x2022), 3)) axes:", 0))
    for i in OneTo(ndims(a))
        println(compact_io)
        print(compact_io, lft_pad)
        print(compact_io, "$i. ")
        print(compact_io, axes(a, i))
    end
end

###
### axis printing
###

Base.show(io::IO, axis::AbstractAxis) = print_axis(io, axis)
Base.show(io::IO, ::MIME"text/plain", axis::AbstractAxis) = print_axis(io, axis)

function print_axis(io, axis::Axis)
    if haskey(io, :compact)
        show(io, keys(axis))
    else
        print(io, "Axis($(keys(axis)) => $(parent(axis)))")
    end
end

function print_axis(io::IO, axis::OffsetAxis)
    if haskey(io, :compact)
        show(io, eachindex(axis))
    else
        print(io, "OffsetAxis(offset=$(offsets(axis, 1)), parent=$(parent(axis)))")
    end
end
function print_axis(io::IO, axis::CenteredAxis)
    if haskey(io, :compact)
        show(io, eachindex(axis))
    else
        ori = static_first(p) + offsets(axis, 1) + div(len, 2one(len))
        print(io, "OffsetAxis(origin=$(ori), parent=$(parent(axis)))")
    end
end

function print_axis(io::IO, axis::IdentityAxis)
    if haskey(io, :compact)
        show(io, eachindex(axis))
    else
        print(io, "IdentityAxis(identity=$(keys(axis)), parent=$(parent(axis)))")
    end
end

function print_axis(io::IO, axis::SimpleAxis)
    inds = Int(first(axis)):Int(last(axis))
    if haskey(io, :compact)
        show(io, inds)
    else
        print(io, "SimpleAxis($(inds))")
    end
end

