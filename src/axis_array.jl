
@inline function compose_axes(::Tuple{}, x::AbstractArray{<:Any,N}) where {N}
    if N === 0
        return ()
    elseif N === 1 && can_change_size(x)
        return (compose_axis(OneToMRange(length(x))),)
    else
        return map(compose_axis, axes(x))
    end
end
function compose_axes(ks::Tuple{Vararg{<:Any,N}}, x::AbstractArray{<:Any,N}) where {N}
    if N === 0
        return ()
    elseif N === 1 && can_change_size(x)
        return compose_axes(ks, (OneToMRange(length(x)),))
    else
        return compose_axes(ks, axes(x))
    end
end
function compose_axes(ks::Tuple, x::AbstractArray{<:Any,N}) where {N}
    throw(DimensionMismatch("Number of axis arguments provided ($(length(ks))) does " *
                            "not match number of parent axes ($N)."))
end
@inline function compose_axes(ks::Tuple{Vararg{<:Any,N}}, inds::Tuple{Vararg{<:Any,N}}) where {N}
    return (
        compose_axis(first(ks), first(inds)),
        compose_axes(tail(ks), tail(inds))...
    )
end
compose_axes(::Tuple{}, ::Tuple{}) = ()
compose_axes(::Tuple{}, inds::Tuple) = map(compose_axis, inds)
compose_axes(axs::Tuple, ::Tuple{}) = map(compose_axis, axs)

###
### compose_axis
###
compose_axis(x::Integer) = SimpleAxis(x)
compose_axis(x) = Axis(x)
compose_axis(x::AbstractAxis) = x
function compose_axis(x::AbstractUnitRange{I}) where {I<:Integer}
    if known_first(x) === one(eltype(x))
        return SimpleAxis(x)
    else
        return OffsetAxis(x)
    end
end
compose_axis(x::IdentityUnitRange) = compose_axis(x.indices)

# 3-args
compose_axis(::Nothing, inds) = compose_axis(inds)
compose_axis(ks::Function, inds) = ks(inds)
function compose_axis(ks::Integer, inds)
    if ks isa StaticInt
        return SimpleAxis(known_first(inds):ks)
    else
        return SimpleAxis(inds)
    end
end
function compose_axis(ks, inds)
    check_axis_length(ks, inds)
    return _compose_axis(ks, inds)
end
function _compose_axis(ks::AbstractAxis, inds)
    # if the indices are the same then don't reconstruct
    if first(parent(ks)) == first(inds)
        return copy(ks)
    else
        return unsafe_reconstruct(ks, inds)
    end
end
@inline function _compose_axis(ks, inds)
    start = known_first(ks)
    if known_step(ks) === 1
        if known_first(ks) === nothing
            return OffsetAxis(first(ks) - static_first(inds), inds)
        elseif known_first(ks) === known_first(inds)
            # if we don't know the length of `inds` but we know the length of `ks` then we
            # should reconstruct `inds` so that it has a static length
            if known_last(inds) === nothing && known_last(ks) !== nothing
                return set_length(inds, static_length(ks))
            else
                return copy(inds)
            end
        else
            return OffsetAxis(static_first(ks) - static_first(inds), inds)
        end
    else
        check_unique_keys(ks)
        T = Axis{eltype(ks),eltype(inds),typeof(ks),typeof(inds)}
        return unsafe_initialize(T, (ks, inds))
    end
end

"""
    AxisArray{T,N,P,AI}

An array struct that wraps any parent array and assigns it an `AbstractAxis` for
each dimension. The first argument is the parent array and the second argument is
a tuple of subtypes to `AbstractAxis` or keys that will be converted to subtypes
of `AbstractAxis` with the provided keys.
"""
struct AxisArray{T,N,D,Axs<:Tuple{Vararg{<:Any,N}}} <: AbstractArray{T,N}
    data::D
    axes::Axs

    # TODO robust checking of indices should happen at this level
    # FIXME this needs to check that all axs are AbstractAxis
    function AxisArray{T,N,P,A}(p::P, axs::A) where {T,N,P,A}
        for i in OneTo(N)
            check_axis_length(axs[i], axes(p, i))
        end
        return new{T,N,P,A}(p, axs)
    end

    ###
    ### AxisArray{T,N,P}
    ###
    function AxisArray{T,N,P}(x::P, axs::Tuple) where {T,N,P<:AbstractArray{T,N}}
        axs = compose_axes(axs, x)
        return new{T,N,P,typeof(axs)}(x, axs)
    end

    AxisArray{T,N,P}(A::AxisArray{T,N,P}) where {T,N,P} = A

    AxisArray{T,N,P}(A::AbstractArray, args...) where {T,N,P} = AxisArray{T,N,P}(A, args)

    function AxisArray{T,N,P}(A::AxisArray; kwargs...) where {T,N,P}
        return AxisArray{T,N,P}(convert(P, parent(A)), axes(A); kwargs...)
    end

    function AxisArray{T,N,P}(x::AbstractArray, axs::Tuple) where {T,N,P}
        return AxisArray{T,N,P}(convert(P, x), axs)
    end

    # TODO fix/clean up these docs
    """
        AxisArray{T,N}(undef, dims::NTuple{N,Integer})
        AxisArray{T,N}(undef, keys::NTuple{N,AbstractVector})

    Construct an uninitialized `N`-dimensional array containing elements of type `T` were
    the size of each dimension is equal to the corresponding integer in `dims`.

    Construct an uninitialized `N`-dimensional array containing elements of type `T` were
    the size of each dimension is determined by the length of the corresponding collection
    in `keys.


    ## Examples
    ```jldoctest
    julia> using AxisIndices

    julia> size(AxisArray{Int,2}(undef, (2,2)))
    (2, 2)

    julia> size(AxisArray{Int,2}(undef, (["a", "b"], [:one, :two])))
    (2, 2)

    """
    function AxisArray{T,N}(A::AbstractArray, ks::Tuple) where {T,N}
        if eltype(A) <: T
            axs = compose_axes(ks, A)
            return new{T,N,typeof(A),typeof(axs)}(p, axs)
        else
            p = AbstractArray{T}(A)
            axs = compose_axes(ks, p)
            return new{T,N,typeof(p),typeof(axs)}(p, axs)
        end
    end
    function AxisArray{T,N}(x::AbstractArray{T,N}, axs::Tuple) where {T,N}
        axs = compose_axes(axs, x)
        return new{T,N,typeof(x),typeof(axs)}(x, axs)
    end
    function AxisArray{T,N}(A::AxisArray, ks::Tuple) where {T,N}
        if eltype(A) <: T
            axs = compose_axes(ks, A)
            return new{T,N,parent_type(A),typeof(axs)}(p, axs)
        else
            p = AbstractArray{T}(parent(A))
            axs = compose_axes(ks, A)
            return new{T,N,typeof(p),typeof(axs)}(p, axs)
        end
    end
    function AxisArray{T,N}(init::ArrayInitializer, args...; kwargs...) where {T,N}
        return AxisArray{T,N}(init, args; kwargs...)
    end
    AxisArray{T,N}(x::AbstractArray, args...) where {T,N} = AxisArray{T,N}(x, args)
    function AxisArray{T,N}(init::ArrayInitializer, ks::Tuple{Vararg{<:Any,N}}) where {T,N}
        axs = map(compose_axis, ks)
        p = init_array(T, init, axs)
        return new{T,N,typeof(p),typeof(axs)}(p, axs)
    end

    ### AxisArray{T}
    """
        AxisArray{T}(undef, keys::NTuple{N,AbstractVector})

    Construct an uninitialized `N`-dimensional array containing elements of type `T` were
    the size of each dimension is determined by the length of the corresponding collection
    in `keys.

    ## Examples
    ```jldoctest
    julia> using AxisIndices

    julia> size(AxisArray{Int}(undef, (["a", "b"], [:one, :two])))
    (2, 2)
    ```
    """
    function AxisArray{T}(x::AbstractArray, axs::Tuple) where {T}
        return AxisArray{T,ndims(x)}(x, axs)
    end
    function AxisArray{T}(x::AbstractArray, axs::Vararg) where {T}
        return AxisArray{T,ndims(x)}(x, axs)
    end
    function AxisArray{T}(init::ArrayInitializer, axs::Tuple) where {T}
        return AxisArray{T,length(axs)}(init, axs)
    end
    function AxisArray{T}(init::ArrayInitializer, axs::Vararg) where {T}
        return AxisArray{T,length(axs)}(init, axs)
    end

    """
        AxisArray(parent::AbstractArray, axes::Tuple)

    Construct an `AxisArray` using `parent` and explicit subtypes of `AbstractAxis`.
    If `check_length` is `true` then each dimension of parent's length is checked to match
    the length of the corresponding axis (e.g., `size(parent 1) == length(axes[1])`.

    ## Examples
    ```jldoctest
    julia> using AxisIndices

    julia> AxisArray(ones(2,2), (SimpleAxis(2), SimpleAxis(2)))
    2×2 AxisArray(::Array{Float64,2}
      • axes:
         1 = 1:2
         2 = 1:2
    )
         1    2
      1  1.0  1.0
      2  1.0  1.0

    julia> AxisArray(ones(2,2), (["a", "b"], ["one", "two"]))
    2×2 AxisArray(::Array{Float64,2}
      • axes:
         1 = ["a", "b"]
         2 = ["one", "two"]
    )
           "one"   "two"
      "a"  1.0     1.0
      "b"  1.0     1.0

    ```
    """
    function AxisArray(x::AbstractArray{T,N}, ks::Tuple) where {T,N}
        axs = compose_axes(ks, x)
        return new{T,N,typeof(x),typeof(axs)}(x, axs)
    end

    """
        AxisArray(parent::AbstractArray, args...) -> AxisArray(parent, tuple(args))

    Passes `args` to a tuple for constructing an `AxisArray`.

    ## Examples
    ```jldoctest
    julia> using AxisIndices

    julia> A = AxisArray(reshape(1:9, 3,3), 2:4, 3.0:5.0);

    julia> A[1, 1]
    1

    julia> A[==(2), ==(3.0)]
    1

    julia> A[1:2, 1:2] == [1 4; 2 5]
    true

    julia> A[<(4), <(5.0)] == [1 4; 2 5]
    true
    ```
    """
    AxisArray(x::AbstractArray, args...) = AxisArray(x, args)

    #= TODO delete this?
    function AxisArray(x::AbstractVector{T}; kwargs...) where {T}
        if can_change_size(x)
            axs = (SimpleAxis(OneToMRange(length(x))),)
        else
            axs = (SimpleAxis(axes(x, 1)),)
        end
        return new{T,1,typeof(x),typeof(axs)}(x, axs)
    end

    function AxisArray(x::AbstractVector{T}, ks::AbstractAxis) where {T}
        check_axis_length(ks, axes(x, 1))
        return new{T,1,typeof(x),Tuple{typeof(ks)}}(x, (ks,))
    end

    function AxisArray(x::AbstractVector{T}, ks::AbstractVector) where {T}
        if can_change_size(x)
            axs = (Axis(ks, OneToMRange(length(x))),)
        else
            axs = (Axis(ks, axes(x, 1)),)
        end
        return new{T,1,typeof(x),typeof(axs)}(x, axs)
    end

    AxisArray(x::AbstractVector{T}, ks::Tuple{}; kwargs...) where {T} = AxisArray(x)

    AxisArray(x::AbstractVector{T}, ks::Tuple; kwargs...) where {T} = AxisArray{T}(x, ks)

    function AxisArray(x::AbstractArray{T,0}, axs::Tuple{}=()) where {T}
        return new{T,0,typeof(x),Tuple{}}(x, ())
    end

    function AxisArray(x::AbstractVector{T}, ks::Tuple) where {T}
        return new{T,1,typeof(x),typeof(axs)}(x, axs)
    end
    =#
end

function initialize_axis_array(data, axs)
    return unsafe_initialize(
        AxisArray{eltype(data),ndims(data),typeof(data),typeof(axs)},
        (data, axs)
    )
end

Base.axes(x::AxisArray) = getfield(x, :axes)

Base.parent(x::AxisArray) = getfield(x, :data)

ArrayInterface.parent_type(::Type{T}) where {P,T<:AxisArray{<:Any,<:Any,P}} = P
@inline function ArrayInterface.can_change_size(::Type{T}) where {D,Axs,T<:AxisArray{<:Any,<:Any,D,Axs}}
    if can_change_size(D)
        return _can_change_axes_size(Axs)
    else
        return false
    end
end
ArrayInterface.can_setindex(::Type{T}) where {T<:AxisArray} = can_setindex(parent_type(T))

@generated function _can_change_axes_size(::Type{T}) where {T<:Tuple}
    for i in T.parameters
        can_change_size(i) && return true
    end
    return false
end

Base.parentindices(x::AxisArray) = parentindices(parent(x))

Base.length(x::AxisArray) = prod(size(x))
@generated function ArrayInterface.known_length(::Type{T}) where {Axs,T<:AxisArray{<:Any,<:Any,<:Any,Axs}}
    out = 1
    for axis in Axs.parameters
        known_length(axis) === nothing && return nothing
        out = out * known_length(axis)
    end
    return out
end

Base.size(x::AxisArray) = map(static_length, axes(x))

@inline function Base.axes(x::AxisArray, i::Integer)
    if i < 1
        error("BoundsError: attempt to access $(typeof(x)) at dimension $i")
    else
        return unsafe_axes(axes(x), i)
    end
end

@inline unsafe_axes(axs::Tuple, ::StaticInt{I}) where {I} = unsafe_axes(axs, I)
@inline function unsafe_axes(axs::Tuple, i)
    if i > length(axs)
        return SimpleAxis(1)
    else
        return getfield(axs, i)
    end
end

Base.eachindex(A::AxisArray) = eachindex(IndexStyle(A), A)

Base.eachindex(::IndexCartesian, A::AxisArray{T,N}) where {T,N} = CartesianIndices(axes(A))
function Base.eachindex(S::IndexLinear, A::AxisArray{T,N}) where {T,N}
    if N === 1
        return axes(A, 1)
    else
        return compose_axis(eachindex(S, parent(A)))
    end
end


Base.eachindex(A::AxisArray{T,1}) where {T} = axes(A, 1)

function ArrayInterface.unsafe_reconstruct(A::AxisArray, data; axes=nothing, kwargs...)
    return _unsafe_reconstruct(A, data, axes)
end

# TODO function _unsafe_reconstruct(A, data, ::Nothing) end
_unsafe_reconstruct(A, data, axs) = initialize_axis_array(data, axs)


###
### getindex
###
@inline function ArrayInterface.unsafe_get_element(A::AxisArray, inds)
    if is_dense_wrapper(A)
        return @inbounds(parent(A)[apply_offsets(A, inds)...])
    else
        return _unsafe_get_element(A, apply_offsets(A, inds))
    end
end
# other methods in padded_axis.jl
@inline _unsafe_get_element(A, inds::Tuple{Vararg{Integer}}) = @inbounds(parent(A)[inds...])

function ArrayInterface.unsafe_get_collection(A::AxisArray, inds)
    axs = to_axes(A, inds)
    dest = AxisArray(similar(parent(A), length.(axs)), axs)
    if map(Base.unsafe_length, axes(dest)) == map(Base.unsafe_length, axs)
        Base._unsafe_getindex!(dest, A, inds...) # usually a generated function, don't allow it to impact inference result
    else
        Base.throw_checksize_error(dest, axs)
    end
    return dest
end



function ArrayInterface.unsafe_set_element!(A::AxisArray, value, inds)
    return @inbounds(setindex!(parent(A), value, apply_offsets(A, inds)...))
end

# * apply_offsets helps apply offsets for offset axes and if there is a padded region
#   applies the padding.
# * If padding returns a function instead of redirecting to a another index, then we
#   filter out the function and apply it to the array to grab the value that represents
#   padded regions
@inline function apply_offsets(A::AxisArray, inds::Tuple)
    if length(inds) === 1 && ndims(A) > 1 # linear indexing
        return (_sub_offset(eachindex(A), first(inds)),)
    else
        return apply_offsets(axes(A), inds)
    end

    #=
    if new_inds isa Tuple{Vararg{<:Integer}}
        return new_inds
    else
        return _filter_pad(new_inds)
    end
    =#
end

_filter_pad(inds::Tuple{I,Vararg}) where {I<:Function} = first(inds)
@inline _filter_pad(inds::Tuple{<:Integer,Vararg}) = _filter_pad(tail(inds))

###
### SubArray
###
#=
@propagate_inbounds function Base.getindex(A::SubArray{T,N,<:AxisArray{T,N}}, args...) where {T,N}
    return ArrayInterface.getindex(A, args...)
end
@propagate_inbounds function Base.getindex(A::SubArray{T,N,<:AxisArray{T,N}}, args::Vararg{Int,N}) where {T,N}
    return ArrayInterface.getindex(A, args...)
end

function ArrayInterface.unsafe_set_element!(A::AxisArray, value, inds)
    return @inbounds(setindex!(parent(A), value, apply_offsets(A, inds)...))
end

=#
@inline function ArrayInterface.to_axes(A::AxisArray, inds::Tuple)
    if ndims(A) === 1
        return (to_axis(axes(A, 1), first(inds)),)
    elseif ArrayInterface.is_linear_indexing(A, inds)
        return (to_axis(eachindex(IndexLinear(), A), first(inds)),)
    else
        return to_axes(A, axes(A), inds)
    end
end

"""
    is_dense_wrapper(::Type{T}) where {T} -> Bool

Do all the indices of `T` map to a unique indice of the parent data that is wrapped?
This is not true for padded axes.
"""
is_dense_wrapper(x) = is_dense_wrapper(typeof(x))
is_dense_wrapper(::Type{T}) where {T} = true
@generated function is_dense_wrapper(::Type{T}) where {Axs,T<:AxisArray{<:Any,<:Any,<:Any,Axs}}
    for i in Axs.parameters
        is_dense_wrapper(i) || return false
    end
    return true
end

@inline function Base.IndexStyle(::Type{A}) where {A<:AxisArray}
    if is_dense_wrapper(A)
        return IndexStyle(parent_type(A))
    else
        return IndexCartesian()
    end
end

