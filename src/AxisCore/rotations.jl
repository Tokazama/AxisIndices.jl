
"""
    rot180(A::AbstractAxisIndices)

Rotate `A` 180 degrees, along with its axes keys.

## Examples
```jldoctest
julia> using AxisIndices

julia> a = AxisIndicesArray([1 2; 3 4], ["a", "b"], ["one", "two"]);

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
Base.rot180(x::AbstractAxisIndices) = unsafe_rot180(x, rot180(parent(x)))
function unsafe_rot180(x::AbstractAxisIndices, p::AbstractArray)
    return unsafe_reconstruct(
        x,
        p,
        (reverse_keys(axes(x, 1), axes(p, 1)),
         reverse_keys(axes(x, 2), axes(p, 2)))
    )
end


"""
    rotr90(A::AbstractAxisIndices)

Rotate `A` right 90 degrees, along with its axes keys.

## Examples
```jldoctest
julia> using AxisIndices

julia> a = AxisIndicesArray([1 2; 3 4], ["a", "b"], ["one", "two"]);

julia> b = rotr90(a);

julia> axes_keys(b)
(["one", "two"], ["b", "a"])

julia> a["a", "one"] == b["one", "a"]
true
```
"""
Base.rotr90(x::AbstractAxisIndices) = unsafe_rotr90(x, rotr90(parent(x)))
function unsafe_rotr90(x::AbstractAxisIndices, p::AbstractArray)
    unsafe_reconstruct(
        x,
        p,
        (assign_indices(axes(x, 2), axes(p, 1)),
         reverse_keys(axes(x, 1), axes(p, 2)))
    )
end

"""
    rotl90(A::AbstractAxisIndices)

Rotate `A` left 90 degrees, along with its axes keys.

## Examples
```jldoctest
julia> using AxisIndices

julia> a = AxisIndicesArray([1 2; 3 4], ["a", "b"], ["one", "two"]);

julia> b = rotl90(a);

julia> axes_keys(b)
(["two", "one"], ["a", "b"])

julia> a["a", "one"] == b["one", "a"]
true

```
"""
Base.rotl90(x::AbstractAxisIndices) = unsafe_rotl90(x, rotl90(parent(x)))
function unsafe_rotl90(x::AbstractAxisIndices, p::AbstractArray)
    unsafe_reconstruct(
        x,
        p,
        (reverse_keys(axes(x, 2), axes(p, 1)), assign_indices(axes(x, 1), axes(p, 2)))
    )
end

