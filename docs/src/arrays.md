# Array Interface

## Construction

Take a standard array and attach custom keys along the indices of each dimension.
```jldoctest arrays_interface
julia> using AxisIndices

julia> A_base = [1 2; 3 4];

julia> A_axis = AxisArray(A_base, ["a", "b"], [:one, :two])
2×2 AxisArray(::Array{Int64,2}
  • axes:
     1 = ["a", "b"]
     2 = [:one, :two]
)
       :one   :two
  "a"  1      2
  "b"  3      4

```

Note that the keys provided are converted to a subtype of `AbstractAxis`.
```jldoctest arrays_interface
julia> axes(A_axis, 1)
Axis(["a", "b"] => SimpleAxis(1:2))

```

An `AxisArray` may also be initialized using similar syntax as `Array{T}(undef, dims)`.
```jldoctest arrays_interface
julia> A_axis = AxisArray{Int}(undef, ["a", "b"], [:one, :two]);

julia> A_axis[:,:] = A_base;

julia> A_axis
2×2 AxisArray(::Array{Int64,2}
  • axes:
     1 = ["a", "b"]
     2 = [:one, :two]
)
       :one   :two
  "a"  1      2
  "b"  3      4

```

Names can be attached to each dimension/axis using `NamedAxisArray`.
```jldoctest arrays_interface
julia> A_named_axis = NamedAxisArray{(:xdim, :ydim)}(A_axis)
2×2 NamedDimsArray(AxisArray(::Array{Int64,2}
  • axes:
     xdim = ["a", "b"]
     ydim = [:one, :two]
))
       :one   :two
  "a"  1      2
  "b"  3      4

julia> A_named_axis == NamedAxisArray{(:xdim, :ydim)}(A_base, ["a", "b"], [:one, :two])
true

```

We can also attach metadata to an array.
```jldoctest arrays_interface
julia> using Metadata

julia> attach_metadata(AxisArray(A_base, (["a", "b"], [:one, :two])), (m1 = 1, m2 = 2))
2×2 attach_metadata(AxisArray(::Array{Int64,2}
  • axes:
     1 = ["a", "b"]
     2 = [:one, :two]
), ::NamedTuple{(:m1, :m2),Tuple{Int64,Int64}}
  • metadata:
     m1 = 1
     m2 = 2
)
       :one   :two
  "a"  1      2
  "b"  3      4

julia> attach_metadata(NamedAxisArray{(:xdim, :ydim)}(A_base, ["a", "b"], [:one, :two]), (m1 = 1, m2 = 2))
2×2 NamedDimsArray(attach_metadata(AxisArray(::Array{Int64,2}
  • axes:
     xdim = ["a", "b"]
     ydim = [:one, :two]
), ::NamedTuple{(:m1, :m2),Tuple{Int64,Int64}}
  • metadata:
     m1 = 1
     m2 = 2
))
       :one   :two
  "a"  1      2
  "b"  3      4

```

## Indexing

Behavior of an `AxisArray` is similar to that of the common `Array` type.

```jldoctest indexing_examples
julia> using AxisIndices

julia> import Unitful: s

julia> A_base = reshape(1:9, 3,3);

julia> A_axis = AxisArray(A_base, ((.1:.1:.3)s, ["a", "b", "c"]))
3×3 AxisArray(reshape(::UnitRange{Int64}, 3, 3)
  • axes:
     1 = (0.1:0.1:0.3) s
     2 = ["a", "b", "c"]
)
         "a"   "b"   "c"
  0.1 s  1     4     7
  0.2 s  2     5     8
  0.3 s  3     6     9

julia> A_axis[1,1] == A_base[1,1]
true

julia> A_axis[1] == A_base[1] # linear indexing works too
true

julia> A_axis[1,:]
3-element AxisArray(::Array{Int64,1}
  • axes:
     1 = ["a", "b", "c"]
)
       1
  "a"  1
  "b"  4
  "c"  7

julia> A_axis[1:2, 1:2]
2×2 AxisArray(::Array{Int64,2}
  • axes:
     1 = (0.1:0.1:0.2) s
     2 = ["a", "b"]
)
         "a"   "b"
  0.1 s  1     4
  0.2 s  2     5

julia> A_axis[1:3]
3-element AxisArray(::Array{Int64,1}
  • axes:
     1 = 1:3
)
     1
  1  1
  2  2
  3  3

```

In addition to standard indexing, an `AxisArray` can be indexed by its keys...
```jldoctest indexing_examples
julia> A_axis[.1s, "a"]
1

julia> A_axis[0.1s..0.3s, ["a", "b"]]
3×2 AxisArray(::Array{Int64,2}
  • axes:
     1 = (0.1:0.1:0.3) s
     2 = ["a", "b"]
)
         "a"   "b"
  0.1 s  1     4
  0.2 s  2     5
  0.3 s  3     6

```


...or functions that filter the keys.
```jldoctest indexing_examples
julia> A_axis[!=(.2s), in(["a", "c"])]
2×2 AxisArray(::Array{Int64,2}
  • axes:
     1 = (0.1:0.1:0.2) s
     2 = ["a", "b"]
)
         "a"   "b"
  0.1 s  1     7
  0.2 s  3     9

```

Indexing notation from the [EllipsisNotation.jl](https://github.com/ChrisRackauckas/EllipsisNotation.jl) packages is also supported.
```
# FIXME
julia> A = AxisArray{Int}(undef, 2, 4, 2);

julia> A[.., 1] = [2 1 4 5
                   2 2 3 6];

julia> A[.., 2] = [3 2 6 5 3 2 6 6];

julia> A[:, :, 1] == [2 1 4 5
                      2 2 3 6]
true

julia> A = AxisArray(ones(3,3,3,3,3));

julia> size(A[1:1, .., 1:1])
(1, 3, 3, 3, 1)

```

## Combining Different Axes

One of benefits of AxisIndices using a unified backend for multiple axis types is that they
can be arbitrarily mixed together. For example, here's an example the first indices are
offset by 4 and the last indices are centered.

```jldoctest indexing_examples
julia> AxisArray(ones(3,3), offset(4), center)
3×3 AxisArray(::Array{Float64,2}
  • axes:
     1 = 5:7
     2 = -1:1
)
     -1    0    1
  5   1.0  1.0  1.0
  6   1.0  1.0  1.0
  7   1.0  1.0  1.0

```

Although this example isn't particularly useful, being able to arbitrarily mix axes with
static characteristics, metadata, offset indices, semantic keys, etc. lends itself to easy
custom designs and algorithms.


