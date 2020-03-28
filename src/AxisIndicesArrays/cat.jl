
for (tf, T, sf, S) in ((parent, :AbstractAxisIndicesVecOrMat, parent, :AbstractAxisIndicesVecOrMat),
                       (parent, :AbstractAxisIndicesVecOrMat, identity, :AbstractVecOrMat),
                       (identity, :AbstractVecOrMat,          parent,  :AbstractAxisIndicesVecOrMat))
    @eval function Base.vcat(A::$T, B::$S, Cs::AbstractVecOrMat...)
        return vcat(AxisIndicesArray(vcat($tf(A), $sf(B)), vcat_axes(A, B)), Cs...)
    end

    @eval function Base.hcat(A::$T, B::$S, Cs::AbstractVecOrMat...)
        return hcat(AxisIndicesArray(hcat($tf(A), $sf(B)), hcat_axes(A, B)), Cs...)
    end

    @eval function Base.cat(A::$T, B::$S, Cs::AbstractVecOrMat...; dims)
        N = ndims(A)
        axs = ntuple(N) do i
            if i in dims
                cat_axis(axes(A, i), axes(B, i))
            else
                broadcast_axis(axes(A, i), axes(B, i))
            end
        end
        p = cat($tf(A), $sf(B); dims=dims)
        #=
        Ndiff = ndims(p) - N
        if Ndiff != 0
            axs = (axs..., ntuple(_ -> SimpleAxis(OneTo(1)), Ndiff-1)..., SimpleAxis(OneTo(2)))
        end
        =#
        #return cat(AxisIndicesArray(p, axs), Cs..., dims=dims)
        return cat(AxisIndicesArray(p, axs), Cs..., dims=dims)
    end
end

function Base.hcat(A::AbstractAxisIndices{T,N}) where {T,N}
    if N === 1
        return unsafe_reconstruct(hcat(parent(A)), (axes(A, 1), SimpleAxis(OneTo(1))))
    else
        return A
    end
end

Base.vcat(A::AbstractAxisIndices{T,N}) where {T,N} = A
Base.cat(A::AbstractAxisIndices{T,N}; dims) where {T,N} = A

