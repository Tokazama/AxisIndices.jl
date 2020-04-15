# Combining Axes

One natural consequence of having axes as independent entities from the actual array data is that it complicates operations such as `cat` and `append!`.
1. How should we propagate characteristics from the values of each axis so that the resulting array is still appropriately memory mapped.
2. How should we combine keys of different types and that are not necessarily unique?

### Appending Axes

Appending axes works similar to concatenating axes except that the first argument is mutated.

Customizing appending axes should be accomplished through either [`AxisIndices.CombineStyle`](@ref) or [`AxisIndices.append_axis!`](@ref).

### Concatenating Axes

Concatenating axes can happen by one of the following:
1. Stacking two collections of completely unique elements
2. Resizing a range of values

The second only happens when the two collections provided are subtypes of `AbstractRange`.

Customizing concatenating axes should be accomplished through either [`AxisIndices.CombineStyle`](@ref) or [`AxisIndices.cat_axis`](@ref).

# Broadcasting Axes

There are three things that determine the output of a broadcasting axes.
1. Standard promotion
2. Key specific promotion (or promotion over `Real`)
3. Order of arguments promotion

Take the following vectors.
```jldoctest broadcast_examples
julia> using AxisIndices

julia> a = ones(3);

julia> b = AxisIndicesArray(a, 2:4);

julia> c = AxisIndicesArray(a, ["1", "2", "3"]);
```

We assume the lack of a formal axis defined in `a` indicates that it's keys are unimportant.
Therefore, we freely choose any keys that are formally defined elsewhere to belong to the new result of a broadcast statement.
This is the kind of behavior one gets from **standard type promotion**.
```jldoctest broadcast_examples
julia> axes_keys(a .+ b)
(UnitMRange(2:4),)

julia> axes_keys(b .+ a)
(UnitMRange(2:4),)

julia> axes_keys(a .+ c)
(["1", "2", "3"],)

julia> axes_keys(c .+ a)
(["1", "2", "3"],)
```

However, when we do the same with `b` and `c` they both have formally defined keys.
```jldoctest broadcast_examples
julia> axes_keys(b .+ c)
(["2", "3", "4"],)

julia> axes_keys(c .+ b)
(["1", "2", "3"],)
```
Notice that all outputs become elements of `String` and a collection that are `Vector`.
We can't depend upon the default promotion in base (e.g., `promote(x, y)`) because some keys won't have `promote_rule` defined for two key types.
It may not be appropriate to define a promotion rule between something like `Int` and `String` in the base Julia library because there is not universally meaningful way to promote it without context.
In this instance we clearly want to apply some sort of label along an axis and that label may or may not be intended to parse as an `Int`, so we always default to broadcasting the key type that is not a subtype of `Real`.

```jldoctest broadcast_examples
julia> d = AxisIndicesArray(a, [:a, :b, :c]);

julia> axes_keys(a .+ d, 1) == [:a, :b, :c]
true
```
The term **key specific promotion** is used because it is only sensible in the context of keys.


Finally, if both key types are non `Real` then **order of arguments** determines promotion.
```jldoctest broadcast_examples
julia> axes_keys(c .+ d)
(["1", "2", "3"],)

julia> axes_keys(d .+ c, 1) == [:a, :b, :c]
true
```

Customizing broadcasting behavior should be accomplished through either [`AxisIndices.CombineStyle`](@ref) or [`AxisIndices.broadcast_axis`](@ref).

