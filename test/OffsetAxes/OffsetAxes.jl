
include("OffsetAxis.jl")
include("CenteredAxis.jl")
include("IdentityAxis.jl")

@test OffsetArray(OffsetArray(ones(2, 2))) isa OffsetArray