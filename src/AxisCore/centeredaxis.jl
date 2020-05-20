
struct CenteredAxis{V,Vs} <: AbstractOffsetAxis{V,Vs}
    values::Vs

    function CenteredAxis{V,Vs}(index::Vs) where {V<:Integer,Vs<:AbstractUnitRange{V}}
        return new{V,Vs}(index)
    end
end

Base.values(axis::CenteredAxis) = getfield(axis, :values)

offset(axis::CenteredAxis) = -div(length(axis) + 1, 2) - (first(getfield(axis, :values)) - 1)

function CenteredAxis{V,Vs}(index) where {V<:Integer,Vs<:AbstractUnitRange{V}}
    return CenteredAxis{V,Vs}(Vs(index))
end

function CenteredAxis{V}(index::Vs) where {V<:Integer,Vs<:AbstractUnitRange{V}}
    return CenteredAxis{V,Vs}(index)
end

function CenteredAxis{V}(index::Vs) where {V<:Integer,V2,Vs<:AbstractUnitRange{V2}}
    return CenteredAxis{V}(convert(AbstractUnitRange{V}, index))
end

CenteredAxis(index) = CenteredAxis{eltype(index)}(index)

function StaticRanges.similar_type(::A, vs_type::Type=values_type(A)) where {A<:CenteredAxis}
    return StaticRanges.similar_type(A, vs_type)
end

