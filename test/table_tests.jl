@testset "AxisTables" begin
#

x = AxisTable(a = [1, 2], b = [3, 4]);
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
@test Tables.getcolumn(x, 1) == [1,2]
@test Tables.columnnames(x) == [:a, :b]
# now let's iterate our MatrixTable to get our first MatrixRow
#= TODO work out AxisTable implementation
matrow = first(x)
@test eltype(mattbl) == typeof(matrow)
# now we can test our `Tables.AbstractRow` interface methods on our MatrixRow
@test matrow.Column1 == 1
@test Tables.getcolumn(matrow, :Column1) == 1
@test Tables.getcolumn(matrow, 1) == 1
@test propertynames(mattbl) == propertynames(matrow) == [:Column1, :Column2, :Column3]
=#


end
