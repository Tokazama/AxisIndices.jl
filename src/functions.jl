# This file is for functions that just need simple standard overloading.

## Helpers:

function indicesarray_result(original_ia, reduced_data, reduction_dims)
    return AxisIndicesArray(reduced_data, reduce_axes(original_ia, reduction_dims))
end

# if reducing over `:` then results is a scalar
indicesarray_result(original_ia, reduced_data, reduction_dims::Colon) = reduced_data


################################################
# Overloads

# 1 Arg
for (mod, funs) in (
    (:Base, (:sum, :prod, :maximum, :minimum, :extrema)),
    (:Statistics, (:mean, :std, :var, :median)))
    for fun in funs
        @eval function $mod.$fun(a::AxisIndicesArray; dims=:, kwargs...)
            return indicesarray_result(a, $mod.$fun(parent(a); dims=dims, kwargs...), dims)
        end
    end
end

# 1 Arg - no default for `dims` keyword
for fun in (:cumsum, :cumprod, :sort, :sort!)
    @eval function Base.$fun(a::AxisIndicesArray; dims, kwargs...)
        return AxisIndicesArray(Base.$fun(parent(a); dims=dims, kwargs...), axes(a))
    end

    # Vector case
    @eval function Base.$fun(a::AxisIndicesVector; kwargs...)
        return AxisIndicesArray(Base.$fun(parent(a); kwargs...), axes(a))
    end
end

if VERSION > v"1.1-"
    function Base.eachslice(a::AxisIndicesArray; dims, kwargs...)
        slices = eachslice(parent(a); dims=dims, kwargs...)
        return Base.Generator(slices) do slice
            return AxisIndicesArray(slice, drop_axes(a, dims))
        end
    end
end

function Base.mapslices(f, a::AxisIndicesArray; dims, kwargs...)
    return indicesarray_result(a, Base.mapslices(f, parent(a); dims=dims, kwargs...), dims)
end

function Base.mapreduce(f1, f2, a::AxisIndicesArray; dims=:, kwargs...)
    return indicesarray_result(a, Base.mapreduce(f1, f2, parent(a); dims=dims, kwargs...), dims)
end

################################################
# Non-dim Overloads

for f in (:(==), :isequal, :isapprox)
    @eval begin
        Base.$f(a::AxisIndicesArray, b::AxisIndicesArray; kw...) = $f(parent(a), parent(b); kw...)
        Base.$f(a::AxisIndicesArray, b::AbstractArray; kw...) = $f(parent(a), b; kw...)
        Base.$f(a::AbstractArray, b::AxisIndicesArray; kw...) = $f(a, parent(b); kw...)
    end
end

function Base.empty!(a::AxisIndicesArray)
    for ax_i in axes(a)
        empty!(ax_i)
    end
    empty!(parent(a))
    return a
end

for f in (:zero, :one, :copy)
    @eval begin
        Base.$f(a::AxisIndicesArray) = AxisIndicesArray(Base.$f(parent(a)), axes(a))
    end
end

const CoVector = Union{Adjoint{<:Any, <:AbstractVector}, Transpose{<:Any, <:AbstractVector}}
# Two arrays
for fun in (:sum!, :prod!, :maximum!, :minimum!)
    for (A,B) in ((AxisIndicesArray, AbstractArray),
                  (AbstractArray,AxisIndicesArray),
                  (AxisIndicesArray, AxisIndicesArray))
        @eval begin
            function Base.$fun(a::$A, b::$B)
                Base.$fun(parent(a), parent(b))
                return a
            end
        end
    end
end

################################################
# map, collect

Base.map(f, A::AxisIndicesArray) = AxisIndicesArray(map(f, parent(A)), axes(A))

for (T, S) in [
    (:AxisIndicesArray, :AbstractArray),
    (:AbstractArray, :AxisIndicesArray),
    (:AxisIndicesArray, :AxisIndicesArray),
    ]
    for fun in [:map, :map!]

        # Here f::F where {F} is needed to avoid ambiguities in Julia 1.0
        @eval function Base.$fun(f::F, a::$T, b::$S, cs::AbstractArray...) where {F}
            return AxisIndicesArray($fun(f, parent(a), parent(b), parent.(cs)...),
                             Broadcast.combine_axes(a, b, cs...,))
        end

    end
end

Base.filter(f, A::AxisIndicesVector) = AxisIndicesArray(filter(f, parent(A)), axes(f))
Base.filter(f, A::AxisIndicesArray) = filter(f, parent(A))

function Base.push!(A::AxisIndicesVector, items...)
    grow_last!(axes(A, 1), length(items))
    push!(parent(A), items...)
    return A
end

function Base.pushfirst!(A::AxisIndicesVector, items...)
    grow_first!(axes(A, 1), length(items))
    pushfirst!(parent(A), items...)
    return A
end

function Base.pop!(A::AxisIndicesVector)
    shrink_last!(axes(A, 1), 1)
    return pop!(parent(A))
end

function Base.popfirst!(A::AxisIndicesVector)
    shrink_first!(axes(A, 1), 1)
    return popfirst!(parent(A))
end

function Base.append!(A::AxisIndicesVector, collection)
    append_axis!(axes(A, 1), axes(collection, 1))
    append!(parent(A), collection)
    return A
end
