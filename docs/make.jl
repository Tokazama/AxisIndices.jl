
using Documenter
using AxisIndices
using LinearAlgebra
using Metadata
using Statistics

makedocs(;
    modules=[AxisIndices],
    format=Documenter.HTML(),
    pages=[
        "index.md",
        "references.md",
    ],
    repo="https://github.com/Tokazama/AxisIndices.jl/blob/{commit}{path}#L{line}",
    sitename="AxisIndices.jl",
    authors="Zachary P. Christensen",
)

deploydocs(
    repo = "github.com/Tokazama/AxisIndices.jl.git",
)

