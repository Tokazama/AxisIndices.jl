# Axis Traits

!!! warning "CORRECT THIS SECTION"
    This section is wrong and needs to be completely rewritten.

# Indexing Traits

At its core, AxisIndices relies on a small change in processing indexing, permitting its unique abilities.
Most arrays pass indexing arguments to the `to_indices` method at some point.
Where a user provides performs indexing as `A[arg1, arg2]`, the translation to native indexing space looks a bit like this:

```julia
# `axes_of_A = axes(A)` and `indexing_arguments = (arg1, arg2)`
function to_indices(A, axes_of_A::Tuple, indexing_arguments::Tuple)
    return (to_index(A, first(indexing_arguments)), to_indices(A, tail(axes_of_A), tail(indexing_arguments))...)
end
```
This means that cusotmizing indexing behavior can be accomplished by either
1. Circumeventing `to_index` by overloading `to_indices`
2. Overloading `to_index` based on `A`
3. Overloading `to_index` based on each indexing argument (e.g., `arg1`, `arg2`)

This package changes this to:
```julia
# `axes_of_A = axes(A)` and `indexing_arguments = (arg1, arg2)`
function to_indices(A, axes_of_A::Tuple, indexing_arguments::Tuple)
    return (to_index(first(axes_of_A), first(indexing_arguments)), to_indices(A, tail(axes_of_A), tail(indexing_arguments))...)
end
```
Now each translation to native indexing space occurs through the direction of each axis of `A`.
This means that customizing indexing behavior can _now_ be accomplished by either
1. Overloading `to_indices` based on `A`.
2. Overloading `to_index` based on each axis of `A` (e.g., `axes(A, 1), axes(A, 2)`)
3. Overloading `to_index` based on each indexing argument (e.g., `arg1`, `arg2`)

However, this does not mean that overloading `to_index` is always safe or even advisable.
This portion of the indexing pipeline is responsible for mapping arguments to the underlying memory of arrays, so you can cause some significant problems if you don't know what you're doing.
It's also easy to inadvertently effect performance when changing how indexing works.
Therefore, AxisIndices also small trait system for handling this.
This is accomplished through the use of `ToIndexStyle`, which is injected into the `to_index` schema as follows:
```julia
function to_index(axis, arg)
    return to_index(ToIndexStyle(), axis, arg)
end
```

Several subtypes of `ToIndexStyle` are provided, allowing users to customize indexing behavior without worrying about rewriting performance critical code.

