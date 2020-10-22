
function fft_axis(fxn::Function, axis::AbstractAxis, inds::AbstractUnitRange)
    return assign_indices(axis, inds)  # default
end

@inline function fft_axes(fxn::Function, axs::Tuple, inds::Tuple, dims::Tuple, cnt::Int=1)
    if first(dims) === cnt
        return (fft_axis(fxn, first(axs), first(inds)),
                fft_axes(fxn, tail(axs), tail(inds), tail(dims), cnt + 1)...)
    else
        return (assign_indices(first(axs), first(inds)),
                fft_axes(fxn, tail(axs), tail(inds), dims, cnt + 1)...)
    end
end
fft_axes(fxn::Function, axs::Tuple, inds::Tuple, dims::Tuple{}, cnt::Int=1) = map(assign_indices, axs, inds)
fft_axes(fxn::Function, axs::Tuple{}, inds::Tuple{}, dims::Tuple{}, cnt::Int=1) = ()

_try_tuple(dim::Integer) = (dim,)
_try_tuple(dim::Tuple) = dim

for f in (:fft, :ifft, :bfft)
    @eval begin
        function AbstractFFTs.$f(A::AxisArray, dims)
            p = AbstractFFTs.$f(parent(A), dims)
            axs = fft_axes(AbstractFFTs.$f, axes(A), axes(p), _try_tuple(dims))
            return unsafe_reconstruct(A, p; axes=axs)
        end
    end
end

