
abstract type AxisParameter <: Function end

abstract type PadsParameter{F,L} <: AxisParameter end

abstract type FillPads{F,L} <: PadsParameter{F,L} end

"""
    AxisInitializer <: Function

Supertype for functions that assist in initialization of `AbstractAxis` subtypes.
"""
abstract type AxisInitializer <: Function end

abstract type PaddedInitializer <: AxisInitializer end

"""
    AbstractAxis

An `AbstractVector` subtype optimized for indexing.
"""
abstract type AbstractAxis{P} <: AbstractUnitRange{Int} end

Base.parent(axis::AbstractAxis) = getfield(axis, :parent)

ArrayInterface.parent_type(::Type{T}) where {P,T<:AbstractAxis{P}} = P

"""
    AbstractOffsetAxis{I,Inds}

Supertype for axes that begin indexing offset from one. All subtypes of `AbstractOffsetAxis`
use the keys for indexing and only convert to the underlying indices when
`to_index(::OffsetAxis, ::Integer)` is called (i.e. when indexing the an array
with an `AbstractOffsetAxis`.

See also: [`OffsetAxis`](@ref), [`CenteredAxis`](@ref)
"""
abstract type AbstractOffsetAxis{O,P} <: AbstractAxis{P} end

"""
    IndexAxis

Index style for mapping keys to an array's parent indices.
"""
struct IndexAxis <: IndexStyle end
Base.IndexStyle(::Type{T}) where {T<:AbstractAxis} = IndexAxis()


include("types.jl")
include("lazy_vcat.jl")
include("lazy_index.jl")
include("parameters.jl")
include("initializers.jl")
include("keys.jl")
include("checkindex.jl")
include("getindex.jl")
include("to_index.jl")
include("compose.jl")
include("broadcast.jl")
include("cat.jl")
include("range_interface.jl")
include("resize.jl")

