# TimeAxis Guide

Here we define an axis that specifically supports time.
First, we compose the type and necessary methods for accessing it's properties and constructing it.
Second, we define a new trait that changes indexing.

## 1. The TimeAxis Type

This first section defines the minimum `keys`, `values`, `similar_type` and constructors for the `TimeAxis` type.
```jldoctest time_axis_example
julia> using AxisIndices, Dates, Unitful

julia> struct TimeAxis{K,V,Ks,Vs} <: AbstractAxis{K,V,Ks,Vs}
           axis::Axis{K,V,Ks,Vs}
           times::Dict{Symbol,Any}
           function TimeAxis{K,V,Ks,Vs}(axis::Axis{K,V,Ks,Vs}, times::Dict{Symbol,Pair{K,K}}) where {K,V,Ks,Vs}
               return new{K,V,Ks,Vs}(axis, times)
           end
           function TimeAxis{K,V,Ks,Vs}(args...; kwargs...) where {K,V,Ks,Vs}
               d = Dict{Symbol,Pair{K,K}}()
               for (k,v) in kwargs
                   d[k] = v
               end
               return new{K,V,Ks,Vs}(Axis{K,V,Ks,Vs}(args...), d)
           end
           function TimeAxis(args...; kwargs...)
               ax = Axis(args...)
               d = Dict{Symbol,Pair{keytype(ax),keytype(ax)}}()
               for (k,v) in kwargs
                   d[k] = v
               end
               return new{keytype(ax),valtype(ax),keys_type(ax),indices_type(ax)}(ax, d)
           end
       end

julia> Base.keys(t::TimeAxis) = keys(getfield(t, :axis))

julia> Base.values(t::TimeAxis) = values(getfield(t, :axis))

julia> function AxisIndices.similar_type(
           t::TimeAxis{K,V,Ks,Vs},
           new_keys_type::Type=Ks,
           new_indices_type::Type=Vs
       ) where {K,V,Ks,Vs}
           return TimeAxis{eltype(new_keys_type),eltype(new_indices_type),new_keys_type,new_indices_type}
       end
```

## 2. The TimeStampCollection Trait

Not only do we want to store discrete intervals of time with labels in the axis, but we want to reference them in a very simple way for indexing.
In other words, if we have previously assigned `:time1` the interval of 1 to 3 seconds, then we should be able to do `axis[:time1]` to index the axis instead of doing `axis[axis.times[:time1]]`.
However, the default indexing behavior is to look for a `Symbol` in the keys of an axis.
We want to tell the indexing pipeline that when we provide a `Symbol` with a `TimeAxis` we want to lookup the argument in `axis.times` and then pass the result to the typical indexing protocol.
So we make a new trait that for this.

```jldoctest time_axis_example
julia> Base.setindex!(t::TimeAxis, val, i::Symbol) = t.times[i] = val

julia> struct TimeStampCollection <: AxisIndices.AxisIndicesStyle end

julia> AxisIndices.is_element(::Type{TimeStampCollection}) = false

julia> function AxisIndices.AxisIndicesStyle(::Type{<:TimeAxis}, ::Type{Symbol})
           return TimeStampCollection()
       end

julia> function AxisIndices.to_index(::TimeStampCollection, axis, arg)
           return AxisIndices.to_index(t.axis, t.times[arg])
       end

julia> function AxisIndices.to_keys(::TimeStampCollection, axis, arg, index)
           return AxisIndices.to_keys(t.axis, t.times[arg], index)
       end
```

## TimeAxis in Action

Now we can access the time points of this access by the `Symbols` that correspond to intervals of time.
```jldoctest time_axis_example
julia> t = TimeAxis(Second(1):Second(1):Second(10));

julia> t[:time_1] = Second(1):Second(1):Second(3);

julia> t[:time_1] == 1:3
true

```

This can also be done with Unitful elements.
```jldoctest time_axis_example
julia> using Unitful: s

julia> t2 = TimeAxis((1:10)s);

julia> t2[:time_1] = 1s..3s;

julia> t[:time_1] == 1:3
true

```

This can naturally turn any array that is an `AbstractAxisIndices` subtype into a collection of time series data.
```jldoctest time_axis_example
julia> x = AxisArray(collect(1:2:20), t);

julia> x[:time_1]
3-element AxisArray{Int64,1}
 • dim_1 - 1 second:1 second:3 seconds

   1 second   1
  2 seconds   3
  3 seconds   5


```
