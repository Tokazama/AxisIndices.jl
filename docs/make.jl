
using Documenter
using AxisIndices
using LinearAlgebra
using Statistics

makedocs(;
    modules=[AxisIndices],
    format=Documenter.HTML(),
    pages=[
        "Introduction" => "index.md",
        "Quick Start" => "quick_start.md",
        "Manual" => [
            "Axis Interface" => "axis.md",
            "Array Interface" => "arrays.md",
            "AxisArrays" => "axis_arrays.md",
            "OffsetAxes" => "offset_axes.md",
            "Metadata" => "metadata.md",
            "Named Axes" => "named_axes.md",
            "Standard Library" => "standard_library.md",
            "Internals of Indexing" => "internals_of_indexing.md",
            "Pretty Printing" => "pretty_printing.md",
            "Compatibility" => "compatibility.md",
        ],
        "Examples" => [
            "CoefTable" => "coeftable.md",
            "TimeAxis Guide" => "time.md",
        ],
        "Comparison to Other Packages" => "comparison.md",
        "Acknowledgments" => "acknowledgments.md"
    ],
    repo="https://github.com/Tokazama/AxisIndices.jl/blob/{commit}{path}#L{line}",
    sitename="AxisIndices.jl",
    authors="Zachary P. Christensen",
)

deploydocs(
    repo = "github.com/Tokazama/AxisIndices.jl.git",
)

