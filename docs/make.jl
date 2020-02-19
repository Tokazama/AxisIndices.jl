
using Documenter, AxisIndices

makedocs(;
    modules=[AxisIndices],
    format=Documenter.HTML(),
    pages=[
        "Introduction" => "index.md"
        "Axis Interface" => [
            "Introduction" => "axis_intro.md",
            "Types" => "axis_types.md",
            "Combining Axes" => "combine_axes.md",
            "Concatenating Axes" => "concat_axes.md",
            "Appending Axes" => "append_axes.md",
            "Reindexing Axes" => "reindex_axes.md",
            "Resizing Axes" => "resize_axes.md",
            "Axes to Arrays" => "axes_to_arrays.md",
        ],
    ]
    repo="https://github.com/Tokazma/AxisIndices.jl/blob/{commit}{path}#L{line}",
    sitename="AxisIndices.jl",
    authors="Zachary P. Christensen",
)

deploydocs(
    repo = "github.com/Tokazama/AxisIndices.jl.git",
)

