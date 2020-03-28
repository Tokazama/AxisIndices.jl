
as_axis(x) = Axis(x)
as_axis(i::Integer) = SimpleAxis(OneTo(i))
as_axis(x::AbstractAxis) = x

as_axis(x::AbstractArray, axs::Tuple) = map(axs_i -> as_axis(x, axs_i), axs)

as_axis(::T, axis::AbstractAxis) where {T} = axis

function as_axis(::T, i::Integer) where {T}
    if is_static(T)
        return SimpleAxis(OneToSRange(i))
    elseif is_fixed(T)
        return SimpleAxis(OneTo(i))
    else
        return SimpleAxis(OneToMRange(i))
    end
end

function as_simple_axis(array::A, axis, check_length::Bool=true) where {A}
    if is_static(A)
        return SimpleAxis(as_static(axis))
    elseif is_fixed(A)
        return SimpleAxis(as_fixed(axis))
    else
        return SimpleAxis(as_dynamic(axis))
    end
end

function as_axis(::T, axis, check_length::Bool=true) where {T}
    if is_static(T)
        return Axis(as_static(axis), check_length)
    elseif is_fixed(T)
        return Axis(as_fixed(axis), check_length)
    else
        return Axis(as_dynamic(axis), check_length)
    end
end

function as_axis(array::A, axis_keys::Ks, axis_values::Vs, check_length::Bool=true) where {A,Ks<:StaticRanges.OneToUnion,Vs<:StaticRanges.OneToUnion}
    if is_static(A)
        return SimpleAxis(as_static(axis_keys))
    elseif is_fixed(A)
        return SimpleAxis(as_fixed(axis_keys))
    else
        return SimpleAxis(as_dynamic(axis_keys))
    end
end

function as_axis(array::A, axis_keys::Ks, axis_values::Vs, check_length::Bool=true) where {A,Ks<:StaticRanges.UnitRangeUnion,Vs<:StaticRanges.UnitRangeUnion}
    if axis_keys == axis_values
        if is_static(A)
            return SimpleAxis(as_static(axis_keys))
        elseif is_fixed(A)
            return SimpleAxis(as_fixed(axis_keys))
        else
            return SimpleAxis(as_dynamic(axis_keys))
        end
    else
        if is_static(A)
            return Axis(as_static(axis_keys), as_static(axis_values), check_length)
        elseif is_fixed(A)
            return Axis(as_fixed(axis_keys), as_fixed(axis_values), check_length)
        else  # is_dynamic(A)
            if can_set_first(Ks)
                return Axis(as_dynamic(axis_keys), as_dynamic(axis_values), check_length)
            else
                return Axis(as_dynamic(axis_keys), UnitMRange(axis_values), check_length)
            end
        end
    end
end

function as_axis(array::A, axis_keys::Ks, axis_values::Vs, check_length::Bool=true) where {A,Ks,Vs}
    if Ks <: AbstractAxis
        if check_length & (length(axis_values) != length(axis_keys))
            error("All keys and values must have the same length as the respective axes of the parent array, got parent axis length = $(length(axis_values)) and keys length = $(length(axis_keys))")
        end
        return axis_keys
    else
        if is_static(A)
            return Axis(as_static(axis_keys), as_static(axis_values), check_length)
        elseif is_fixed(A)
            return Axis(as_fixed(axis_keys), as_fixed(axis_values), check_length)
        else  # is_dynamic(A)
            if can_set_first(Ks)
                return Axis(as_dynamic(axis_keys), as_dynamic(axis_values), check_length)
            else
                return Axis(as_dynamic(axis_keys), UnitMRange(axis_values), check_length)
            end
        end
    end
end

function as_axes(array, axis_keys::Tuple{Vararg{<:Any,M}}, axis_values::Tuple{Vararg{<:Any,N}}, check_length::Bool=true) where {N,M}
    newaxs = ntuple(N) do i
        if i > M
            as_simple_axis(array, getfield(axis_values, i), check_length)
        else
            as_axis(array, getfield(axis_keys, i), getfield(axis_values, i), check_length)
        end
    end
    return newaxs
end

