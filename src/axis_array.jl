
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
    AxisArray{T,N,P,A}(p::P, axs::A) where {T,N,P,A} = new{T,N,P,A}(p, axs)

    ###
    ### AxisArray{T,N,P}
    ###
    AxisArray{T,N,P}(A::AxisArray{T,N,P}) where {T,N,P} = A

    AxisArray{T,N,P}(A::AbstractArray, args...) where {T,N,P} = AxisArray{T,N,P}(A, args)

    function AxisArray{T,N,P}(A::AxisArray) where {T,N,P}
        return AxisArray{T,N,P}(convert(P, parent(A)), axes(A))
    end

    function AxisArray{T,N,P}(x::AbstractArray, axs::Tuple) where {T,N,P}
        return AxisArray{T,N,P}(convert(P, x), axs)
    end

    function AxisArray{T,N,P}(x::P, axs::Tuple) where {T,N,P<:AbstractArray{T,N}}
        axs = _to_axes(axs, axes(x))
        return new{T,N,P,typeof(axs)}(x, axs)
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
    function AxisArray{T,N}(A::AbstractArray{T2,N}, axis_keys::Tuple) where {T,T2,N}
        # TODO delete this if we pass tests copyto!(Array{T}(undef, size(A)), A)
        return AxisArray{T,N}(AbstractArray{T}(A), axis_keys)
    end

    function AxisArray{T,N}(init::ArrayInitializer, args...) where {T,N}
        return AxisArray{T,N}(init, args)
    end

    AxisArray{T,N}(x::AbstractArray, args...) where {T,N} = AxisArray{T,N}(x, args)

    function AxisArray{T,N}(init::ArrayInitializer, axs::Tuple{Vararg{Any,N}}) where {T,N}
        return AxisArray{T,N}(init, map(_unsafe_reconstruct, axs))
    end

    function AxisArray{T,N}(init::ArrayInitializer, axs::Tuple{Vararg{<:AbstractAxis,N}}) where {T,N}
        p = init_array(T, init, axs)
        return new{T,N,typeof(p),typeof(axs)}(p, axs)
    end

    function AxisArray{T,N}(x::AbstractArray{T,N}, axs::Tuple) where {T,N}
        axs = _to_axes(axs, axes(x))
        return new{T,N,typeof(x),typeof(axs)}(x, axs)
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
    function AxisArray{T}(x::AbstractArray, axs::Tuple, check_length::Bool=true) where {T}
        return AxisArray{T,ndims(x)}(x, axs, check_length)
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
        AxisArray(parent::AbstractArray, axes::Tuple{Vararg{AbstractAxis}}[, check_length=true])

    Construct an `AxisArray` using `parent` and explicit subtypes of `AbstractAxis`.
    If `check_length` is `true` then each dimension of parent's length is checked to match
    the length of the corresponding axis (e.g., `size(parent 1) == length(axes[1])`.

    ## Examples
    ```jldoctest
    julia> using AxisIndices

    julia> AxisArray(ones(2,2), (SimpleAxis(2), SimpleAxis(2)))
    2×2 AxisArray{Float64,2}
     • dim_1 - 1:2
     • dim_2 - 1:2
            1     2
      1   1.0   1.0
      2   1.0   1.0

    ```
    """
    function AxisArray(x::AbstractArray{T,N}, axs::Tuple{Vararg{<:AbstractAxis,N}}) where {T,N}
        for i in 1:N
            check_axis_length(getfield(axs, i), axes(x, i))
        end
        return new{T,N,typeof(x),typeof(axs)}(x, axs)
    end

    """
        AxisArray(parent::AbstractArray, keys::Tuple[, values=axes(parent), check_length=true])

    Given an the some array `parent` and a tuple of vectors `keys` corresponding to
    each dimension of `parent` constructs an `AxisArray`. Each element of `keys`
    is paired with an element of `values` to compose a subtype of `AbstractAxis`.
    `values` map the `keys` to the indices of `parent`.

    ## Examples
    ```jldoctest
    julia> using AxisIndices

    julia> AxisArray(ones(2,2), (["a", "b"], ["one", "two"]))
    2×2 AxisArray{Float64,2}
     • dim_1 - ["a", "b"]
     • dim_2 - ["one", "two"]
          one   two
      a   1.0   1.0
      b   1.0   1.0

    ```
    """
    function AxisArray(x::AbstractArray{T,N}, ks::Tuple{Vararg{Any,N2}}, inds::Tuple=axes(x)) where {T,N,N2}
        axs = _to_axes(ks, inds)
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

    function AxisArray(x::AbstractVector{T}) where {T}
        if can_change_size(x)
            axs = (SimpleAxis(axes(x, 1)),)
        else
            axs = (SimpleAxis(OneToMRange(length(x))),)
        end
        return new{T,1,typeof(x),typeof(axs)}(x, axs)
    end

    function AxisArray(x::AbstractVector{T}, ks::AbstractAxis) where {T}
        check_axis_length(ks, axes(x, 1))
        return new{T,1,typeof(x),Tuple{typeof(ks)}}(x, (ks,))
    end

    function AxisArray(x::AbstractVector{T}, ks::AbstractVector) where {T}
        if can_change_size(x)
            axs = (Axis(ks, axes(x, 1)),)
        else
            axs = (Axis(ks, OneToMRange(length(x))),)
        end
        return new{T,1,typeof(x),typeof(axs)}(x, axs)
    end


    AxisArray(x::AbstractVector{T}, ks::Tuple{}) where {T} = AxisArray(x)

    AxisArray(x::AbstractVector{T}, ks::Tuple) where {T} = AxisArray{T}(x, ks)

    function AxisArray(x::AbstractArray{T,0}, axs::Tuple{}=()) where {T}
        return new{T,0,typeof(x),Tuple{}}(x, ())
    end

    function AxisArray(
        x::AbstractVector{T},
        axs::Tuple{<:AbstractAxis},
        check_length::Bool=true
    ) where {T}

        axis = first(axs)
        if check_length && parentindices(axis) != axes(x, 1)
            error("provided axis doesn't have same indices as provided vector")
        end
        return AxisArray{T,1,typeof(x),typeof(axs)}(x, axs)
    end
end

Base.IndexStyle(::Type{A}) where {A<:AxisArray} = IndexStyle(parent_type(A))

ArrayInterface.parent_type(::Type{T}) where {P,T<:AxisArray{<:Any,<:Any,P}} = P
@inline function ArrayInterface.can_change_size(::Type{T}) where {D,Axs,T<:AxisArray{<:Any,<:Any,D,Axs}}
    if can_change_size(D)
        return _can_change_axes_size(Axs)
    else
        return false
    end
end

@generated function _can_change_axes_size(::Type{T}) where {T<:Tuple}
    for i in T.parameters
        can_change_size(i) && return true
    end
    return false
end

Base.parentindices(x::AxisArray) = parentindices(parent(x))

Base.length(x::AxisArray) = prod(size(x))

Base.size(x::AxisArray) = map(length, axes(x))

function Base.axes(x::AxisArray, i::Integer)
    if i < 1
        error("BoundsError: attempt to access $(typeof(x)) at dimension $i")
    else
        return unsafe_axes(x, i)
    end
end

function unsafe_axes(x, i)
    if i > ndims(x)
        return SimpleAxis(1)
    else
        return getfield(axes(x), i)
    end
end

Base.axes(x::AxisArray) = getfield(x, :axes)

Base.parent(x::AxisArray) = getfield(x, :data)

