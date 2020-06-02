
using Documenter, AxisIndices, LinearAlgebra, Statistics

makedocs(;
    modules=[AxisIndices],
    format=Documenter.HTML(),
    pages=[
        "Introduction" => "index.md",
        "Quick Start" => "quick_start.md",
        "Manual" => [
            "Axis Interface" => "axis.md",
            "Array Interface" => "arrays.md",
            "Tabular Interface" => "table.md",
            "Internals of Indexing" => "internals_of_indexing.md",
            "Pretty Printing" => "pretty_printing.md",
            "Compatibility" => "compatibility.md",
            "Observations" => "observations.md",
        ],
        "Examples" => [
            "CoefTable" => "coeftable.md",
            "TimeAxis Guide" => "time.md",
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

