@testset "to_axes" begin
    A = ones(2,2)
    args = (:,:)
    new_indices = axes(A)

    @test @inferred(to_axes(AxisArray(A), args, new_indices, new_indices)) ===
          (SimpleAxis(Base.OneTo(2)), SimpleAxis(Base.OneTo(2)))

    A = ones(2)
    args = (:,)
    new_indices = axes(A)
    @test @inferred(to_axes(AxisArray(A), args, new_indices, new_indices)) === (SimpleAxis(Base.OneTo(2)),)

    A = ones(2,2)
    args = (:,1)
    new_indices = (Base.OneTo(2),)
    @test @inferred(to_axes(AxisArray(A), args, (Base.OneTo(2), 1), new_indices)) === (SimpleAxis(Base.OneTo(2)),)
end
