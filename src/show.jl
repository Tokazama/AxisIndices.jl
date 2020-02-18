
function Base.show(io::IO, m::MIME"text/plain", a::AxisIndicesArray)
    show(io, m, summary(a))
    show_axesarray(io, m, parent(a), axes(a))
end

show_axesarray(io::IO, m, a::AbstractArray, axes::Tuple) = show(io, m, a)
show_axesarray(io::IO, a::AbstractArray, axes::Tuple) = show(io, a)

