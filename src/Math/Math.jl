module Math

using LinearAlgebra
using Statistics
using StaticRanges
using AxisIndices.AxisCore

using Base: OneTo

export matmul_axes, get_factorization

"""
    get_factorization(F::Factorization, A::AbstractArray, d::Symbol)

Used internally to compose an `AxisIndicesArray` for each component of a factor
decomposition. `F` is the result of decomposition, `A` is an arry (likely
a subtype of `AbstractAxisIndices`), and `d` is a symbol referring to a component
of the factorization.
"""
function get_factorization end

include("matmul.jl")
include("inv.jl")
include("diagonal.jl")
include("covcor.jl")
include("svd.jl")
include("lu.jl")
include("lq.jl")
include("qr.jl")
include("eigen.jl")

end
