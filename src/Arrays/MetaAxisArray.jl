
const MetAxisArray{T,N,Ax,M,P<:AbstractAxisArray{T,N,Ax}} = MetadataArray{T,N,M,P}

MetAxisArray(A::AbstractArray, axs::Tuple, meta=nothing) = MetadataArray(AxisArray(A, axs), meta)



