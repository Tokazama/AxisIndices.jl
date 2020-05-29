# Tabular Interface


# TODO

`AxisIndices.jl` integrates with the `Tables.jl` interface via `AxisTable`.

## Construction

### Key Word Construction

```julia tables_docs
julia> using AxisIndices

julia> t = Table(A = 1:4, B = ["M", "F", "F", "M"])
```

### Property Name Assignment

```julia tables_docs
julia> t = AxisTable()

julia> t.A = 1:8

julia> t.B = ["M", "F", "F", "M", "F", "M", "M", "F"]
```

### Adding Rows
