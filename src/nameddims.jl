using NamedDims

export
    NamedIndicesArray,
    NIArray,
    dim,
    dimnames

###
### NamedDims
###

function StaticRanges.axes_type(::Type{<:NamedDimsArray{L,T,N,A}}) where {L,T,N,A}
    return StaticRanges.axes_type(A)
end

StaticRanges.parent_type(::Type{<:NamedDimsArray{L,T,N,A}}) where {L,T,N,A} = A

"""
    NamedIndicesArray

Type alias for `NamedDimsArray` whose parent array is a subtype of `AbstractAxisIndices`.
"""
const NamedIndicesArray{L,T,N,P,AI} = NamedDimsArray{L,T,N,AxisIndicesArray{T,N,P,AI}}

"""
    NIArray((parent::AbstractArray, axes::NamedTuple{L,AbstractAxes}))

An abbreviated alias and constructor for [`NamedIndicesArray`](@ref).

## Examples
```jldoctest
julia> using AxisIndices

julia> A = NIArray(reshape(1:24, 2, 3, 4), x=["a", "b"], y =["one", "two", "three"], z=2:5)
3-dimensional NamedIndicesArray{Int64,3,Base.ReshapedArray{Int64,3,UnitRange{Int64},Tuple{}}...}
[x, y, z[2]] =
      one   two   three
  a   1.0   3.0     5.0
  b   2.0   4.0     6.0


[x, y, z[3]] =
      one    two   three
  a   7.0    9.0    11.0
  b   8.0   10.0    12.0


[x, y, z[4]] =
       one    two   three
  a   13.0   15.0    17.0
  b   14.0   16.0    18.0


[x, y, z[5]] =
       one    two   three
  a   19.0   21.0    23.0
  b   20.0   22.0    24.0


julia> dimnames(A)
(:x, :y, :z)

julia> axes_keys(A)
(["a", "b"], ["one", "two", "three"], UnitMRange(2:5))

julia> B = A["a", :, :]
2-dimensional NamedIndicesArray{Int64,2,Array{Int64,2}...}
[y, z] =
            2      3      4      5
    one   1.0    7.0   13.0   19.0
    two   3.0    9.0   15.0   21.0
  three   5.0   11.0   17.0   23.0


julia> C = B["one",:]
1-dimensional NamedIndicesArray{Int64,1,Array{Int64,1}...}
[z] =

  2    1.0
  3    7.0
  4   13.0
  5   19.0


```
"""
const NIArray{L,T,N,P,AI} = NamedIndicesArray{L,T,N,P,AI}

NIArray(x::AbstractArray; kwargs...) = NIArray(x, kwargs.data)
function NIArray(x::AbstractArray, axs::NamedTuple{L}) where {L}
    return NamedDimsArray{L}(AxisIndicesArray(x, values(axs)))
end

for f in (:getindex, :view, :dotview)
    _f = Symbol(:_, f)
    @eval begin
        @propagate_inbounds function Base.$f(a::NIArray, inds...)
            return $_f(a, to_indices(parent(a), axes(a), inds))
        end

        @propagate_inbounds function Base.$f(a::NIArray, inds::Vararg{<:Integer})
            return Base.$f(parent(a), inds...)
        end

        @propagate_inbounds function Base.$f(a::NIArray, inds::CartesianIndex)
            return Base.$f(parent(a), inds)
        end

        @propagate_inbounds function $_f(a::NIArray, inds::Tuple{Vararg{<:Integer}})
            return Base.$f(parent(a), inds...)
        end

        @propagate_inbounds function $_f(a::NIArray{T,N}, inds::Tuple{Vararg{<:Any,M}}) where {T,N,M}
            data = Base.$f(parent(a), inds...)
            L = NamedDims.remaining_dimnames_from_indexing(dimnames(a), inds)
            return NamedDims.NamedDimsArray{L}(data)
        end

        @propagate_inbounds function $_f(a::NIArray{T,N}, inds::Tuple{Vararg{<:Any,N}}) where {T,N}
            data = Base.$f(parent(a), inds...)
            L = NamedDims.remaining_dimnames_from_indexing(dimnames(a), inds)
            return NamedDims.NamedDimsArray{L}(data)
        end
    end
end

function Base.show(io::IO,
    m::MIME"text/plain",
    A::NIArray{L,T,N},
    pre_rowname="",
    post_rowname="",
    row_colname="",
    vec_colname="",
    tf=array_format(:text),
    formatter=ft_round(3),
    kwargs...
) where {L,T,N}

    println(io, "$N-dimensional NamedIndicesArray{$T,$N,$(parent_type(parent_type(A)))...}")
    return pretty_array(
        io,
        parent(parent(A)),
        axes_keys(A);
        dnames=L,
        vec_colname=vec_colname,
        row_colname=row_colname,
        post_rowname=post_rowname,
        pre_rowname=pre_rowname,
        tf=tf,
        formatter=formatter,
        kwargs...
    )
end

function Base.show(io::IO,
    m::MIME"text/plain",
    A::NIArray{L,T,2},
    pre_rowname="",
    post_rowname="",
    row_colname="",
    vec_colname="",
    tf=array_format(:text),
    formatter=ft_round(3),
    kwargs...
) where {L,T}

    println(io, "2-dimensional NamedIndicesArray{$T,2,$(parent_type(parent_type(A)))...}")
    println(io, "[$(L[1]), $(L[2])] = ")
    return pretty_array(
        io,
        parent(parent(A)),
        axes_keys(A);
        dnames=L,
        vec_colname=vec_colname,
        row_colname=row_colname,
        post_rowname=post_rowname,
        pre_rowname=pre_rowname,
        tf=tf,
        formatter=formatter,
        kwargs...
    )
end

function Base.show(io::IO,
    m::MIME"text/plain",
    A::NIArray{L,T,1},
    pre_rowname="",
    post_rowname="",
    row_colname="",
    vec_colname="",
    tf=array_format(:text),
    formatter=ft_round(3),
    kwargs...
) where {L,T}

    println(io, "1-dimensional NamedIndicesArray{$T,1,$(parent_type(parent_type(A)))...}")
    println(io, "[$(L[1])] = ")
    return pretty_array(
        io,
        parent(parent(A)),
        axes_keys(A);
        dnames=L,
        vec_colname=vec_colname,
        row_colname=row_colname,
        post_rowname=post_rowname,
        pre_rowname=pre_rowname,
        tf=tf,
        formatter=formatter,
        kwargs...
    )
end

