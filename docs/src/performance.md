
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

