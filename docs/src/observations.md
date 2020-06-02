# Observations

The `AxisIndices.ObservationDims` module is experimental and demonstrates the convenience of generating methods using the `@defdim` macro.

## Example usage

Let's create some data where each observation represents a unique set of subject measurements.
```jldoctest observation_docs
julia> using AxisIndices

julia> data = NamedAxisArray(reshape(1:6, 2, 3), x = 2:3, observations = [:subject_1, :subject_2, :subject_3])
2×3 NamedAxisArray{Int64,2}
 • x - 2:3
 • observations - [:subject_1, :subject_2, :subject_3]
      subject_1   subject_2   subject_3
  2           1           3           5
  3           2           4           6

```

The `ObservationDims` module isn't necessary to access observations or subject specific data...
```jldoctest observation_docs
julia> data[observations = :subject_1]
2-element NamedAxisArray{Int64,1}
 • x - 2:3

  2   1
  3   2

```

But there are a number of convenient methods for accessing observation data with this module.
```jldoctest observation_docs
julia> using AxisIndices.ObservationDims

julia> obsdim(data)  # the dimension along which observations are enumerated
2

julia> nobs(data)  # the number of distinct observations
3

julia> obs_keys(data)  # the key for each observation
3-element Array{Symbol,1}:
 :subject_1
 :subject_2
 :subject_3

```

There are several other useful methods such as `each_obs` which supports iterating along the observation dimension.
Such methods may be helpful in development of an API.
For example, multiple dispatch could be used to return an observation iterator with `each_obs` on non array types also.

## Reference

```@index
Pages   = ["observations.md"]
Modules = [AxisIndices.ObservationDims]
Order   = [:function, :type]
```

```@autodocs
Modules = [AxisIndices.ObservationDims]
```
