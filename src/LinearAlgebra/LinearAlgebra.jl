
include("diagonal.jl")
include("lq.jl")
include("lu.jl")
include("qr.jl")
include("svd.jl")

"""
    get_factorization(F::Factorization, axs::NTuple{2,Any}, d::Symbol)

Used internally to compose an `AxisIndicesArray` for each component of a factor
decomposition.

## QR Factorization
```jldoctest get_factorization_example
julia> using AxisIndices, LinearAlgebra

julia> m = AxisIndicesArray([1.0 2; 3 4], (Axis(2:3 => Base.OneTo(2)), Axis(3:4 => Base.OneTo(2))));

julia> F = qr(m, Val(true));

julia> keys.(axes(F.Q))
(2:3, Base.OneTo(2))

julia> keys.(axes(F.R))
(Base.OneTo(2), 3:4)

julia> keys.(axes(F.Q * F.R))
(2:3, 3:4)

julia> keys.(axes(F.p))
(2:3,)

julia> keys.(axes(F.P))
(2:3, 2:3)

julia> keys.(axes(F.P * AxisIndicesArray([1.0 2; 3 4], (2:3, 3:4))))
(2:3, 3:4)
```

## LU Factorization
```jldoctest get_factorization_example
julia> F = lu(m);

julia> keys.(axes(F.L))
(2:3, Base.OneTo(2))

julia> keys.(axes(F.U))
(Base.OneTo(2), 3:4)

julia> keys.(axes(F.p))
(2:3,)

julia> keys.(axes(F.P))
(2:3, 2:3)

julia> keys.(axes(F.P * m))
(2:3, 3:4)

julia> keys.(axes(F.L * F.U))
(2:3, 3:4)
```

## LQ Factorization
```jldoctest get_factorization_example
julia> F = lq(m);

julia> keys.(axes(F.L))
(2:3, Base.OneTo(2))

julia> keys.(axes(F.Q))
(Base.OneTo(2), 3:4)

julia> keys.(axes(F.L * F.Q))
(2:3, 3:4)
```

## SVD Factorization
```jldoctest get_factorization_example
julia> F = svd(m);

julia> axes(F.U)
(Axis(2:3 => Base.OneTo(2)), SimpleAxis(Base.OneTo(2)))

julia> axes(F.V)
(Axis(3:4 => Base.OneTo(2)), SimpleAxis(Base.OneTo(2)))

julia> axes(F.Vt)
(SimpleAxis(Base.OneTo(2)), Axis(3:4 => Base.OneTo(2)))

julia> axes(F.U * Diagonal(F.S) * F.Vt)
(Axis(2:3 => Base.OneTo(2)), Axis(3:4 => Base.OneTo(2)))
```
"""
get_factorization
