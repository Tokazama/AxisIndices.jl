
"""
    is_key_type(::T) -> Bool

Returns `true` if `T` is always considered a key for indexing. Only `CartesianIndex`
and subtypes of `Real` return `false`.
"""
is_key_type(::Type{T}) where {T} = true
is_key_type(::Type{<:CartesianIndex}) = false
is_key_type(::Type{<:Real}) = false


"""
    CombineStyle

Determines the behavior of `broadcast_axis`, `cat_axis`, `append_axis!`.
"""
abstract type CombineStyle end

struct CombineAxis <: CombineStyle end

struct CombineSimpleAxis <: CombineStyle end

struct CombineResize <: CombineStyle end

struct CombineStack <: CombineStyle end

CombineStyle(x, y) = CombineStyle(CombineStyle(x), CombineStyle(y))
CombineStyle(::T) where {T} = CombineStyle(T)
CombineStyle(::Type{T}) where {T} = CombineStack() # default
CombineStyle(::Type{T}) where {T<:AbstractAxis} = CombineAxis()
CombineStyle(::Type{T}) where {T<:AbstractSimpleAxis} = CombineSimpleAxis()
CombineStyle(::Type{T}) where {T<:AbstractRange} = CombineResize()
CombineStyle(::Type{T}) where {T<:LinearIndices{1}} = CombineResize()  # b/c it really is OneTo{Int}

CombineStyle(::CombineAxis, ::CombineStyle) = CombineAxis()
CombineStyle(::CombineStyle, ::CombineAxis) = CombineAxis()
CombineStyle(::CombineAxis, ::CombineAxis) = CombineAxis()
CombineStyle(::CombineSimpleAxis, ::CombineAxis) = CombineAxis()
CombineStyle(::CombineAxis, ::CombineSimpleAxis) = CombineAxis()

CombineStyle(::CombineSimpleAxis, ::CombineStyle) = CombineSimpleAxis()
CombineStyle(::CombineStyle, ::CombineSimpleAxis) = CombineSimpleAxis()
CombineStyle(::CombineSimpleAxis, ::CombineSimpleAxis) = CombineSimpleAxis()

CombineStyle(x::CombineStyle, y::CombineStyle) = x

