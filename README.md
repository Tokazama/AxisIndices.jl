# AxisIndices.jl

[![Build Status](https://travis-ci.com/Tokazama/AxisIndices.jl.svg?branch=master)](https://travis-ci.com/Tokazama/AxisIndices.jl)
[![stable-docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://Tokazama.github.io/AxisIndices.jl/stable)
[![dev-docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://Tokazama.github.io/AxisIndices.jl/dev)

Here are some reasons you should try AxisIndices
* **Flexible design** for **customizing multidimensional indexing** behavior
* **It's fast**. [StaticRanges](https://github.com/Tokazama/StaticRanges.jl) are used to speed up indexing ranges. If something is slow, please create a detailed issue.
* **Works with Julia's standard library** (in progress). The end goal of AxisIndices is to fully integrate with the standard library wherever possible. If you can find a relevant method that isn't supported in `Base`or  `Statistics` then it's likely an oversight, so make an issue. `LinearAlgebra`, `MappedArrays`, `OffsetArrays`, and `NamedDims` also have some form of support.

The linked documentation provides a very brief ["Quick Start"](https://tokazama.github.io/AxisIndices.jl/dev/quick_start/) section along with detailed documentation of internal methods and types.

## Construction By Axes

Axes can indicate what kind of array you want (static/fixed size) and/or can map key values to indices.

```julia
julia> using AxisIndices

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
