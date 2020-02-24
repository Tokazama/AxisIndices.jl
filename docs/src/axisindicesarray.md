# AxisIndicesArray

`AxisIndicesArray` is provided as a convenient subtype of `AbstractArray` for using instances of `AbstractAxis`.
The implementation is meant to be basic and have sane defaults that can be overridden as necessary.
In other words, default methods for manipulating arrays that return an `AxisIndicesArray` should not cause unexpected downstream behavior for users.
However, it should also be possible to change the behavior of an `AxisIndicesArray` through unique subtypes of `AbstractAxis`.

