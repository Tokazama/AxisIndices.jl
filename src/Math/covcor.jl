
function covcor_axes(old_axes::NTuple{2,Any}, new_indices::NTuple{2,Any}, dim::Int)
    if dim === 1
        return (
            assign_indices(last(old_axes), first(new_indices)),
            assign_indices(last(old_axes), last(new_indices))
        )
    elseif dim === 2
        return (
            assign_indices(first(old_axes), first(new_indices)),
            assign_indices(first(old_axes), last(new_indices))
        )
    else
        return (
            assign_indices(first(old_axes), first(new_indices)),
            assign_indices(last(old_axes), last(new_indices))
        )
    end
end

for fun in (:cor, :cov)

    fun_doc = """
        $fun(x::AbstractAxisIndicesMatrix; dims=1, kwargs...)

    Performs `$fun` on the parent matrix of `x` and reconstructs a similar type
    with the appropriate axes.

    ## Examples
    ```jldoctest
    julia> using AxisIndices, Statistics

    julia> A = AxisIndicesArray([1 2 3; 4 5 6; 7 8 9], ["a", "b", "c"], [:one, :two, :three]);

    julia> axes_keys($fun(A, dims = 2))
    (["a", "b", "c"], ["a", "b", "c"])

    julia> axes_keys($fun(A, dims = 1))
    ([:one, :two, :three], [:one, :two, :three])

    ```
    """
    @eval begin
        @doc $fun_doc
        function Statistics.$fun(x::AbstractAxisIndices{T,2}; dims=1, kwargs...) where {T}
            p = Statistics.$fun(parent(x); dims=dims, kwargs...)
            return unsafe_reconstruct(x, p, covcor_axes(axes(x), axes(p), dims))
        end
    end
end

# TODO get rid of indicesarray_result
for f in (:mean, :std, :var, :median)
    @eval function Statistics.$f(a::AbstractAxisIndices; dims=:, kwargs...)
        return Basics.reconstruct_reduction(a, Statistics.$f(parent(a); dims=dims, kwargs...), dims)
    end
end

