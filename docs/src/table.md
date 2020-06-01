# Tabular Interface


# TODO

`AxisIndices.jl` integrates with the `Tables.jl` interface via `AxisTable`.

## Construction

### Key Word Construction

```jldoctest tables_docs
julia> using AxisIndices

julia> t = Table(A = 1:4, B = ["M", "F", "F", "M"])
Table
┌───┬───┐
│ A │ B │
├───┼───┤
│ 1 │ M │
│ 2 │ F │
│ 3 │ F │
│ 4 │ M │
└───┴───┘

```

### Property Name Assignment

```jldoctest tables_docs
julia> t = Table();

julia> t.A = 1:8;

julia> t.B = ["M", "F", "F", "M", "F", "M", "M", "F"];

julia> t
Table
┌───┬───┐
│ A │ B │
├───┼───┤
│ 1 │ M │
│ 2 │ F │
│ 3 │ F │
│ 4 │ M │
│ 5 │ F │
│ 6 │ M │
│ 7 │ M │
│ 8 │ F │
└───┴───┘

```

### Adding Rows

TODO

