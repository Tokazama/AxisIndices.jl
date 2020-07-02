# Internals of Indexing

This section is for those who want to understand how indexing is implemented in `AxisIndices` and some of the logic behind it.
It goes over:

* The three steps of indexing.
    1. Mapping to indices
    2. Retrieving elements
    3. Reconstructing axes
* Introduction to `AxisIndicesStyle` traits

Although the basic concepts used here are very unlikely to change, small details (such as internally used naming and types) may change.
Therefore, the exact implementation of these concepts are actively being developed and improved.

## Mapping to Indices

AxisIndices attempts to redirect the uses its own internal implementation of `to_indices`.
Where the the method from base looks somewhate like the following...


```julia
function Base.to_indices(A, axes::Tuple, args::Tuple)
    return (Base.to_index(A, first(args)), Base.to_indices(A, tail(axes), tail(args))...)
end
```

AxisIndices looks more like...

```julia
function AxisIndices.to_indices(A, axes::Tuple, args::Tuple)
    return (AxisIndices.to_index(first(axes), first(args)), AxisIndices.to_indices(A, tail(axes), tail(args))...)
end
```

This allows each axis to influence how an argument maps to indices.
The combination of a given axis and argument produce a trait that directs this mapping.

```julia
AxisIndices.to_index(axis, arg) = to_index(AxisIndicesStyle(axis, arg), axis, arg)
```

Note that this `to_index` method is completely unique from the one implemented in `Base` [^1].

Functionally, this translates to retrieving the elements of an `AbstractIndicesArray` like so:
```julia
A[arg1, arg2] ->
parent(A)[to_indices(A, (arg1, arg2))...] ->
parent(A)[to_indices(A, axes(A), (arg1, arg2))...] ->
parent(A)[indices...] -> sub_A
```

## Reconstructing Axes

Once the new array is composed axes need to be reconstructed through `to_axes`, which essentially is the reverse of `to_indices`.
Instead of passing each argument to `to_index` they're passed to `to_key` [^2].

```julia
AxisIndices.to_key(axis, arg, index) = to_key(AxisIndicesStyle(axis, arg), axis, arg, index)
```

The resulting keys produced are combined with the relevant indices of the new array to reconstruct the axis[^3].

## AxisIndicesStyle

You may have noticed that `AxisIndicesStyle` is in the last part of `to_index` and `to_key` described.
`AxisIndicesStyle` is the supertype for a set of traits that determine what each argument means in the context of an axis.
For example, `AxisIndicesStyle(::AbstractAxis, ::Integer)` returns `IndexElement`, telling `to_index` and `to_key` that the provided argument directly corresponds to an index with an axis.
Contrast this with `KeyElement` which tells `to_index` to find the position of the provided argument within the keys and return the corresponding index.
These traits are fully responsible for dispatch to `to_index` and `to_keys`.
Therefore, new subtypes of `AxisIndicesStyle` must define a `to_index` and `to_keys` method.


[^1]: There's absolutely no functionality provided from `Base.to_index` that isn't already available with `AxisIndices.to_index`. Providing a seperate implementation is meant to avoid causing any unecessary ambiguities in this or any other packages that may be simultaneously loaded.
[^2]: Why do we need the `index` produced in the previous `to_index` method to reconstruct keys? Technically we don't, but it avoids looking up indices a second time and ensuring they are inbounds.
[^3]: It is at this point that `unsafe_reconstruct` is called. This is only important to know if you want to create a new axis type that has keys that require some unique procedure to reconstruct.
