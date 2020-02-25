# Quick Start

Most users will be able to achieve what they want by just specifying a tuple of
keys for the indices of each dimension.
```jldoctest quick_start_example
julia> using AxisIndices

julia> A = AxisIndicesArray(reshape(1:9, 3,3),
               (2:4,        # first dimension has keys 2:4
                3.0:5.0));  # second dimension has keys 3.0:5.0
```

Most code should work just the same for an `AxisIndicesArray`...
```jldoctest quick_start_example
julia> A[1, 1]
1

julia> A[1:2, 1:2] == parent(A)[1:2, 1:2]
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

Note that the first call only returns a single element, where the last call returns an array.
This is because all keys must be unique so there can only be one value that returns `true` if filtering by `==`, which is the same as indexing by `1` (e.g., only one index can equal `1`).
The last call uses operators that can produce any number of `true` values and the resulting output is an array.
This is the same as indexing an array by any vector (i.e., returns another array).


