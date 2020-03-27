# TimeAxis

Here we define an axis that specifically supports time.
This first section defines the minimum `keys`, `values`, `similar_type` and constructors for the `TimeAxis` type.
```jldoctest time_axis_example
julia> using AxisIndices, Dates, Unitful

julia> struct TimeAxis{K,V,Ks,Vs} <: AbstractAxis{K,V,Ks,Vs}
           axis::Axis{K,V,Ks,Vs}
           times::Dict{Symbol,Pair{K,K}}
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
               return new{keytype(ax),valtype(ax),keys_type(ax),values_type(ax)}(ax, d)
           end
       end

julia> Base.keys(t::TimeAxis) = keys(getfield(t, :axis))

julia> Base.values(t::TimeAxis) = values(getfield(t, :axis))

julia> function AxisIndices.similar_type(
           t::TimeAxis{K,V,Ks,Vs},
           new_keys_type::Type=Ks,
           new_values_type::Type=Vs
          ) where {K,V,Ks,Vs}
           return TimeAxis{eltype(new_keys_type),eltype(new_values_type),new_keys_type,new_values_type}
       end
```

Here are some extras to make it more useful.
```jldoctest time_axis_example
julia> Base.setindex!(t::TimeAxis, val, i::Symbol) = t.times[i] = val

julia> function Base.to_index(t::TimeAxis, i::Symbol)
           f, l = t.times[i]
           return Base.to_index(t, and(>=(f), <=(l)))
       end
```

Now we can access the time points of this access by the `Symbols` that correspond to intervals of time.
```jldoctest time_axis_example
julia> t = TimeAxis(Second(1):Second(1):Second(10));

julia> t[:time_1] = Pair(Second(1), Second(3));

julia> t[:time_1] == 1:3
true
```

This can also be done with Unitful elements.
```jldoctest time_axis_example
julia> using Unitful: s

julia> t2 = TimeAxis((1:10)s);

julia> t2[:time_1] = Pair(1s, 3s);

julia> t[:time_1] == 1:3
true
```

And now we have a time series array.
```jldoctest time_axis_example
julia> x = AxisIndicesArray(collect(1:2:20), t);

julia> x[:time_1]
1-dimensional AxisIndicesArray{Int64,1,Array{Int64,1}...}

   1 second   1.0
  2 seconds   3.0
  3 seconds   5.0


```

