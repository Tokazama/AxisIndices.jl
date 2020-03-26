
using Documenter, AxisIndices

makedocs(;
    modules=[AxisIndices],
    format=Documenter.HTML(),
    pages=[
        "Introduction" => "index.md",
        "Quick Start" => "quick_start.md",
        "Axes" => [
            "The Axis" => "axis.md",
            "Axis Traits" => "traits.md",
            "Broadcasting Axes" => "broadcasting_axes.md",
            "Concatenating Axes" => "concatenating_axes.md",
            "Appending Axes" => "appending_axes.md",
        ],
        "Arrays With Axes" => [
            "AbstractAxisIndices" => "array.md",
            "Pretty Printing" => "pretty_printing.md",
            "Compatibility" => "compatibility.md",
        ],
        "Examples" => [
            "Indexing" => "indexing.md",
            "CoefTable" => "coeftable.md",
            "TimeAxis" => "time.md",
        ],
        "Comparison to Other Packages" => "comparison.md",
        "Acknowledgments" => "acknowledgments.md"
    ],
    repo="https://github.com/Tokazma/AxisIndices.jl/blob/{commit}{path}#L{line}",
    sitename="AxisIndices.jl",
    authors="Zachary P. Christensen",
)

deploydocs(
    repo = "github.com/Tokazama/AxisIndices.jl.git",
)
