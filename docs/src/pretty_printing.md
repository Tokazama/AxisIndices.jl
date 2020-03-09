# Pretty Printing

!!! warning
    Currently pretty printing is an experimental feature that may undergo rapid changes.

Each 2-dimensional `AbstractAxisIndices` subtype prints with keyword arguments passed to `PrettyTables`.
N-dimensional arrays iteratively call matrix printing similar to how base Julia does (but passing keyword arguments for pretty printing).
Keywords are incorporated through the `show` method (e.g., `show(::IO, ::AbstractAxisIndices; kwargs...)`).


