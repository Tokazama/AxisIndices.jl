# Quick Start

Custom indexing only requires specifying a tuple of keys[^1] for the indices of each dimension.
```jldoctest quick_start_example
julia> using AxisIndices

julia> A = AxisArray(reshape(1:9, 3,3),
               (2:4,        # first dimension has keys 2:4
                3.0:5.0));  # second dimension has keys 3.0:5.0
```

Most code should work just the same for an `AxisArray`...
```jldoctest quick_start_example
julia> A[2, 1]
1

julia> A[2:4, 1:2] == parent(A)[1:3, 1:2]
true

julia> sum(A) == sum(parent(A))
true
```

But now the indices of each dimension have keys that we can filter through.
```jldoctest quick_start_example
julia> A[==(2), ==(3.0)] == parent(A)[findfirst(==(2), 2:4), findfirst(==(3.0), 3.0:5.0)] == 1
true

julia> A[<(4), <(5.0)] == parent(A)[findall(<(4), 2:4), findall(<(5.0), 3.0:5.0)] == [1 4; 2 5]
true
```

Any value that is not a `CartesianIndex` or subtype of `Real` is considered a dedicated key type.
In other words, it could never be used for default indexing and will be treated the same as the `==` filtering syntax above.
```jldoctest quick_start_example
julia> AxisArray([1, 2, 3], (["one", "two", "three"],))["one"]
1
```

Note that the first call only returns a single element, where the last call returns an array.
This is because all keys must be unique so there can only be one value that returns `true` if filtering by `==`, which is the same as indexing by `1` (e.g., only one index can equal `1`).
The last call uses operators that can produce any number of `true` values and the resulting output is an array.
This is the same as indexing an array by any vector (i.e., returns another array).

[^1]: Terminology here is important here. Keys, indices, and axes each have a specific meaning. Throughout the documentation the following functional definitions apply:
    * axis: maps a set of keys to a set of indices.
    * indices: a set of integers (e.g., `<:Integer`) that locate the in memory locations of elements.
    * keys: maps a set of any type to a set of indices
    * indexing: anytime one calls `getindex` or uses square brackets to navigate the elements of a collection
    Also note the use of argument (abbreviated `arg` in code) and arguments (abbreviated `args` in code). These terms specifically refer to what users pass to an indexing method. Therefore, an argument may be a key (`:a`), index (`1`), or something else that maps to one of the two (`==(1)`).

