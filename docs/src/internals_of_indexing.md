# Internals of Indexing

Indexing has 3 steps.
1. Mapping to indices
2. Retrieving elements
3. Reconstructing axes

## Mapping to Indices

AxisIndices attempts to redirect the traditional `to_indices` method from the following...


```julia
function to_indices(A, axes::Tuple, args::Tuple)
    return (to_index(A, first(args)), to_indices(A, tail(axes), tail(args))...)
end
```

to...

```julia
function to_indices(A, axes::Tuple, args::Tuple)
    return (to_index(first(axes), first(args)), to_indices(A, tail(axes), tail(args))...)
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

The resulting keys produced are combined with the relevant indices of the new array to reconstruct the axis.

[^1]: There's absolutely no functionality provided from `Base.to_index` that isn't already available with `AxisIndices.to_index`. Therefore, even though it isn't absolutely necessary it provides a clean break from what happens in `Base`.
[^2]: Why do we need the `index` produced in the previous `to_index` method? Technically we don't, but it allows use to avoid looking up indices a second time and ensuring they are inbounds.
