# AxisIndices.jl

[![Build Status](https://travis-ci.com/Tokazama/AxisIndices.jl.svg?branch=master)](https://travis-ci.com/Tokazama/AxisIndices.jl)
[![stable-docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://Tokazama.github.io/AxisIndices.jl/stable)
[![dev-docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://Tokazama.github.io/AxisIndices.jl/dev)

Here are some reasons you should try AxisIndices
* **Flexible design** for **customizing multidimensional indexing** behavior
* **It's fast**. [StaticRanges](https://github.com/Tokazama/StaticRanges.jl) are used to speed up indexing ranges. If something is slow, please create a detailed issue.
* **Works with Julia's standard library** (in progress). The end goal of AxisIndices is to fully integrate with the standard library wherever possible. If you can find a relevant method that isn't supported in `Base`or  `Statistics` then it's likely an oversight, so make an issue. `LinearAlgebra`, `MappedArrays`, `OffsetArrays`, and `NamedDims` also have some form of support.

# Contents

* [Introduction](#introduction)
* [The Axis Interface](#the-axis-interface)
* [The Array Interface](#the-array-interface)

# Introduction

The goals of this package are:
1. Facilitate multidimensional indexing (e.g., `instance_of_an_array[indices]`) that supports semantic user facing indices (e.g., `indices = Second(1)`).
2. Accomplishing the first goal should not interfere in the ability to perform the vast majority of array related methods (e.g, `vcat`, `append!`, etc.).
3. It should be easy to implement new subtypes of `AbstractAxis` that accommodate novel behavior and needs.

These goals are accomplished predominantly through the `AbstractAxis` type.
It is a subtype of `AbstractUnitRange{<:Integer}` with an additional interface for creating keys and interacting with them.
This additional interface is intended to be easily extended to new types that may be needed for a variety of different situations.
An additional `AxisArray` type is provided that uses any subtype of `AbstractAxis` for each axis.
However, many methods are provided and documented internally so that it's easy for users to alter the behavior of an `AxisArray` with a new `AbstractAxis` subtype or create an entirely unique multidimensional structure.

## Quick Start

Custom indexing only requires specifying a tuple of keys[^1] for the indices of each dimension.
```julia
julia> using AxisIndices

julia> A = AxisArray(reshape(1:9, 3,3),
               (2:4,        # first dimension has keys 2:4
                3.0:5.0));  # second dimension has keys 3.0:5.0
```

Most code should work just the same for an `AxisArray`...
```julia
julia> A[2, 1]
1

julia> A[2:4, 1:2] == parent(A)[1:3, 1:2]
true

julia> sum(A) == sum(parent(A))
true
```

But now the indices of each dimension have keys that we can filter through.
```julia
julia> A[==(2), ==(3.0)] == parent(A)[findfirst(==(2), 2:4), findfirst(==(3.0), 3.0:5.0)] == 1
true

julia> A[<(4), <(5.0)] == parent(A)[findall(<(4), 2:4), findall(<(5.0), 3.0:5.0)] == [1 4; 2 5]
true
```

Any value that is not a `CartesianIndex` or subtype of `Real` is considered a dedicated key type.
In other words, it could never be used for default indexing and will be treated the same as the `==` filtering syntax above.
```julia
julia> AxisArray([1, 2, 3], (["one", "two", "three"],))["one"]
1
```

Note that the first call only returns a single element, where the last call returns an array.
This is because all keys must be unique so there can only be one value that returns `true` if filtering by `==`, which is the same as indexing by `1` (e.g., only one index can equal `1`).
The last call uses operators that can produce any number of `true` values and the resulting output is an array.
This is the same as indexing an array by any vector (i.e., returns another array).

## Construction By Axes

Axes can indicate what kind of array you want (static/fixed size) and/or can map key values to indices.

```julia
julia> using ArrayInterface

julia> import ArrayInterface: StaticInt

julia> x = AxisArray{Int}(
          undef,                      # initialize empty array
          StaticInt(1):StaticInt(2),  # first  axis with known size of two
          StaticInt(1):StaticInt(2)   # second axis with known size of two
       );

julia> ArrayInterface.known_length(x) # size is known at compile time
4

julia> x[1:4] .= 1;  # underlying type is mutable `Array`, so we can assign new values

julia> x
2×2 AxisArray(::Array{Int64,2}
  • axes:
     1 = 1:2
     2 = 1:2
)
     1  2
  1  1  1
  2  1  1  

julia> A = AxisArray(reshape(1:4, 2, 2), [:a, :b], ["one", "two"])
2×2 AxisArray(reshape(::UnitRange{Int64}, 2, 2)
  • axes:
     1 = [:a, :b]
     2 = ["one", "two"]
)
      "one"   "two" 
  :a  1       3
  :b  2       4  

julia> A[:a, "one"]
1
```

## Indexing Cheat Sheet

The following can be replicated by using Unitful seconds (i.e., `using Unitful: s`)

| Code                                                |    | Result                             |
|----------------------------------------------------:|----|------------------------------------|
| `Axis((1:10)s, 2:11)[1s]`                           | -> | `2`                                |
| `Axis((1:10)s, 2:11)[2]`                            | -> | `2`                                |
| `Axis((1:10)s, 2:11)[1s..3s]`                       | -> | `Axis((1:3)s, 2:4)`                |
| `Axis((1:10)s, 2:11)[2:4]`                          | -> | `Axis((1:3)s, 2:4)`                |
| `Axis((1:10)s, 2:11)[>(5s)]`                        | -> | `Axis((6:10)s, 7:11)`              |
| `Axis((1:10)s, 2:11)[<(5s)]`                        | -> | `Axis((1:4)s, 2:5)`                |
| `Axis((1:10)s, 2:11)[==(5s)]`                       | -> | `6`                                |
| `Axis((1:10)s, 2:11)[!=(5s)]`                       | -> | `[1, 2, 3, 4, 5, 7, 8, 9, 10, 11]` |
| `Axis((1:10)s, 2:11)[in((1:2)s)]`                   | -> | `Axis((1:2)s, 2:3)`                |
| `Axis([pi + 0, pi + 1])[isapprox(3.14, atol=1e-2)]` | -> | `1`                                |
| `SimpleAxis(1:10)[<(5)]`                            | -> | `SimpleAxis(1:4)`                  |

# The Axis Interface

<details>

The following describes the components necessary to construct and manipulate existing and new subtypes of `AbstractAxis`.


| `AbstractAxis` Type | Usage                                                                               |
|--------------------:|:------------------------------------------------------------------------------------|
| [`Axis`](@ref)              | Attach keys to indices                                                      |
| [`SimpleAxis`](@ref)        | Give standard indices access AxisIndices's syntax                           |
| [`CenteredAxis`](@ref)      | Enforce indexing that is centered around zero                               |
| [`OffsetAxis`](@ref)        | Enforce indexing with where the first index is offset from 1                |
| [`IdentityAxis`](@ref)      | Preserve indices after indexing                                             |
| [`MetaAxis`](@ref)          | Attach arbitrary metadata to an axis                                        |
| [`StructAxis`](@ref)        | Map a type's field names and field types to each element along an axis.     |


## Introduction 

The supertype to all axis types herein is the `AbstractAxis`, which is a subtype of `AbstractUnitRange{<:Integer}`.

If we have a set of keys `a b c` and a set of indices `1 2 3` then the key `a` maps to the index `1`.
Given these definitions, the `AbstractAxis` differs from the classic dictionary in the following two ways:
1. The `valtype` of `AbstractAxis` is always an integer.
2. The `values` are always unique and continuous.

The two main axis types defined here are `Axis` and `SimpleAxis`.
The standard syntax for indexing doesn't change at all for these types.
```jldoctest intro_axis_examples
julia> using AxisIndices

julia> using Dates

julia> using ChainedFixes  # provides `and`, `or`, `⩓`, `⩔` methods

julia> sa = SimpleAxis(1:10)
SimpleAxis(1:10)

julia> sa[2]
2

julia> sa[>(2)]
SimpleAxis(3:10)

julia> a = Axis(1:10)
Axis(1:10 => SimpleAxis(1:10))

julia> a[2]
2

julia> a[2:3]
Axis(2:3 => SimpleAxis(2:3))
```

But now we can also use functions to index by the keys of an `AbstractAxis`.
```jldoctest intro_axis_examples
julia> a = Axis(2.0:11.0)
Axis(2.0:1.0:11.0 => SimpleAxis(1:10))

julia> a[1]
1

julia> a[isequal(2.0)]
1

julia> a[>(2)]
Axis(3.0:1.0:11.0 => SimpleAxis(2:10))

julia> a[>(2.0)]
Axis(3.0:1.0:11.0 => SimpleAxis(2:10))

julia> a[and(>(2.0), <(8.0))]
Axis(3.0:1.0:7.0 => SimpleAxis(2:6))

julia> sa[in(3:5)]
SimpleAxis(3:5)
```

This also allows certain syntax special treatment because they are obviously not referring to traditional integer based indexing.
```jldoctest intro_axis_examples
julia> x, y, z = Axis([:one, :two, :three]), Axis(["one", "two", "three"]), Axis(Second(1):Second(1):Second(3));

julia> x[:one]
1

julia> x[:one] == y["one"] == z[Second(1)]
true

julia> x[[:one, :two]]
2-element AxisArray(::Array{Int64,1}
  • axes:
     1 = [:one, :two]
)
        1
  :one  1
  :two  2
```
Note in the last example that a vector was returned instead of an `AbstractAxis`.
An `AbstractAxis` is a subtype of `AbstractUnitRange` and therefore cannot be reformed after any operation that does not guarantee the return of another unit range.
This is similar to the behavior of `UnitRange` in base.

## Indexing an Axis

Setup for running axis examples.
```jldoctest indexing_examples
julia> using AxisIndices, Unitful, ChainedFixes

julia> using Unitful: s

julia> time1 = Axis((1.5:.5:10)s)
Axis((1.5:0.5:10.0) s => SimpleAxis(1:18))

julia> time2 = Axis((1.5:.5:10)s, SimpleAxis(2:19))
Axis((1.5:0.5:10.0) s => SimpleAxis(2:19))
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
ERROR: BoundsError: attempt to access Axis((1.5:0.5:10.0) s => SimpleAxis(2:19)) at index [1]
[...]
```
Notice that `time2[1]` throws an error.
This is because the indices of the `time2` axis don't contain a 1 and begins at 2.
This allows an axis to map to any single dimensional memory mapping, even if it doesn't start at 1.

Indexing an axis with a collection of integers works similarly to indexing any other `AbstractUnitRange`.
That is, using other subtypes of `AbstractUnitRange` preserves the structure...
```jldoctest indexing_examples
julia> time1[1:2]
Axis((1.5:0.5:2.0) s => SimpleAxis(1:2))

julia> time2[2:3]
Axis((1.5:0.5:2.0) s => SimpleAxis(2:3))
```

However, we can't ensure that the resulting range will have a step of one in other cases so only the indices are returned.
```jldoctest indexing_examples
julia> time1[1:2:3]
2-element AxisArray(::StepRange{Int64,Int64}
  • axes:
     1 = (1.5:1.0:2.5) s
)
         1
  1.5 s  1
  2.5 s  3

julia> time1[[1, 2, 3]]
3-element AxisArray(::Array{Int64,1}
  • axes:
     1 = Unitful.Quantity{Float64,𝐓,Unitful.FreeUnits{(s,),𝐓,nothing}}[1.5 s, 2.0 s, 2.5 s]
)
         1
  1.5 s  1
  2.0 s  2
  2.5 s  3

julia> time1[firstindex(time1):end]
Axis((1.5:0.5:10.0) s => SimpleAxis(1:18))

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
Axis((1.5:0.5:3.0) s => SimpleAxis(1:4))

julia> time1[3s..4.5s]
Axis((3.0:0.5:4.5) s => SimpleAxis(4:7))
```

### Approximate Indexing

```jldoctest indexing_examples
julia> axis = Axis([pi + 0, pi + 1]);

julia> axis[3.141592653589793]
1

julia> axis[3.14159265358979]
ERROR: BoundsError: attempt to access Axis([3.141592653589793, 4.141592653589793] => SimpleAxis(1:2)) at index [3.14159265358979]
[...]

julia> axis[isapprox(3.14159265358979)]
1

julia> axis[isapprox(3.14, atol=1e-2)]
1
```

### Indexing With Functions

Operators that typically return `true` or `false` can often 
```jldoctest indexing_examples
julia> time1[<(3.0s)]
Axis((1.5:0.5:2.5) s => SimpleAxis(1:3))

julia> time1[>(3.0s)]
Axis((3.5:0.5:10.0) s => SimpleAxis(5:18))

julia> time1[==(6.0s)]
10

julia> time1[!=(6.0s)] == vcat(1:9, 11:18)
true
```

These operators can also be combined to get more specific regions of an axis.
```jldoctest indexing_examples
julia> time1[and(>(2.5s), <(10.0s))]
Axis((3.0:0.5:9.5) s => SimpleAxis(4:17))

julia> time1[>(2.5s) ⩓ <(10.0s)]  # equivalent to `and` you can use \And<TAB>
Axis((3.0:0.5:9.5) s => SimpleAxis(4:17))

julia> time1[or(<(2.5s),  >(9.0s))] == vcat(1:2, 17:18)
true

julia> time1[<(2.5s) ⩔ >(9.0s)] == vcat(1:2, 17:18) # equivalent to `or` you can use \Or<TAB>
true

```

## Interface

* Required
  * `Base.first`
  * `Base.last`
  * `ArrayInterface.known_first`
  * `ArrayInterface.known_last`
  * `ArrayInterface.unsafe_reconstruct`
* Recommended
  * `ArrayInterface.parent_type`

</details>

# The Array Interface

<details>

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

</details>

<br>
## Notes

[^1]: Terminology here is important here. Keys, indices, and axes each have a specific meaning. Throughout the documentation the following functional definitions apply:

  * axis: maps a set of keys to a set of indices.
  * indices: a set of integers (e.g., `<:Integer`) that locate the in memory locations of elements.
  * keys: maps a set of any type to a set of indices
  * indexing: anytime one calls `getindex` or uses square brackets to navigate the elements of a collection
  Also note the use of argument (abbreviated `arg` in code) and arguments (abbreviated `args` in code). These terms specifically refer to what users pass to an indexing method. Therefore, an argument may be a key (`:a`), index (`1`), or something else that maps to one of the two (`==(1)`).
