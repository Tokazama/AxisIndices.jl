
using Documenter
using AxisIndices
using LinearAlgebra
using Metadata
using Statistics

makedocs(;
    modules=[AxisIndices],
    format=Documenter.HTML(),
    pages=[
        "AxisIndices" => "index.md",
        "Manual" => [
            "AxisArrays" => "axis_arrays.md",
            "OffsetAxes" => "offset_axes.md",
            #"Named Axes" => "named_axes.md",
            "Standard Library" => "standard_library.md",
            "Internals of Indexing" => "internals_of_indexing.md",
            "Compatibility" => "compatibility.md",
            "Performance" => "performance.md"
        ],
        #=
        "Examples" => [
            "CoefTable" => "coeftable.md",
            "TimeAxis Guide" => "time.md",
        ],
        =#
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

