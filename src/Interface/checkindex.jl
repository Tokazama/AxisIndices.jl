# check_index - basically checkindex but passes a style trait argument
@propagate_inbounds function check_index(axis, arg)
    return check_index(AxisIndicesStyle(axis, arg), axis, arg)
end

@propagate_inbounds function check_index(axis, arg::Indices)
    return check_index(AxisIndicesStyle(axis, arg), axis, arg.x)
end

@propagate_inbounds function check_index(axis, arg::Keys)
    return check_index(AxisIndicesStyle(axis, arg), axis, arg.x)
end

check_index(::KeyElement, axis, arg) = arg in keys(axis)

check_index(::IndexElement, axis, arg) = arg in indices(axis)

check_index(::BoolElement, axis, arg) = checkindex(Bool, indices(axis), arg)

check_index(::CartesianElement, axis, arg) = checkindex(Bool, indices(axis), first(arg.I))

check_index(::KeysCollection, axis, arg) = length(find_all_in(arg, keys(axis))) == length(arg)

check_index(::IndicesCollection, axis, arg) = length(find_all_in(arg, indices(axis))) == length(arg)

check_index(::BoolsCollection, axis, arg) = checkindex(Bool, indices(axis), arg)

check_index(::IntervalCollection, axis, arg) = true

check_index(::KeysIn, axis, arg) = length(find_all_in(arg.x, keys(axis))) == length(arg.x)

check_index(::IndicesIn, axis, arg) = length(find_all_in(arg.x, indices(axis))) == length(arg.x)

check_index(::KeyEquals, axis, arg) = !isa(find_first(arg, keys(axis)), Nothing)

check_index(::IndexEquals, axis, arg) = checkbounds(Bool, indices(axis), arg.x)

check_index(::KeysFix2, axis, arg) = true

check_index(::IndicesFix2, axis, arg) = true

check_index(::SliceCollection, axis, arg) = true

check_index(::KeyedStyle{S}, axis, arg) where {S} = check_index(S, axis, arg)


