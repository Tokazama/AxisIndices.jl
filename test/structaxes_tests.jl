@testset "StructAxes" begin


axis = @inferred(StructAxis{NamedTuple{(:one,:two,:three),Tuple{Int64,Int32,Int16}}}())


end
