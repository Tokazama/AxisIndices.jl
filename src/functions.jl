# 1 Arg - no default for `dims` keyword
for fun in (:cumsum, :cumprod, :sort, :sort!)
    @eval function Base.$fun(a::AbstractAxisIndices; dims, kwargs...)
        return AxisIndicesArray(Base.$fun(parent(a); dims=dims, kwargs...), axes(a))
    end

    # Vector case
    @eval function Base.$fun(a::AbstractAxisIndices{T,1}; kwargs...) where {T}
        p = Base.$fun(parent(a); kwargs...)
        return similar_type(a, typeof(p))(p, axes(a))
    end
end

if VERSION > v"1.1-"
    function Base.eachslice(a::AbstractAxisIndices; dims, kwargs...)
        slices = eachslice(parent(a); dims=dims, kwargs...)
        return Base.Generator(slices) do slice
            axs = drop_axes(a, dims)
            return similar_type(a, typeof(slice), typeof(axs))(slice, axs)
        end
    end
end

################################################
# Non-dim Overloads

for f in (:(==), :isequal, :isapprox)
    @eval begin
        Base.$f(a::AbstractAxisIndices, b::AbstractAxisIndices; kw...) = $f(parent(a), parent(b); kw...)
        Base.$f(a::AbstractAxisIndices, b::AbstractArray; kw...) = $f(parent(a), b; kw...)
        Base.$f(a::AbstractArray, b::AbstractAxisIndices; kw...) = $f(a, parent(b); kw...)
    end
end

for f in (:zero, :one, :copy)
    @eval begin
        function Base.$f(a::AbstractAxisIndices)
            p = Base.$f(parent(a))
            return similar_type(a, typeof(p))(p, axes(a))
        end
    end
end

const CoVector = Union{Adjoint{<:Any, <:AbstractVector}, Transpose{<:Any, <:AbstractVector}}
# Two arrays
for fun in (:sum!, :prod!, :maximum!, :minimum!)
    for (A,B) in ((AbstractAxisIndices, AbstractArray),
                  (AbstractArray,       AbstractAxisIndices),
                  (AbstractAxisIndices, AbstractAxisIndices))
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

function Base.map(f, A::AbstractAxisIndices)
    p = map(f, parent(A))
    return similar_type(A, typeof(p))(p, axes(A))
end

for f in (:map, :map!)
    # Here f::F where {F} is needed to avoid ambiguities in Julia 1.0
    @eval begin
        function Base.$f(f::F, a::AbstractArray, b::AbstractAxisIndices, cs::AbstractArray...) where {F}
            p = $f(f, parent(a), parent(b), parent.(cs)...)
            axs = Broadcast.combine_axes(a, b, cs...,)
            return similar_type(b, typeof(p), typeof(axs))(p, axs)
        end

        function Base.$f(f::F, a::AbstractAxisIndices, b::AbstractAxisIndices, cs::AbstractArray...) where {F}
            p = $f(f, parent(a), parent(b), parent.(cs)...)
            axs = Broadcast.combine_axes(a, b, cs...,)
            return similar_type(b, typeof(p), typeof(axs))(p, axs)
        end

        function Base.$f(f::F, a::AbstractAxisIndices, b::AbstractArray, cs::AbstractArray...) where {F}
            p = $f(f, parent(a), parent(b), parent.(cs)...)
            axs = Broadcast.combine_axes(a, b, cs...,)
            return similar_type(a, typeof(p), typeof(axs))(p, axs)
        end
    end
end

