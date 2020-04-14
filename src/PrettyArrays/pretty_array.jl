
"""
    pretty_array([io::IO,] A::AbstractArray[, axs::NamedTuple=named_axes(A)]; kwargs...)

Prints to `io` the array `A` with the keys `key_names` along each dimension of `A`.
Printing of multidimensional arrays is accomplished in a similar manner to `Array`, where the final two dimensions are sliced producing a series of matrices.
`kwargs...` are passed to `pretty_table` for 1/2D slice produced.

## Examples
```jldoctest
julia> using AxisIndices

julia> pretty_array(ones(Int, 2,2,2),
           (x = Axis(2:3),
            y = Axis([:one, :two]),
            z = Axis(["a", "b"])))
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
    A::AbstractArray,
    axs::NamedTuple{L}=named_axes(A),
    backend::Symbol=:text;
    kwargs...
) where {L}

    limit::Bool = get(io, :limit, false)
    if isempty(A)
        return
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

        print(io, "[$(L[1]), $(L[2]), ")
        for i in 1:(nd-1)
            print(io, "$(L[i])[$(keys(keyinds[i])[idxs[i]])], ")
        end
        println(io, "$(L[end])[", keys(keyinds[end])[idxs[end]], "]] =")
        axs2 = (axs[1], axs[2])
        pretty_array(
            io,
            view(A, axes(A,1), axes(A,2), idxs...),
            NamedTuple{(L[1], L[2]),typeof(axs2)}(axs2),
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
    axs::NamedTuple=named_axes(A),
    backend::Symbol=:text;
    kwargs...
)

    if backend === :text
        return pretty_array_text(io, A, axs[1], Axis([""], Base.OneTo(1)); kwargs...)
    elseif backend === :html
        return pretty_array_html(io, A, axs[1], Axis([""], Base.OneTo(1)); kwargs...)
    elseif backed === :latex
        return pretty_array_latex(io, A, axs[1],Axis([""], Base.OneTo(1)); kwargs...)
    else
        error()
    end
end

function pretty_array(
    io::IO,
    A::AbstractMatrix,
    axs::NamedTuple=named_axes(A),
    backend::Symbol=:text;
    kwargs...
)
    if backend === :text
        return pretty_array_text(io, A, axs[1], axs[2]; kwargs...)
    elseif backend === :html
        return pretty_array_html(io, A, axs[1], axs[2]; kwargs...)
    elseif backed === :latex
        return pretty_array_latex(io, A, axs[1], axs[2]; kwargs...)
    else
        error()
    end
end

function pretty_array(
    A::AbstractArray,
    axs::NamedTuple=named_axes(A),
    backend::Symbol=:text;
    kwargs...
)
    return pretty_array(stdout, A, axs, backend; kwargs...)
end

function pretty_array(
    A::AbstractAxisIndices,
    axs::NamedTuple=named_axes(A),
    backend::Symbol=:text;
    kwargs...
)
    return pretty_array(stdout, parent(A), axs, backend; kwargs...)
end


function pretty_array(::Type{String}, A::AbstractArray, axs::NamedTuple=named_axes(A); kwargs...)
    io = IOBuffer()
    pretty_array(io, A, axs; kwargs...)
    return String(take!(io))
end

