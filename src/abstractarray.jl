
macro def_equals(f, X,Y)
    if X === :AxisArray
        if Y === :AxisArray
            esc(quote
                function Base.$f(x::$X, y::$Y)
                    if is_dense_wrapper(x) && is_dense_wrapper(y)
                        return Base.$f(parent(x), parent(y))
                    else
                        for (x_i,y_i) in zip(x,y)
                            Base.$f(x_i, y_i) || return false
                        end
                        return true
                    end
                end
            end)
        else
            esc(quote
                function Base.$f(x::$X, y::$Y)
                    if is_dense_wrapper(x)
                        return Base.$f(parent(x), y)
                    else
                        for (x_i,y_i) in zip(x,y)
                            Base.$f(x_i, y_i) || return false
                        end
                        return true
                    end
                end
            end)
        end
    else
        esc(quote
            function Base.$f(x::$X, y::$Y)
                if is_dense_wrapper(y)
                    return Base.$f(x, parent(y))
                else
                    for (x_i,y_i) in zip(x,y)
                        Base.$f(x_i, y_i) || return false
                    end
                    return true
                end
            end
        end)
    end
end

@def_equals(==, AxisArray, AxisArray)
@def_equals(==, AbstractArray, AxisArray)
@def_equals(==, AxisArray, AbstractArray)
@def_equals(==, AxisArray, AbstractAxis)
@def_equals(==, AbstractAxis, AxisArray)
@def_equals(==, AxisArray, GapRange)
@def_equals(==, GapRange, AxisArray)

@def_equals(isequal, AxisArray, AxisArray)
@def_equals(isequal, AbstractArray, AxisArray)
@def_equals(isequal, AxisArray, AbstractArray)
@def_equals(isequal, AxisArray, AbstractAxis)
@def_equals(isequal, AbstractAxis, AxisArray)

Base.isapprox(a::AxisArray, b::AxisArray; kw...) = isapprox(parent(a), parent(b); kw...)
Base.isapprox(a::AxisArray, b::AbstractArray; kw...) = isapprox(parent(a), b; kw...)
Base.isapprox(a::AbstractArray, b::AxisArray; kw...) = isapprox(a, parent(b); kw...)

Base.copy(A::AxisArray) = AxisArray(copy(parent(A)), map(copy, axes(A)))

for (tf, T, sf, S) in (
    (parent, :AxisArray, parent, :AxisArray),
    (parent, :AxisArray, identity, :AbstractArray),
    (identity, :AbstractArray, parent, :AxisArray))

    @eval function Base.cat(A::$T, B::$S, Cs::AbstractArray...; dims)
        p = cat($tf(A), $sf(B); dims=dims)
        return cat(AxisArray(p, cat_axes(A, B, p, dims)), Cs..., dims=dims)
    end
end

for (tf, T, sf, S) in (
    (parent, :AxisVecOrMat, parent, :AxisVecOrMat),
    (parent, :AxisArray, identity, :VecOrMat),
    (identity, :VecOrMat, parent, :AxisArray))
    @eval function Base.vcat(A::$T, B::$S, Cs::VecOrMat...)
        p = vcat($tf(A), $sf(B))
        return vcat(initialize_axis_array(p, vcat_axes(A, B, p)), Cs...)
    end

    @eval function Base.hcat(A::$T, B::$S, Cs::VecOrMat...)
        p = hcat($tf(A), $sf(B))
        return hcat(initialize_axis_array(p, hcat_axes(A, B, p)), Cs...)
    end
end

function Base.hcat(A::AxisArray{T,N}) where {T,N}
    if N === 1
        return AxisArray(hcat(parent(A)), (axes(A, 1), axes(A, 2)))
    else
        return A
    end
end

Base.vcat(A::AxisArray{T,N}) where {T,N} = A

Base.cat(A::AxisArray{T,N}; dims) where {T,N} = A

