# Indexing Tutorial

## Indexing an Axis

Setup for running axis examples.
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

julia> time2[1]
ERROR: BoundsError: attempt to access 18-element Axis((1.5:0.5:10.0) s => 2:19) at index [1]
[...]
```
Notice that `time2[1]` throws an error.
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

julia> time1[firstindex(time1):end]
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

## `Keys` and `Indices`

If our keys are integers and we want to ensure that we always refer keys we can use `Keys`
```jldoctest indexing_examples
julia> Axis((2:11), 1:10)[Keys(<(5))]
Axis(2:4 => 1:3)

julia> Axis((2:11), 1:10)[Indices(<(5))]
Axis(2:5 => 1:4)

julia> Axis((2:11), 1:10)[Keys(3)]
2

julia> Axis((2:11), 1:10)[Indices(3)]
3

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

julia> time1[!=(6.0s)] == vcat(1:9, 11:18)
true
```

These operators can also be combined to get more specific regions of an axis.
```jldoctest indexing_examples
julia> time1[and(>(2.5s), <(10.0s))]
Axis((3.0:0.5:9.5) s => 4:17)

julia> time1[>(2.5s) ⩓ <(10.0s)]  # equivalent to `and` you can use \And<TAB>
Axis((3.0:0.5:9.5) s => 4:17)

julia> time1[or(<(2.5s),  >(9.0s))] == vcat(1:2, 17:18)
true

julia> time1[<(2.5s) ⩔ >(9.0s)] == vcat(1:2, 17:18) # equivalent to `or` you can use \Or<TAB>
true

```

## Indexing an Array

Setup for running array examples.
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
AxisIndicesArray{Int64,1,Array{Int64,1}...}
 • dim_1 - Axis(["a", "b", "c"] => OneToMRange(3))

  a   1
  b   4
  c   7


julia> A[1:2,1:2]
AxisIndicesArray{Int64,2,Array{Int64,2}...}
 • dim_1 - Axis((0.1:0.1:0.2) s => Base.OneTo(2))
 • dim_2 - Axis(["a", "b"] => OneToMRange(2))
          a   b
  0.1 s   1   4
  0.2 s   2   5


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
AxisIndicesArray{Int64,2,Array{Int64,2}...}
 • dim_1 - Axis((0.1:0.1:0.3) s => Base.OneTo(3))
 • dim_2 - Axis(["a", "b"] => OneToMRange(2))
          a   b
  0.1 s   1   4
  0.2 s   2   5
  0.3 s   3   6


```

### Indexing With Functions

```jldoctest indexing_examples
julia> A[!=(.2s), in(["a", "c"])]
AxisIndicesArray{Int64,2,Array{Int64,2}...}
 • dim_1 - Axis(Unitful.Quantity{Float64,𝐓,Unitful.FreeUnits{(s,),𝐓,nothing}}[0.1 s, 0.3 s] => Base.OneTo(2))
 • dim_2 - Axis(["a", "c"] => OneToMRange(2))
          a   c
  0.1 s   1   7
  0.3 s   3   9


```

