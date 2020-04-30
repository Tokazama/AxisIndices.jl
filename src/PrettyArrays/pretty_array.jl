
"""
    pretty_array([io::IO,] A::AbstractArray[, axs=axes(A)], dimnames=ntuple(i -> Symbol(:dim_, i), N), backend=:text; kwargs...)

Prints to `io` the array `A` with the keys `key_names` along each dimension of `A`.
Printing of multidimensional arrays is accomplished in a similar manner to `Array`, where the final two dimensions are sliced producing a series of matrices.
`kwargs...` are passed to `pretty_table` for 1/2D slice produced.

## Examples
```jldoctest
julia> using AxisIndices

julia> pretty_array(ones(Int, 2,2,2), (Axis(2:3), Axis([:one, :two]), Axis(["a", "b"])), (:x, :y, :z))
[x, y, z[a]] =
      one   two
  2     1     1
  3     1     1

[x, y, z[b]] =
      one   two
  2     1     1
  3     1     1

```
"""
function pretty_array(
    io::IO,
    A::AbstractArray{T,N},
    axs::Tuple=axes(A),
    dnames::Tuple=ntuple(i -> Symbol(:dim_, i), N),
    backend::Symbol=:text;
    kwargs...
) where {T,N}

    limit::Bool = get(io, :limit, false)
    if isempty(A)
        return nothing
    end
    tailinds = tail(tail(axes(A)))
    keyinds = tail(tail(axs))
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
            print(io, "$(dnames[i])[$(keys(keyinds[i])[idxs[i]])], ")
        end
        println(io, "$(dnames[end])[", keys(keyinds[end])[idxs[end]], "]] =")
        pretty_array(
            io,
            view(A, axes(A,1), axes(A,2), idxs...),
            (axs[1], axs[2]),
            (dnames[1], dnames[2]),
            backend;
            kwargs...
        )
        print(io, idxs == map(last,tailinds) ? "" : "\n")
        @label skip
    end
end

function pretty_array(
    io::IO,
    A::AbstractVector,
    axs::Tuple=axes(A),
    dnames::Tuple=(:_,),
    backend::Symbol=:text;
    kwargs...
)

    if isempty(A)
        return nothing
    else
        if backend === :text
            return pretty_array_text(io, A, axs[1]; kwargs...)
        #=
        elseif backend === :html
            return pretty_array_html(io, A, axs[1]; kwargs...)
        elseif backed === :latex
            return pretty_array_latex(io, A, axs[1]; kwargs...)
        else
            error("unsupported backend specified")
        =#
        end
    end
end

function pretty_array(
    io::IO,
    A::AbstractMatrix,
    axs::Tuple=axes(A),
    dnames::Tuple=(:_,:_),
    backend::Symbol=:text;
    kwargs...
)
    if isempty(A)
        return nothing
    else
        if backend === :text
            return pretty_array_text(io, A, axs[1], axs[2]; kwargs...)
        #=
        elseif backend === :html
            return pretty_array_html(io, A, axs[1], axs[2]; kwargs...)
        elseif backed === :latex
            return pretty_array_latex(io, A, axs[1], axs[2]; kwargs...)
        else
            error("unsupported backend specified")
        =#
        end
    end
end

function pretty_array(
    io::IO,
    A::AbstractArray{T,0},
    axs::Tuple=(),
    dnames::Tuple=(),
    backend::Symbol=:text;
    kwargs...
) where {T}
    if isempty(A)
        return nothing
    else
        return print(io, A[1])
    end
end

function pretty_array(
    A::AbstractArray{T,N},
    axs::Tuple=axes(A),
    dnames::Tuple=ntuple(i -> Symbol(:dim_, i), N), 
    backend::Symbol=:text;
    kwargs...
) where {T,N}
    return pretty_array(stdout, A, axs, dnames, backend; kwargs...)
end

function pretty_array(
    ::Type{String},
    A::AbstractArray{T,N},
    axs::Tuple=axes(A),
    dnames::Tuple=ntuple(i -> Symbol(:dim_, i), N),
    backend::Symbol=:text;
    kwargs...
) where {T,N}
    io = IOBuffer()
    pretty_array(io, A, axs, dnames, backend; kwargs...)
    return String(take!(io))
end

