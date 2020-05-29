
@testset "NamedMetaAxisArray" begin
    nma1 = NamedMetaAxisArray{(:dim_1,:dim_2)}(ones(Int, 2, 2), ["a", "b"], [:one, :two]);
    nma2 = NamedMetaAxisArray(ones(Int, 2, 2), (dim_1 = ["a", "b"], dim_2 = [:one, :two]));
    nma3 = NamedMetaAxisArray{(:dim_1,:dim_2),Int}(undef, ["a", "b"], [:one, :two]);
    nma4 = NamedMetaAxisArray{(:dim_1,:dim_2),Int,2}(undef, ["a", "b"], [:one, :two]);

    @test typeof(nma1) <: typeof(nma2)
    @test typeof(nma3) <: typeof(nma4)
    @test axes(nma1) == axes(nma2) == axes(nma3) == axes(nma4)
    @test dimnames(nma1) == dimnames(nma2) == dimnames(nma3) == dimnames(nma4)
end
