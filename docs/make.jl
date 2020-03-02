
using Documenter, AxisIndices

makedocs(;
    modules=[AxisIndices],
    format=Documenter.HTML(),
    pages=[
        "Introduction" => "index.md",
        "Quick Start" => "quick_start.md",
        "The Axis" => "axis.md",
        "Arrays With Axes" => "axisindicesarray.md",
        "Comparison to Other Packages" => "comparison.md",
        "Pretty Printing" => "pretty_printing.md",
    ],
    repo="https://github.com/Tokazma/AxisIndices.jl/blob/{commit}{path}#L{line}",
    sitename="AxisIndices.jl",
    authors="Zachary P. Christensen",
)

deploydocs(
    repo = "github.com/Tokazama/AxisIndices.jl.git",
)

