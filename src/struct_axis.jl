
@generated _fieldnames(::Type{T}) where {T} = fieldnames(T)
_fieldcount(::Type{T}) where {T} = length(_fieldnames(T))
 
"""
    StructAxis{T}

An axis that uses a structure `T` to form its keys.
"""
struct StructAxis{T,Inds} <: AbstractAxis{Int,Inds}
    parent::Inds

    function StructAxis{T,Inds}(inds::Inds) where {T,Inds}
        if typeof(T) <: DataType
            new{T,Inds}(inds)
        else
            throw(ArgumentError("Type must be have all field fully paramterized, got $T"))
        end
    end

    function StructAxis{T}(inds::AbstractAxis) where {T}
        fc = _fieldcount(T)
        if known_length(inds) === fc
            return StructAxis{T,typeof(inds)}(inds)
        else
            if known_first(inds) === nothing
                throw(ArgumentError("StructAxis cannot have a parent type whose first index and last index are not known at compile time."))
            else
                f = static_first(inds)
                l = f + StaticInt(fc) - One()
                return StructAxis{T}(unsafe_reconstruct(inds, f:l))
            end
        end
    end
    StructAxis{T}(inds) where {T} = StructAxis{T}(compose_axis(inds))
    function StructAxis{T}() where {T}
        inds = SimpleAxis(One():StaticInt{_fieldcount(T)}())
        return new{T,typeof(inds)}(inds)
    end
end

Base.parent(axis::StructAxis) = getfield(axis, :parent)

@inline Base.propertynames(axis::StructAxis{T}) where {T} = (_fieldnames(T), propertynames(parent(axis))...)
@inline function Base.getproperty(axis::StructAxis{T}, k::Symbol) where {T}
    i = _to_field_index(T, k)
    if i === 0
        return getproperty(parent(axis), k)
    else
        return @inbounds(parent(axis)[i + (One() - static_first(axis))])
    end
end

function Base.keys(axis::StructAxis{T}) where {T}
    return initialize_axis_array(
        Symbol[fieldnames(T)...],
        (SimpleAxis(One():static_length(axis)),)
    )
end

# TODO ArrayInterface.unsafe_reconstruct(axis::StructAxis
@inline function ArrayInterface.unsafe_reconstruct(axis::StructAxis{T}, inds) where {T}
    if known_length(inds) === known_length(axis)
        return StructAxis{T,typeof(inds)}(inds)
    else
        indexΔ = One() - static_first(axis)
        return _unsafe_reconstruct_struct_axis(axis, inds, static_first(inds) + indexΔ, static_last(inds) + indexΔ)
    end
end
@inline function _unsafe_reconstruct_struct_axis(axis::StructAxis{T}, inds, start, stop) where {T}
    return initialize_axis([fieldname(T, i) for i in start:stop], compose_axis(inds))
end

@inline function _unsafe_reconstruct_struct_axis(axis::StructAxis{T}, inds, start::StaticInt, stop::StaticInt) where {T}
    return StructAxis{NamedTuple{__names(T, start, stop), __types(T, start, stop)}}(inds)
end

@generated function __names(::Type{T}, ::StaticInt{F}, ::StaticInt{L}) where {T,F,L}
    e = Expr(:tuple)
    for i in F:L
        push!(e.args, QuoteNode(fieldname(T, i)))
    end
    return e
end

@generated function __types(::Type{T}, ::StaticInt{F}, ::StaticInt{L}) where {T,F,L}
    return Tuple{[fieldtype(T, i) for i in F:L]...}
end

# TODO figure out how to place type inference of each field into indexing
@inline function structdim(A::AxisArray{<:Any,<:Any,<:Any,Axs}) where {Axs}
    d = _structdim(Axs)
    if d === 0
        throw(MethodError(structdim, A))
    else
        return StaticInt(d)
    end
end
Base.@pure function _structdim(::Type{T}) where {T<:Tuple}
    for i in OneTo(length(T.parameters))
        T.parameters[i] <: StructAxis && return i
    end
    return 0
end

to_index_type(axis::StructAxis{T}, arg) where {T} = fieldtype(T, to_index(axis, arg))

"""
    struct_view(A)

Creates a `MappedArray` whose element type is derived from the first `StructAxis` found as
an axis of `A`.
"""
@inline function struct_view(A)
    dim = structdim(A)
    axis = axes(A, dim)
    axs = _not_axes(axes(A), dim)
    data = _tuple_of_views(parent(A), static_first(axis), static_last(axis), dim)
    return _struct_view(_struct_view_type(axis), data, axs)
end

_struct_view_type(::StructAxis{T}) where {T} = T
_struct_view_function(::Type{T}) where {T<:NamedTuple} = (args...) -> T(args)
_struct_view_function(::Type{T}) where {T} = T

@generated function _tuple_of_views(A::AbstractArray{<:Any,N}, ::StaticInt{F}, ::StaticInt{L}, dim::StaticInt{D}) where {N,F,L,D}
    e = Expr(:tuple)

    slice_before = [:(:) for i in 1:(D - 1)]
    slice_after = [:(:) for i in 1:(N - D)]

    for i in F:L
        view_i = :(view(A))
        append!(view_i.args, slice_before)
        push!(view_i.args, i)
        append!(view_i.args, slice_after)
        push!(e.args, view_i)
    end
    return Expr(:block, Expr(:meta, :inline), e)
end
@generated function _not_axes(axs::Tuple{Vararg{<:Any,N}}, ::StaticInt{I}) where {N,I}
    e = Expr(:tuple)
    for i in OneTo(N)
        if i !== I
            push!(e.args, :(getfield(axs, $i)))
        end
    end
    return Expr(:block, Expr(:meta, :inline), e)
end
function _struct_view(::Type{T}, data, axs) where {T}
    f = _struct_view_function(T)
    aview = __struct_view(T, f, data)
    return unsafe_initialize(AxisArray{T,length(axs),typeof(aview),typeof(axs)}, (aview, axs))
end
@inline function __struct_view(::Type{T}, f, data) where {T}
    return ReadonlyMultiMappedArray{T,ndims(first(data)),typeof(data),typeof(f)}(f, data)
end
@inline function __struct_view(::Type{T}, ::Type{T}, data) where {T}
    return ReadonlyMultiMappedArray{T,ndims(first(data)),typeof(data),Type{T}}(T, data)
end

function print_axis(io, axis::StructAxis{T}) where {T}
    print(io, "StructAxis($(T) => $(parent(axis)))")
end

