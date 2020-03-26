# Indexing

## Indexing an Axis
Here's the basic setup to go through these examples
```jldoctest indexing_examples
julia> using AxisIndices, Unitful, IntervalSets

julia> using Unitful: s

julia> time1 = Axis((1.5:.5:10)s)
Axis((1.5:0.5:10.0) s => Base.OneTo(18))

julia> time2 = Axis((1.5:.5:10)s, 2:19)
Axis((1.5:0.5:10.0) s => 2:19)
```

### Indexing With Integers

Integers will map directly to the indices of an axis.
```jldoctest indexing_examples
julia> time1[1]
1

julia> time1[2]
2

julia> time2[2]
2

julia> time2[begin]
2
```
Notice that `time2[begin]` returns `2`.
This is because the indices of the `time2` axis don't contain a 1 and begins at 2.
This allows an axis to map to any single dimensional memory mapping, even if it doesn't start at 1.

Indexing an axis with a collection of integers works similarly to indexing any other `AbstractUnitRange`.
That is, using other subtypes of `AbstractUnitRange` preserves the structure...
```jldoctest indexing_examples
julia> time1[1:2]
Axis((1.5:0.5:2.0) s => 1:2)

julia> time2[2:3]
Axis((1.5:0.5:2.0) s => 2:3)
```

However, we can't ensure that the resulting range will have a step of one in other cases so only the indices are returned.
```jldoctest indexing_examples
julia> time1[1:2:4]
1:2:3

julia> time1[[1, 2, 3]]
3-element Array{Int64,1}:
 1
 2
 3

julia> time1[begin:end]
Axis((1.5:0.5:10.0) s => 1:18)

```

### Indexing With Keys

```jldoctest indexing_examples
julia> time1[1.5s]
1

julia> time2[1.5s]
2
```

```jldoctest indexing_examples
julia> time1[1.5s..3s]
Axis((1.5:0.5:3.0) s => 1:4)

julia> time1[3s..4.5s]
Axis((3.0:0.5:4.5) s => 4:7)
```

### Indexing With Functions

Operators that typically return `true` or `false` can often 
```jldoctest indexing_examples
julia> time1[<(3.0s)]
Axis((1.5:0.5:2.5) s => 1:3)

julia> time1[>(3.0s)]
Axis((3.5:0.5:10.0) s => 5:18)

julia> time1[==(6.0s)]
10

julia> time1[!=(6.0s)]
17-element Array{Int64,1}:
  1
  2
  3
  4
  5
  6
  7
  8
  9
 11
 12
 13
 14
 15
 16
 17
 18

```

These operators can also be combined to get more specific regions of an axis.
```jldoctest indexing_examples
julia> time1[and(>(2.5s), <(10.0s))]
Axis((3.0:0.5:9.5) s => 4:17)

julia> time1[>(2.5s) ⩓ <(10.0s)]  # equivalent to `and` you can use \And<TAB>
Axis((3.0:0.5:9.5) s => 4:17)

julia> time1[or(<(2.5s),  >(9.0s))]
4-element Array{Int64,1}:
  1
  2
 17
 18

julia> time1[<(2.5s) ⩔ >(9.0s)]  # equivalent to `or` you can use \Or<TAB>
4-element Array{Int64,1}:
  1
  2
 17
 18

```

## Indexing an Array

```jldoctest indexing_examples
julia> A = AxisIndicesArray(reshape(1:9, 3,3),
               ((.1:.1:.3)s,        # first dimension has keys (0.1:0.1:0.3) s
                 ["a", "b", "c"]));         # second dimension has keys ["a", "b", "c"]
```

### Indexing With Integers

```jldoctest indexing_examples
julia> A[1,1]
1

julia> A[1]
1
```

```jldoctest indexing_examples
julia> A[1,:]
1-dimensional AxisIndicesArray{Int64,1,Array{Int64,1}...}

  a   1.0
  b   4.0
  c   7.0

julia> A[1:2,1:2]
2-dimensional AxisIndicesArray{Int64,2,Array{Int64,2}...}
            a     b
  0.1 s   1.0   4.0
  0.2 s   2.0   5.0


julia> A[1:3]
3-element Array{Int64,1}:
 1
 2
 3

```

### Indexing With Keys

```jldoctest indexing_examples
julia> A[.1s, "a"]
1

julia> A[0.1s..0.3s, ["a", "b"]]
2-dimensional AxisIndicesArray{Int64,2,Array{Int64,2}...}
            a     b
  0.1 s   1.0   4.0
  0.2 s   2.0   5.0
  0.3 s   3.0   6.0

```

### Indexing With Functions

```jldoctest indexing_examples
julia> A[!=(.2s), in(["a", "c"])]
2-dimensional AxisIndicesArray{Int64,2,Array{Int64,2}...}
            a     c
  0.1 s   1.0   7.0
  0.3 s   3.0   9.0


```

## When Indexing Doesn't Start at One

By default `Axis` will have indices that start at one.
However, if the first index along a dimension of something doesn't start at one this could force an index call to search outside of memory.

```
julia> OffsetArrays
```
