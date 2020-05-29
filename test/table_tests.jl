@testset "Tables" begin

@testset "Tables Interface" begin
    x = Table(a = [1, 2], b = [3, 4]);
    # test that the MatrixTable `istable`
    @test Tables.istable(typeof(x))
    # test that it defines row access
    @test Tables.rowaccess(typeof(x))
    @test Tables.rows(x) == x
    # test that it defines column access
    @test Tables.columnaccess(typeof(x))
    @test Tables.columns(x) == x
    # test that we can access the first "column" of our matrix table by column name
    @test x.a == [1, 2]
    # test our `Tables.AbstractColumns` interface methods
    @test Tables.getcolumn(x, :a) == [1,2]
    @test Tables.columnnames(x) == [:a, :b]
    # now let's iterate our MatrixTable to get our first MatrixRow
    @test @inferred(Tables.schema(x)) isa Tables.Schema{(:a,:b),Tuple{Array{Int,1},Array{Int,1}}}
    @test @inferred(propertynames(x)) == [:a, :b]

    r = TableRow(1, x)
    @test Tables.columnnames(r) == [:a, :b]
    @test @inferred(propertynames(r)) == [:a, :b]

    @testset "AxisIndices interface" begin
        @test @inferred(colaxis(x)) isa StructAxis

        @test @inferred(rowaxis(x)) isa SimpleAxis
        @test @inferred(rowtype(x)) <: SimpleAxis
        @test @inferred(colaxis(x)) isa StructAxis

        @test @inferred(colaxis(r)) isa StructAxis
    end
end


#= TODO work out Table implementation
matrow = first(x)
@test eltype(mattbl) == typeof(matrow)
# now we can test our `Tables.AbstractRow` interface methods on our MatrixRow
@test matrow.Column1 == 1
@test Tables.getcolumn(matrow, :Column1) == 1
@test Tables.getcolumn(matrow, 1) == 1
@test propertynames(mattbl) == propertynames(matrow) == [:Column1, :Column2, :Column3]
=#

@testset "indexing" begin
    t = Table(A = 1:2:1000, B = repeat(1:10, inner=50), c = 1:500);
    t2 = t[1:2, 1:2];
    @test axes(t, 1) isa SimpleAxis
    @test axes(t, 2) isa StructAxis
    @test axes(t, 3) isa SimpleAxis
    @test axes(t) isa Tuple{<:SimpleAxis,<:StructAxis}
    @test ndims(t) == 2
    @test ndims(typeof(t)) == 2
    # FIXME
    @test length(t) == 500
    @test size(t) == (500, 3)
    @test size(t, 1) == 500
    @test size(t, 2) == 3
    @test size(t, 3) == 1
    @test t[1,1] == 1
    @test t[:, :A] == t.A
    @test t[1,2] == 1
    t[1,2] = 2
    @test t[1,2] == 2
    @test getproperty(t, 1) == 1:2:999

    r = t[2,:]
    @test r isa TableRow
    @test r.A == 3
    @test r[1] == 3
    @test r.B == 1
    r.B = 2
    @test r[:B] == 2
    @test getproperty(r, 2) == 2
end


end
