
rotl90_axes(x::AbstractArray) = rotl90_axes(axes(x))
rotl90_axes(x::Tuple) = (reverse_keys(getfield(x, 2)), getfield(x, 1))

rotr90_axes(x::AbstractArray) = rotr90_axes(axes(x))
rotr90_axes(x::Tuple) = (getfield(x, 2), reverse_keys(getfield(x, 1)))

rot180_axes(x::AbstractArray) = rot180_axes(axes(x))
rot180_axes(x::Tuple) = (reverse_keys(getfield(x, 1)), reverse_keys(getfield(x, 2)))

