
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
# infinitely easier to read when wrapping things at multiple levels or using Unitfulkeys
function Base.summary(io::IO, a::AbstractAxis)
    return print(io, "$(length(a))-elment $(typeof(a).name)($(keys(a)) => $(values(a)))")
end

function Base.summary(io::IO, a::AbstractSimpleAxis)
    return print(io, "$(length(a))-elment $(typeof(a).name)($(values(a))))")
end

