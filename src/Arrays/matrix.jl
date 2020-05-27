
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

