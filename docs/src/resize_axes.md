# Resizing Axes

These methods help with operations that need to resize axes, either dynamically or by creating a new instance of an axis. In addition to helping with operations related to array resizing, these may be useful for managing the axis of a vector throughout a `push!`, `pushfirst!`, `pop`, and `popfirst!` operation.

```@docs
AxisIndices.resize_first
AxisIndices.resize_first!
AxisIndices.resize_last
AxisIndices.resize_last!

AxisIndices.grow_first
AxisIndices.grow_first!
AxisIndices.grow_last
AxisIndices.grow_last!

AxisIndices.shrink_first
AxisIndices.shrink_first!
AxisIndices.shrink_last
AxisIndices.shrink_last!

AxisIndices.next_type
AxisIndices.prev_type
```
