


A = [1 2; 3 4]
Aaxes = AxisIndicesArray(A, ["a", "b"], 2.0:3.0)

A_view = @inferred(view(A, :, 1))
Aaxes_view = @inferred(view(Aaxes, :, 1))
@test A_view == Aaxes_view

fill!(A_view, 0)
fill!(Aaxes_view, 0)
@test A_view == Aaxes_view
@test A_view == Aaxes_view


  | idxs::Tuple{Int64,Base.Slice{Axis{Int64,Int64,UnitMRange{Int64},UnitMRange{Int64}}}}
axs = (1, Base.Slice(Axis(UnitMRange(2:4) => UnitMRange(1:3))))

to_indices(Aaxes, axes(Aaxes), axs)

A_named = NamedDimsArray{(:a,:b)}(A)

dims = 3
slices = [[111 121; 211 221], [112 122; 212 222]]
cat_slices = cat(slices...; dims=3)
A = AxisIndicesArray(cat_slices, (2:3, 3:4, 4:5));

eachslice(a; dims=3)


