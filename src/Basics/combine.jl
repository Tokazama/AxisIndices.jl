
"""
    CombineStyle

Abstract type that determines the behavior of `broadcast_axis`, `cat_axis`, `append_axis!`.
"""
abstract type CombineStyle end

"""
    CombineAxis

Subtype of `CombineStyle` that informs relevant methods to produce a subtype of `AbstractAxis`.
"""
struct CombineAxis <: CombineStyle end

"""
    CombineSimpleAxis

Subtype of `CombineStyle` that informs relevant methods to produce a subtype of `AbstractSimpleAxis`.
"""
struct CombineSimpleAxis <: CombineStyle end

"""
    CombineResize

Subtype of `CombineStyle` that informs relevant methods that axes should be combined by
resizing a collection (as opposed to by concatenation or appending).
"""
struct CombineResize <: CombineStyle end

"""
    CombineStack

Subtype of `CombineStyle` that informs relevant methods that axes should be combined by
stacking elements in some whay (as opposed to resizing a collection).
"""
struct CombineStack <: CombineStyle end

CombineStyle(x, y...) = CombineStyle(CombineStyle(x), CombineStyle(y...))
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

