
using Documenter, AxisIndices

makedocs(;
    modules=[AxisIndices],
    format=Documenter.HTML(),
    pages=[
        "Introduction" => "index.md",
        "Quick Start" => "quick_start.md",
        "Manual" => [
            "The Axis" => "axis.md",
            "Internals of Indexing" => "internals_of_indexing.md",
            "Combining Axes" => "combining_axes.md",
            "Pretty Printing" => "pretty_printing.md",
            "Compatibility" => "compatibility.md",
        ],
        "Examples" => [
            "Indexing Tutorial" => "indexing.md",
            "CoefTable" => "coeftable.md",
            "TimeAxis Guide" => "time.md",
        ],
        "Reference" => "references.md",
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

