
to_axis(axis::AbstractAxis) = axis

function to_axis(axis::AbstractAxis, inds::AbstractUnitRange{<:Integer})
    return assign_indices(axis, inds)
end

to_axis(axis::AbstractUnitRange{<:Integer}) = SimpleAxis(axis)
to_axis(ks::AbstractVector) = Axis(ks)
to_axis(ks::AbstractVector, vs::AbstractUnitRange{<:Integer}) = Axis(ks, vs)
to_axis(len::Integer) = SimpleAxis(len)

to_axis(::StaticRanges.Static, ks, vs) = to_axis(as_static(ks), as_static(vs))
to_axis(::StaticRanges.Fixed, ks, vs) = to_axis(as_fixed(ks), as_fixed(vs))
to_axis(::StaticRanges.Dynamic, ks, vs) = to_axis(as_dynamic(ks), as_dynamic(vs))

to_axis(::StaticRanges.Static, vs) = to_axis(as_static(vs))
to_axis(::StaticRanges.Fixed, vs) = to_axis(as_fixed(vs))
to_axis(::StaticRanges.Dynamic, vs) = to_axis(as_dynamic(vs))

@inline _to_axes(S::Staticness, ks::Tuple{<:AbstractVector,Vararg{Any}}, vs::Tuple, check_length::Bool) =
    (to_axis(S, first(ks), first(vs)), _to_axes(S, maybetail(ks), maybetail(vs), check_length)...)
@inline _to_axes(S::Staticness, ks::Tuple{<:Integer,Vararg{Any}}, vs::Tuple, check_length::Bool) =
    (to_axis(S, first(vs)), _to_axes(S, maybetail(ks), maybetail(vs), check_length)...)
@inline _to_axes(S::Staticness, ks::Tuple{}, vs::Tuple, check_length::Bool) =
    (to_axis(S, first(vs)), _to_axes(S, (), maybetail(vs), check_length)...)
_to_axes(S::Staticness, ks::Tuple{}, vs::Tuple{}, check_length::Bool) = ()

