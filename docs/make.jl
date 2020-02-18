
using Documenter, AxisIndices

makedocs(;
    modules=[AxisIndices],
    format=Documenter.HTML(),
    pages=[
        "Introduction" => "index.md"
    ]
    repo="https://github.com/Tokazma/AxisIndices.jl/blob/{commit}{path}#L{line}",
    sitename="AxisIndices.jl",
    authors="Zachary P. Christensen",
)

deploydocs(
    repo = "github.com/Tokazama/AxisIndices.jl.git",
)

