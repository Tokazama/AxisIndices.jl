
const AxisMatrix{T,P<:AbstractMatrix{T},Ax1,Ax2} = AxisArray{T,2,P,Tuple{Ax1,Ax2}}

"""
    rot180(A::AbstractAxisMatrix)

Rotate `A` 180 degrees, along with its axes keys.

## Examples
```jldoctest
julia> using AxisIndices

julia> a = AxisArray([1 2; 3 4], ["a", "b"], ["one", "two"]);

julia> b = rot180(a);

julia> axes_keys(b)
(["b", "a"], ["two", "one"])

julia> c = rotr90(rotr90(a));

julia> axes_keys(c)
(["b", "a"], ["two", "one"])

julia> a["a", "one"] == b["a", "one"] == c["a", "one"]
true
```
"""
function Base.rot180(x::AbstractAxisMatrix)
    p = rot180(parent(x))
    axs = (reverse_keys(axes(x, 1), axes(p, 1)), reverse_keys(axes(x, 2), axes(p, 2)))
    return unsafe_reconstruct(x, p, axs)
end

"""
    rotr90(A::AbstractAxisMatrix)

Rotate `A` right 90 degrees, along with its axes keys.

## Examples
```jldoctest
julia> using AxisIndices

julia> a = AxisArray([1 2; 3 4], ["a", "b"], ["one", "two"]);

julia> b = rotr90(a);

julia> axes_keys(b)
(["one", "two"], ["b", "a"])

julia> a["a", "one"] == b["one", "a"]
true
```
"""
function Base.rotr90(x::AbstractAxisMatrix)
    p = rotr90(parent(x))
    axs = (assign_indices(axes(x, 2), axes(p, 1)), reverse_keys(axes(x, 1), axes(p, 2)))
    return unsafe_reconstruct(x, p, axs)
end

"""
    rotl90(A::AbstractAxisMatrix)

Rotate `A` left 90 degrees, along with its axes keys.

## Examples
```jldoctest
julia> using AxisIndices

julia> a = AxisArray([1 2; 3 4], ["a", "b"], ["one", "two"]);

julia> b = rotl90(a);

julia> axes_keys(b)
(["two", "one"], ["a", "b"])

julia> a["a", "one"] == b["one", "a"]
true

```
"""
function Base.rotl90(x::AbstractAxisMatrix)
    p = rotl90(parent(x))
    axs = (reverse_keys(axes(x, 2), axes(p, 1)), assign_indices(axes(x, 1), axes(p, 2)))
    return unsafe_reconstruct(x, p, axs)
end



# Using `CovVector` results in Method ambiguities; have to define more specific methods.
#for A in (Adjoint{<:Any, <:AbstractVector}, Transpose{<:Real, <:AbstractVector{<:Real}})
#    @eval function Base.:*(a::$A, b::AbstractAxisArray{T,1,<:AbstractVector{T}}) where {T}
#        return *(a, parent(b))
#    end
#end
#
#function Base.:*(A::AbstractMatrix, adjB::Adjoint{<:Any,<:AbstractTriangular})
#end



function covcor_axes(old_axes::NTuple{2,Any}, new_indices::NTuple{2,Any}, dim::Int)
    if dim === 1
        return (
            assign_indices(last(old_axes), first(new_indices)),
            StaticRanges.resize_last(last(old_axes), last(new_indices))
        )
    elseif dim === 2
        return (
            StaticRanges.resize_last(first(old_axes), first(new_indices)),
            assign_indices(first(old_axes), last(new_indices))
        )
    else
        return (
            StaticRanges.resize_last(first(old_axes), first(new_indices)),
            StaticRanges.resize_last(last(old_axes), last(new_indices))
        )
    end
   
end

for fun in (:cor, :cov)

    fun_doc = """
        $fun(x::AbstractAxisMatrix; dims=1, kwargs...)

    Performs `$fun` on the parent matrix of `x` and reconstructs a similar type
    with the appropriate axes.

    ## Examples
    ```jldoctest
    julia> using AxisIndices, Statistics

    julia> A = AxisArray([1 2 3; 4 5 6; 7 8 9], ["a", "b", "c"], [:one, :two, :three]);

    julia> axes_keys($fun(A, dims = 2))
    (["a", "b", "c"], ["a", "b", "c"])

    julia> axes_keys($fun(A, dims = 1))
    ([:one, :two, :three], [:one, :two, :three])

    ```
    """
    @eval begin
        @doc $fun_doc
        function Statistics.$fun(x::AbstractAxisArray{T,2}; dims=1, kwargs...) where {T}
            p = Statistics.$fun(parent(x); dims=dims, kwargs...)
            return unsafe_reconstruct(x, p, covcor_axes(axes(x), axes(p), dims))
        end
    end
end

# TODO get rid of indicesarray_result
for f in (:mean, :std, :var, :median)
    @eval function Statistics.$f(a::AbstractAxisArray; dims=:, kwargs...)
        return reconstruct_reduction(a, Statistics.$f(parent(a); dims=dims, kwargs...), dims)
    end
end

###
### 🐇/*
###
#
#    matmul_axes(a, b, p) -> Tuple
#
# The arrays from `a * b = p`, where `p` will be the new parent array of an AbstractAxisArray.

matmul_axes(a::Tuple, b::Tuple, p::Tuple) = _matmul_axes(a, b, p)
matmul_axes(a::Tuple, b::Tuple, p::Tuple{}) = ()

function _matmul_axes(a::Tuple{Any}, b::Tuple{Any,Any}, p::Tuple{Any,Any})
    return (_matmul_assign_indices(first(a), first(p)), _matmul_assign_indices(last(b), last(p)))
end

function _matmul_axes(a::Tuple{Any,Any}, b::Tuple{Any,Any}, p::Tuple{Any,Any})
    return (_matmul_assign_indices(first(a), first(p)), _matmul_assign_indices(last(b), last(p)))
end

function _matmul_axes(a::Tuple{Any,Any}, b::Tuple{Any}, p::Tuple{Any})
    return (_matmul_assign_indices(first(a), first(p)),)
end

_matmul_assign_indices(axis::AbstractAxis, inds) = assign_indices(axis, inds)
_matmul_assign_indices(axis, inds) = SimpleAxis(inds)

_matmul(A, p, axs::Tuple) = unsafe_reconstruct(A, p, axs)
_matmul(A, p, axs::Tuple{}) = p


for (A,B) in ((AbstractAxisMatrix,AbstractAxisMatrix),
              (AbstractAxisVector,AbstractAxisMatrix),
              (AbstractAxisMatrix,AbstractAxisVector))
    @eval begin
        function Base.:*(a::$A, b::$B)
            p = *(parent(a), parent(b))
            axs = Arrays.matmul_axes(axes(a), axes(b), axes(p))
            return Arrays._matmul(a, p, axs)
        end
    end
end


#     @declare_axisarray_matmul(T)
#
# This is used to quickly resolve ambiguities with `*`.
# It simply defines a method for `*(::T, ::AbstractAxisArray)` and
# `*(::AbstractAxisArray, ::T)`, which unwrap the `AbstractAxisArray` for subsequent
# `*` methods and than rewraps the appropriate axes as an axis array. It isn't
# exported and doesn't have an official docstring b/c it's unlikely to be useful
# outside the internals of this package.
macro declare_axisarray_matmul(T)
    esc(quote
        function Base.:*(a::AbstractAxisMatrix, b::$T)
            p = *(parent(a), b)
            axs = Arrays.matmul_axes(axes(a), axes(b), axes(p))
            return Arrays._matmul(a, p, axs)
        end

        function Base.:*(a::AbstractAxisVector, b::$T)
            p = *(parent(a), b)
            axs = Arrays.matmul_axes(axes(a), axes(b), axes(p))
            return Arrays._matmul(a, p, axs)
        end

        function Base.:*(a::$T, b::AbstractAxisMatrix)
            p = *(a, parent(b))
            axs = Arrays.matmul_axes(axes(a), axes(b), axes(p))
            return Arrays._matmul(b, p, axs)
        end
        function Base.:*(a::$T, b::AbstractAxisVector)
            p = *(a, parent(b))
            axs = Arrays.matmul_axes(axes(a), axes(b), axes(p))
            return Arrays._matmul(b, p, axs)
        end
    end)
end

@declare_axisarray_matmul AbstractVector

@declare_axisarray_matmul AbstractMatrix

@declare_axisarray_matmul Diagonal

@declare_axisarray_matmul StaticMatrix

#@declare_axisarray_matmul StaticVector

const RealHermSymComplexHerm = Union{Hermitian{T,S}, Hermitian{Complex{T},S}, Symmetric{T,S}} where S where T<:Real
function Base.:*(a::Adjoint{<:Any,<:RealHermSymComplexHerm}, b::AbstractAxisVector)
    p = *(a, parent(b))
    return _matmul(b, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end
function Base.:*(a::Adjoint{<:Any,<:RealHermSymComplexHerm}, b::AbstractAxisMatrix)
    p = *(a, parent(b))
    return _matmul(b, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end
function Base.:*(a::AbstractAxisMatrix, b::Adjoint{<:Any,<:RealHermSymComplexHerm})
    p = *(a, parent(b))
    return _matmul(b, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end

function Base.:*(a::Adjoint{<:Any,<:LinearAlgebra.AbstractTriangular}, b::AbstractAxisMatrix)
    p = *(a, parent(b))
    return _matmul(b, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end
function Base.:*(a::Adjoint{<:Any,<:LinearAlgebra.AbstractTriangular}, b::AbstractAxisVector)
    p = *(a, parent(b))
    return _matmul(b, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end
function Base.:*(a::Transpose{<:Any,<:LinearAlgebra.AbstractTriangular}, b::AbstractAxisMatrix)
    p = *(a, parent(b))
    return _matmul(b, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end
function Base.:*(a::Transpose{<:Any,<:LinearAlgebra.AbstractTriangular}, b::AbstractAxisVector)
    p = *(a, parent(b))
    return _matmul(b, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end
function Base.:*(a::AbstractAxisMatrix, b::Transpose{<:Any,<:RealHermSymComplexHerm})
    p = *(a, parent(b))
    return _matmul(b, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end
function Base.:*(a::LinearAlgebra.AbstractTriangular, b::AbstractAxisVector)
    p = *(a, parent(b))
    return _matmul(b, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end

function Base.:*(a::Adjoint{T,<:AbstractArray{T,1}}, b::AbstractAxisVector{T}) where {T<:Number}
    p = *(a, parent(b))
    return _matmul(b, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end
function Base.:*(a::Adjoint{T,<:AbstractArray{T,1}}, b::AbstractAxisVector{T}) where {T}
    p = *(a, parent(b))
    return _matmul(b, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end
function Base.:*(a::Transpose{T,<:AbstractArray{T,1}}, b::AbstractAxisVector{T}) where {T<:Real}
    p = *(a, parent(b))
    return _matmul(b, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end
function Base.:*(a::AbstractAxisMatrix, b::LinearAlgebra.AbstractTriangular, )
    p = *(parent(a), b)
    return _matmul(a, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end

const RealHermSymComplexSym = Union{Hermitian{T,S}, Symmetric{T,S}, Symmetric{Complex{T},S}} where S where T<:Real
function Base.:*(a::AbstractAxisMatrix, b::Transpose{<:Any,<:RealHermSymComplexSym})
    p = *(parent(a), b)
    return _matmul(a, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end

NamedDims.@declare_matmul(AbstractAxisMatrix, AbstractAxisVector)


function Base.:*(a::LinearAlgebra.AbstractRotation, b::AbstractAxisVector)
    p = *(a, parent(b))
    return _matmul(b, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end
function Base.:*(a::LinearAlgebra.AbstractRotation, b::AbstractAxisMatrix)
    p = *(a, parent(b))
    return _matmul(b, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end
function Base.:(*)(a::AbstractAxisVector, b::Adjoint{<:Any,<:LinearAlgebra.AbstractRotation})
    p = *(parent(a), b)
    return _matmul(a, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end
function Base.:(*)(a::AbstractAxisMatrix, b::Adjoint{<:Any,<:LinearAlgebra.AbstractRotation})
    p = *(parent(a), b)
    return _matmul(a, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end
function Base.:*(a::LinearAlgebra.AdjOrTransAbsVec, b::AbstractAxisVector)
    p = *(a, parent(b))
    return _matmul(b, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end
function Base.:*(a::AbstractAxisVector, b::LinearAlgebra.AdjOrTransAbsVec)
    p = *(parent(a), b)
    return _matmul(a, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end
function Base.:*(a::AbstractAxisVector, b::Transpose{<:Any,<:AbstractMatrix})
    p = *(a, parent(b))
    return _matmul(a, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end
function Base.:*(a::AbstractAxisVector, b::Adjoint{<:Any,<:AbstractMatrix})
    p = *(a, parent(b))
    return _matmul(a, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end

function Base.:*(a::Transpose{<:Any,<:AbstractMatrix{T}}, b::AbstractAxisVector{S}) where {T,S}
    p = *(a, parent(b))
    return _matmul(b, p, Arrays.matmul_axes(axes(a), axes(b), axes(p)))
end
#*(u::TransposeAbsVec{T}, v::AbstractVector{T}) where {T<:Real} = dot(u.parent, v)
#*(u::AdjOrTransAbsVec, v::AbstractVector) = sum(uu*vv for (uu, vv) in zip(u, v))

#=
function Base.:(*)(A::AbstractMatrix, B::AbstractMatrix)
    TS = promote_op(matprod, eltype(A), eltype(B))
    mul!(similar(B, TS, (size(A,1), size(B,2))), A, B)
end

function (*)(A::AbstractMatrix, B::AbstractMatrix)
    TS = promote_op(matprod, eltype(A), eltype(B))
    mul!(similar(B, TS, (size(A,1), size(B,2))), A, B)
end
function (*)(R::AbstractRotation{T}, A::AbstractVecOrMat{S}) where {T,S}
    TS = typeof(zero(T)*zero(S) + zero(T)*zero(S))
    lmul!(convert(AbstractRotation{TS}, R), TS == S ? copy(A) : convert(AbstractArray{TS}, A))
end
(*)(A::AbstractVector, adjR::Adjoint{<:Any,<:AbstractRotation}) = _absvecormat_mul_adjrot(A, adjR)
(*)(A::AbstractMatrix, adjR::Adjoint{<:Any,<:AbstractRotation}) = _absvecormat_mul_adjrot(A, adjR)

#function Base.:*(a::Diagonal{T1}, b::AbstractAxisMatrix{T2}) where {T}
    return _matmul(b, promote_type(T1, T2), *(a, parent(b)), matmul_axes(a, b))
end
function Base.:*(a::AbstractAxisArray{T1,2}, b::Diagonal{T2}) where {T1,T2}
    return _matmul(a, promote_type(T1, T2), *(parent(a), b), matmul_axes(a, b))
end
function Base.:*(
    a::Adjoint{T1,<:AbstractVector{T1}},
    b::AbstractAxisArray{T,1,<:AbstractVector{T}}
) where {T1<:Number,T}

    return *(a, parent(b))
end
function Base.:*(
    a::Transpose{T1,<:AbstractVector{T1}},
    b::AbstractAxisArray{T,1,<:AbstractVector{T}}
) where {T1<:Real,T}

    return *(a, parent(b))
end


=#

# vector^T * vector
#function Base.:*(a::AbstractAxisArray{T,2,<:CoVector}, b::AbstractAxisVector) where {T}
#    return *(parent(a), parent(b))
#end
#=
for mat in (:AbstractVector, :AbstractMatrix)
    ### Multiplication with triangle to the left and hence rhs cannot be transposed.
    @eval begin
        function *(A::AbstractTriangular, B::$mat)
            require_one_based_indexing(B)
            TAB = typeof(zero(eltype(A))*zero(eltype(B)) + zero(eltype(A))*zero(eltype(B)))
            BB = similar(B, TAB, size(B))
            copyto!(BB, B)
            lmul!(convert(AbstractArray{TAB}, A), BB)
        end

        function *(transA::Transpose{<:Any,<:AbstractTriangular}, B::$mat)
            require_one_based_indexing(B)
            A = transA.parent
            TAB = typeof(zero(eltype(A))*zero(eltype(B)) + zero(eltype(A))*zero(eltype(B)))
            BB = similar(B, TAB, size(B))
            copyto!(BB, B)
            lmul!(transpose(convert(AbstractArray{TAB}, A)), BB)
        end
    end
    ### Left division with triangle to the left hence rhs cannot be transposed. No quotients.
    @eval begin
        function \(A::Union{UnitUpperTriangular,UnitLowerTriangular}, B::$mat)
            require_one_based_indexing(B)
            TAB = typeof(zero(eltype(A))*zero(eltype(B)) + zero(eltype(A))*zero(eltype(B)))
            BB = similar(B, TAB, size(B))
            copyto!(BB, B)
            ldiv!(convert(AbstractArray{TAB}, A), BB)
        end
        function \(adjA::Adjoint{<:Any,<:Union{UnitUpperTriangular,UnitLowerTriangular}}, B::$mat)
            require_one_based_indexing(B)
            A = adjA.parent
            TAB = typeof(zero(eltype(A))*zero(eltype(B)) + zero(eltype(A))*zero(eltype(B)))
            BB = similar(B, TAB, size(B))
            copyto!(BB, B)
            ldiv!(adjoint(convert(AbstractArray{TAB}, A)), BB)
        end
        function \(transA::Transpose{<:Any,<:Union{UnitUpperTriangular,UnitLowerTriangular}}, B::$mat)
            require_one_based_indexing(B)
            A = transA.parent
            TAB = typeof(zero(eltype(A))*zero(eltype(B)) + zero(eltype(A))*zero(eltype(B)))
            BB = similar(B, TAB, size(B))
            copyto!(BB, B)
            ldiv!(transpose(convert(AbstractArray{TAB}, A)), BB)
        end
    end
    ### Left division with triangle to the left hence rhs cannot be transposed. Quotients.
    @eval begin
        function \(A::Union{UpperTriangular,LowerTriangular}, B::$mat)
            require_one_based_indexing(B)
            TAB = typeof((zero(eltype(A))*zero(eltype(B)) + zero(eltype(A))*zero(eltype(B)))/one(eltype(A)))
            BB = similar(B, TAB, size(B))
            copyto!(BB, B)
            ldiv!(convert(AbstractArray{TAB}, A), BB)
        end
        function \(adjA::Adjoint{<:Any,<:Union{UpperTriangular,LowerTriangular}}, B::$mat)
            require_one_based_indexing(B)
            A = adjA.parent
            TAB = typeof((zero(eltype(A))*zero(eltype(B)) + zero(eltype(A))*zero(eltype(B)))/one(eltype(A)))
            BB = similar(B, TAB, size(B))
            copyto!(BB, B)
            ldiv!(adjoint(convert(AbstractArray{TAB}, A)), BB)
        end
        function \(transA::Transpose{<:Any,<:Union{UpperTriangular,LowerTriangular}}, B::$mat)
            require_one_based_indexing(B)
            A = transA.parent
            TAB = typeof((zero(eltype(A))*zero(eltype(B)) + zero(eltype(A))*zero(eltype(B)))/one(eltype(A)))
            BB = similar(B, TAB, size(B))
            copyto!(BB, B)
            ldiv!(transpose(convert(AbstractArray{TAB}, A)), BB)
        end
    end
    ### Right division with triangle to the right hence lhs cannot be transposed. No quotients.
    @eval begin
        function /(A::$mat, B::Union{UnitUpperTriangular, UnitLowerTriangular})
            require_one_based_indexing(A)
            TAB = typeof(zero(eltype(A))*zero(eltype(B)) + zero(eltype(A))*zero(eltype(B)))
            AA = similar(A, TAB, size(A))
            copyto!(AA, A)
            rdiv!(AA, convert(AbstractArray{TAB}, B))
        end
        function /(A::$mat, adjB::Adjoint{<:Any,<:Union{UnitUpperTriangular, UnitLowerTriangular}})
            require_one_based_indexing(A)
            B = adjB.parent
            TAB = typeof(zero(eltype(A))*zero(eltype(B)) + zero(eltype(A))*zero(eltype(B)))
            AA = similar(A, TAB, size(A))
            copyto!(AA, A)
            rdiv!(AA, adjoint(convert(AbstractArray{TAB}, B)))
        end
        function /(A::$mat, transB::Transpose{<:Any,<:Union{UnitUpperTriangular, UnitLowerTriangular}})
            require_one_based_indexing(A)
            B = transB.parent
            TAB = typeof(zero(eltype(A))*zero(eltype(B)) + zero(eltype(A))*zero(eltype(B)))
            AA = similar(A, TAB, size(A))
            copyto!(AA, A)
            rdiv!(AA, transpose(convert(AbstractArray{TAB}, B)))
        end
    end
    ### Right division with triangle to the right hence lhs cannot be transposed. Quotients.
    @eval begin
        function /(A::$mat, B::Union{UpperTriangular,LowerTriangular})
            require_one_based_indexing(A)
            TAB = typeof((zero(eltype(A))*zero(eltype(B)) + zero(eltype(A))*zero(eltype(B)))/one(eltype(A)))
            AA = similar(A, TAB, size(A))
            copyto!(AA, A)
            rdiv!(AA, convert(AbstractArray{TAB}, B))
        end
        function /(A::$mat, adjB::Adjoint{<:Any,<:Union{UpperTriangular,LowerTriangular}})
            require_one_based_indexing(A)
            B = adjB.parent
            TAB = typeof((zero(eltype(A))*zero(eltype(B)) + zero(eltype(A))*zero(eltype(B)))/one(eltype(A)))
            AA = similar(A, TAB, size(A))
            copyto!(AA, A)
            rdiv!(AA, adjoint(convert(AbstractArray{TAB}, B)))
        end
        function /(A::$mat, transB::Transpose{<:Any,<:Union{UpperTriangular,LowerTriangular}})
            require_one_based_indexing(A)
            B = transB.parent
            TAB = typeof((zero(eltype(A))*zero(eltype(B)) + zero(eltype(A))*zero(eltype(B)))/one(eltype(A)))
            AA = similar(A, TAB, size(A))
            copyto!(AA, A)
            rdiv!(AA, transpose(convert(AbstractArray{TAB}, B)))
        end
    end
end

=#
