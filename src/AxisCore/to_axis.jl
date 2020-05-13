
# 1 arg
to_axis(axis::AbstractAxis) = axis
to_axis(ks::AbstractVector) = Axis(ks)
to_axis(axis::StaticRanges.OneToUnion{<:Integer}) = SimpleAxis(axis)
#to_axis(axis::AbstractUnitRange{<:Integer}) = SimpleAxis(axis)
to_axis(len::Integer) = SimpleAxis(len)

# 2 arg
to_axis(ks::Nothing,        vs::AbstractUnitRange{<:Integer}) = SimpleAxis(vs)
to_axis(ks::AbstractVector, vs::AbstractUnitRange{<:Integer}) = Axis(ks, vs)
to_axis(ks::AbstractAxis,   vs::AbstractUnitRange{<:Integer}) = resize_last(ks, vs)

# 3 arg
to_axis(axis::AbstractAxis,       ks,               vs::AbstractUnitRange, check_length::Bool=true) = similar(axis, ks, vs, check_length)
to_axis(axis::AbstractSimpleAxis, ks,               vs::AbstractUnitRange, check_length::Bool=true) = _to_axis(axis, ks, vs, check_length)
to_axis(axis::AbstractAxis,       ks::Nothing,      vs::AbstractUnitRange, check_length::Bool=true) = resize_last(axis, vs)
to_axis(axis::AbstractSimpleAxis, ks::Nothing,      vs::AbstractUnitRange, check_length::Bool=true) = resize_last(axis, vs)
to_axis(axis::AbstractAxis,       ks::AbstractAxis, vs::AbstractUnitRange, check_length::Bool=true) = similar(axis, keys(ks), vs, check_length)

# Do an additional pass to ensure that the user really wants to abandon the old_axis type,
# b/c we can't have keys diffent from indices with an AbstractSimpleAxis
function _to_axis(axis::AbstractSimpleAxis, ks::OneToUnion, vs::OneToUnion, check_length::Bool)
    check_length && check_axis_length(ks, vs)
    return unsafe_reconstruct(axis, ks)
end
#...but we can only do that in a type stable way with OneTo
function _to_axis(axis::AbstractSimpleAxis, ks, vs, check_length::Bool)
    return Axis(ks, vs, check_length)
end



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

