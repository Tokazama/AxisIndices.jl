
###
### getindex
###
@propagate_inbounds function Base.getindex(x::AbstractTable, arg1, arg2)
    return get_index(x, row_axis(x), col_axis(x), arg1, arg2)
end

@propagate_inbounds function get_index(x, raxis, caxis, arg1, arg2)
    return _unsafe_getindex(x, raxis, caxis, arg1, arg2, to_index(raxis, arg1), to_index(caxis, arg2))
end

@inline function _unsafe_getindex(x, raxis, caxis, arg1, arg2, i1::Integer, i2::Integer)
    return unsafe_getindex(unsafe_getindex(parent(x), (arg2,), (i2,)), (arg1,), (i1,))
end

@inline function _unsafe_getindex(x, raxis, caxis, arg1, arg2, i1::Integer, i2::AbstractVector)
    return [unsafe_getindex(unsafe_getindex(parent(x), (arg2,), (i,)), (arg1,), (i1,)) for i in i2]
end

_unsafe_getindex(x, raxis, caxis, arg1, arg2, i1::Integer, i2::Base.Slice) = TableRow(i1, x)

@inline function _unsafe_getindex(x, raxis, caxis, arg1, arg2, i1::AbstractVector, i2::Integer)
    return @inbounds(getindex(unsafe_getindex(parent(x), (arg2,), (i2,)), i1))
end

@inline function _unsafe_getindex(x, raxis, caxis, arg1, arg2, i1::Base.Slice, i2::Integer)
    return @inbounds(unsafe_getindex(parent(x), (arg2,), (i2,)))
end

# FIXME
#=
ERROR: MethodError: no method matching similar(::Type{Array{Array{String,1},1}}, ::Tuple{Base.IdentityUnitRange{OneToMRange{Int64}}})
Closest candidates are:
  similar(::AbstractAxisArray{T,N,P,AI} where AI where P where N, ::Tuple{Vararg{AbstractArray{T,1} where T,N}}) where {T, N} at /Users/zchristensen/projects/AxisIndices.jl/src/Arrays/AbstractAxisArray.jl:53
  similar(::AbstractArray{T,N} where N, ::Tuple) where T at abstractarray.jl:626
  similar(::Type{T}, ::Union{Integer, AbstractUnitRange}...) where T<:AbstractArray at abstractarray.jl:669
  ...
Stacktrace:
 [1] _array_for(::Type{Array{String,1}}, ::Base.Slice{OneToMRange{Int64}}, ::Base.HasShape{1}) at ./array.jl:680
 [2] collect(::Base.Generator{Base.Slice{OneToMRange{Int64}},AxisIndices.Tabular.var"#12#13"{Table{Array{AbstractArray{T,1} where T,1},SimpleAxis{Int64,Base.OneTo{Int64}},Axis{Symbol,Int64,Array{Symbol,1},OneToMRange{Int64}}},Colon,Array{Int64,1}}}) at ./a
rray.jl:693
 [3] _unsafe_getindex(::Table{Array{AbstractArray{T,1} where T,1},SimpleAxis{Int64,Base.OneTo{Int64}},Axis{Symbol,Int64,Array{Symbol,1},OneToMRange{Int64}}}, ::SimpleAxis{Int64,Base.OneTo{Int64}}, ::Axis{Symbol,Int64,Array{Symbol,1},OneToMRange{Int64}}, ::
Array{Int64,1}, ::Function, ::Array{Int64,1}, ::Base.Slice{OneToMRange{Int64}}) at /Users/zchristensen/projects/AxisIndices.jl/src/Tabular/indexing.jl:32
 [4] get_index(::Table{Array{AbstractArray{T,1} where T,1},SimpleAxis{Int64,Base.OneTo{Int64}},Axis{Symbol,Int64,Array{Symbol,1},OneToMRange{Int64}}}, ::SimpleAxis{Int64,Base.OneTo{Int64}}, ::Axis{Symbol,Int64,Array{Symbol,1},OneToMRange{Int64}}, ::Array{I
nt64,1}, ::Function) at /Users/zchristensen/projects/AxisIndices.jl/src/Tabular/indexing.jl:10
 [5] getindex(::Table{Array{AbstractArray{T,1} where T,1},SimpleAxis{Int64,Base.OneTo{Int64}},Axis{Symbol,Int64,Array{Symbol,1},OneToMRange{Int64}}}, ::Array{Int64,1}, ::Function) at /Users/zchristensen/projects/AxisIndices.jl/src/Tabular/indexing.jl:6
 [6] top-level scope at REPL[7]:1

=#
@inline function _unsafe_getindex(x, raxis, caxis, arg1, arg2, i1::AbstractVector, i2::AbstractVector)
    return Table([@inbounds(getindex(unsafe_getindex(parent(x), (arg2,), (i,)), i1)) for i in i2], caxis[i2])
end

@inline function _unsafe_getindex(x, raxis, caxis, arg1, arg2, i1::AbstractVector, ::Base.Slice)
    return Table([@inbounds(getindex(col_i, i1)) for col_i in parent(x)], caxis)
end




###
### setindex!
###

_nrows_equals_indices_length(raxis, ::Colon) = true
_nrows_equals_indices_length(raxis, arg) = length(to_index(raxis, arg)) == length(raxis)


function unsafe_pushcol!(x::AbstractTable, caxis, key, vals::AbstractVector)
    is_dynamic(caxis) || error("Columns may only be dynamically add to tables with a dynamic column axis.")
    is_dynamic(x) || error("Columns may only be dynamically add to tables with dynamic column storage.")
    Axes.push_key!(caxis, key)
    push!(parent(x), vals)
    return nothing
end

@propagate_inbounds function set_index!(x, raxis, caxis, vals, arg1, arg2)
    if is_element(arg2) && is_key(arg2)
        if checkindex(Bool, caxis, arg2)
        elseif _nrows_equals_indices_length(raxis, arg1) # might be creating new column
            if isempty(x)
                set_length!(raxis, length(vals))
            end
            unsafe_pushcol!(x, caxis, arg2, vals)
        else
            error("Cannot create new column $arg2 because length of provided column is not the same as the number of rows.")
        end
    else
        setindex!(getindex(parent(x), to_index(col_axis(x), arg2)), vals, to_index(row_axis(x), arg1))
    end
end

@propagate_inbounds function Base.setindex!(x::AbstractTable, vals, arg1, arg2)
    set_index!(x, row_axis(x), col_axis(x), vals, arg1, arg2)
end
