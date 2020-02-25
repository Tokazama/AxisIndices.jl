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

