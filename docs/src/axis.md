# The Axis Interface

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

## Performance

Indexing `CartesianAxes` is comparable to that of `CartesianIndices`.
```julia
julia> using AxisIndices, BenchmarkTools

julia> cartaxes = CartesianAxes((Axis(2.0:5.0), Axis(1:4)));

julia> cartinds = CartesianIndices((1:4, 1:4));

julia> @btime getindex(cartaxes, 2, 2)
20.848 ns (1 allocation: 32 bytes)
CartesianIndex(2, 2)

julia> @btime getindex(cartinds, 2, 2)
22.317 ns (1 allocation: 32 bytes)
CartesianIndex(2, 2)

julia> @btime getindex(cartaxes, ==(3.0), 2)
444.374 ns (7 allocations: 416 bytes)
CartesianIndex(2, 2)
```

Indexing `LinearAxes` is comparable to that of `LinearIndices`
```julia
julia> using AxisIndices, BenchmarkTools

julia> linaxes = LinearAxes((Axis(1.0:4.0), Axis(1:4)));

julia> lininds = LinearIndices((1:4, 1:4));

julia> @btime getindex(linaxes, 2, 2)
18.275 ns (0 allocations: 0 bytes)
6

julia> @btime getindex(lininds, 2, 2)
18.849 ns (0 allocations: 0 bytes)
6

julia> @btime getindex(linaxes, ==(3.0), 2)
381.098 ns (6 allocations: 384 bytes)
7
```

You may notice there's significant overhead for using the filtering syntax.
However, the filtering syntax takes advantage of a special type in base, `Fix2`.
This means that we can take advantage of filtering methods that have been optimized for specific types of keys. 
Here we do the same thing as above but we create a function that knows it's going to perform filtering.

```julia
julia> getindex_filter(a, i1, i2) = a[==(i1), ==(i2)]
getindex_filter (generic function with 1 method)

julia> @btime getindex_filter(linaxes, 3.0, 2)
57.216 ns (0 allocations: 0 bytes)
7

julia> linaxes2 = LinearAxes((Axis(Base.OneTo(4)), Axis(Base.OneTo(4))));

julia> @btime getindex_filter(linaxes2, 3, 2)
22.070 ns (0 allocations: 0 bytes)
7
```
Indexing `linaxes` is much faster now that it can be optimized inside of a function call.
However, it's still a little over twice as slow as normal indexing.
That's largely because of the cost of searching `1.0:4.0` (which is a `StepRangeLen` type in this case).
The second benchmark demonstrates how close we really are to standard indexing given similar range types.

## Interface

* Required
  * `Base.first`
  * `Base.last`
  * `ArrayInterface.known_first`
  * `ArrayInterface.known_last`
  * `ArrayInterface.unsafe_reconstruct`
* Recommended
  * `ArrayInterface.parent_type`


