

function Base.show(io::IO, ::MIME"text/plain", a::AbstractAxis)
    print(io, "$(typeof(a).name)($(keys(a)) => $(values(a)))")
end

function Base.show(io::IO, a::AbstractAxis)
    print(io, "$(typeof(a).name)($(keys(a)) => $(values(a)))")
end

function Base.show(io::IO, ::MIME"text/plain", a::AbstractSimpleAxis)
    print(io, "$(typeof(a).name)($(values(a)))")
end

function Base.show(io::IO, a::AbstractSimpleAxis)
    print(io, "$(typeof(a).name)($(values(a)))")
end

# This is different than how most of Julia does a summary, but it also makes errors
# infinitely easier to read when wrapping things at multiple levels or using Unitful keys
function Base.summary(io::IO, a::AbstractAxis)
    return print(io, "$(length(a))-element $(typeof(a).name)($(keys(a)) => $(values(a)))")
end

function Base.summary(io::IO, a::AbstractSimpleAxis)
    return print(io, "$(length(a))-element $(typeof(a).name)($(values(a))))")
end

function Base.show(io::IO, x::AbstractAxisIndices; kwargs...)
    return show(io, MIME"text/plain"(), x, kwargs...)
end
function Base.show(io::IO, m::MIME"text/plain", x::AbstractAxisIndices{T,N}; kwargs...) where {T,N}
    println(io, "$(typeof(x).name.name){$T,$N,$(parent_type(x))...}")
    return show_array(io, x; kwargs...)
end

