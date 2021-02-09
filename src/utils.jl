# things that don't directly have anything to do with this package but are necessary

@generated unsafe_initialize(::Type{T}, args::Tuple) where {T} = Expr(:splatnew, :T, :args)

# Val wraps the number of axes to retain
naxes(A::AbstractArray, v::Val) = naxes(axes(A), v)
naxes(axs::Tuple, v::Val{N}) where {N} = _naxes(axs, N)
@inline function _naxes(axs::Tuple, i::Int)
    if i === 0
        return ()
    else
        return (first(axs), _naxes(tail(axs), i - 1)...)
    end
end

@inline function _naxes(axs::Tuple{}, i::Int)
    if i === 0
        return ()
    else
        return (SimpleAxis(1), _naxes((), i - 1)...)
    end
end

known_offset1(::Type{T}) where {T} = first(known_offsets(T))

offset1(::Type{T}) where {T} = first(offsets(T))




function same_root_offset(::Type{A}, ::Type{I}) where {A<:SimpleAxis,I}
    offset_axis1(A) === offset_axis1(I)
end
function same_root_offset(::Type{A}, ::Type{I}) where {A<:AbstractAxis,I}
    return same_root_offset(parent_type(A), I)
end

is_dynamic(x) = is_dynamic(typeof(x))
function is_dynamic(::Type{T}) where {T}
    if can_change_size(T) || ismutable(T)
        return true
    elseif parent_type(T) <: T
        return false
    else
        return is_dynamic(parent_type(T))
    end
end

function is_dynamic(::Type{T}) where {K,Ks,T<:Axis{K,Ks}}
    return is_dynamic(Ks) || is_dynamic(parent_type(T))
end

function assign_indices(axis, inds)
    if can_change_size(axis) && !((known_length(inds) === nothing) || known_length(inds) === known_length(axis))
        return unsafe_reconstruct(axis, inds)
    else
        return axis
    end
end

function throw_offset_error(@nospecialize(axis))
    throw("Cannot wrap axis $axis due to offset of $(first(axis))")
end
