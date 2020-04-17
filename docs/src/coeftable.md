# Making a CoefTable

This example will guide you through manipulating the pretty printing framework.
We'll motivate this by trying to recreate the coefficient table from StatsBase.jl.

## Creating the Table 
```julia
julia> using AxisIndices, DataFrames, GLM, Distributions

julia> function coefarray(mm::StatsModels.TableRegressionModel; level::Real=0.95)
           cc = coef(mm)
           se = stderror(mm)
           tt = cc ./ se
           p = ccdf.(Ref(FDist(1, dof_residual(mm))), abs2.(tt))
           ci = se*quantile(TDist(dof_residual(mm)), (1-level)/2)
           levstr = isinteger(level*100) ? string(Integer(level*100)) : string(level*100)
           ct = AxisIndicesArray(
               hcat(cc,se,tt,p,cc+ci,cc-ci),
               (coefnames(mm),
               ["Estimate","Std. Error","t value","Pr(>|t|)","Lower $levstr%","Upper $levstr%"])
           )
       end
coefarray (generic function with 1 method)

julia> ols = lm(@formula(Y ~ X), DataFrame(X=[1,2,3], Y=[2,4,7]));

julia> cfa = coefarray(ols)
2-dimensional AxisIndicesArray{Float64,2,Array{Float64,2}...}
                   Estimate   Std. Error       t value     Pr(>|t|)     Lower 95%    Upper 95%
  (Intercept)   -0.66666667   0.62360956   -1.06904497   0.47876359   -8.59037747   7.25704413
            X           2.5   0.28867513    8.66025404    0.0731864   -1.16796536   6.16796536

```

But we can do better. Let's use the underlying `pretty_array` method to get this into shape.
```julia
julia> using PrettyTables

ctf = array_text_format = TextFormat(
    up_right_corner = ' ',
    up_left_corner = ' ',
    bottom_left_corner=' ',
    bottom_right_corner= ' ',
    up_intersection= '─',
    left_intersection= ' ',
    right_intersection= ' ',
    middle_intersection= '─',
    bottom_intersection= '─',
    column= ' ',
    hlines=[ :begin, :header, :end]
    #    row= ' ',
)

julia> pretty_array(cfa; tf=ctf)
 ──────────────────────────────────────────────────────────────────────────────────────────────
                   Estimate   Std. Error       t value     Pr(>|t|)     Lower 95%    Upper 95%
 ──────────────────────────────────────────────────────────────────────────────────────────────
  (Intercept)   -0.66666667   0.62360956   -1.06904497   0.47876359   -8.59037747   7.25704413
            X           2.5   0.28867513    8.66025404    0.0731864   -1.16796536   6.16796536
 ──────────────────────────────────────────────────────────────────────────────────────────────
```

This looks pretty good but the nicest part is that we can now treat this as a typical matrix.
```julia
julia> cfa[1,"Estimate"]
-0.6666666666666738

julia> cfa[1:2,1:2]
2-dimensional AxisIndicesArray{Float64,2,Array{Float64,2}...}
                Estimate   Std. Error
  (Intercept)     -0.667        0.624
            X        2.5        0.289
```

Because keys and indices are bound together we don't lose track of what each element is when we index.
```julia
julia> cfa[1,:]
1-dimensional AxisIndicesArray{Float64,1,Array{Float64,1}...}

    Estimate   -0.667
  Std. Error    0.624
     t value   -1.069
    Pr(>|t|)    0.479
   Lower 95%    -8.59
   Upper 95%    7.257

```

## Automating the table

We can actually do even better if this format should always be the default by making a new axis type and redefining the `coefarray` method.
The following will result in any array with a `CoefHeader` printing exactly how we'd like it to by default.
Note that this is a quick and dirty way of getting a new axis.
See `TimeAxis Guide` for a better guide on making an axis.
```julia
julia> struct CoefHeader <: AbstractAxis{String,Int,Vector{String},Base.OneTo{Int}} end

julia> Base.keys(::CoefHeader) = ["Estimate","Std. Error","t value","Pr(>|t|)","Lower 95%","Upper 95%"]

julia> Base.values(::CoefHeader) = Base.OneTo(5)

julia> AxisIndices.text_format(axis, ::CoefHeader) = ctf

julia> AxisIndices.unsafe_reconstruct(::CoefHeader, args...) = CoefHeader()

julia> function coefarray(mm::StatsModels.TableRegressionModel; level::Real=0.95)
           cc = coef(mm)
           se = stderror(mm)
           tt = cc ./ se
           p = ccdf.(Ref(FDist(1, dof_residual(mm))), abs2.(tt))
           ci = se*quantile(TDist(dof_residual(mm)), (1-level)/2)
           levstr = isinteger(level*100) ? string(Integer(level*100)) : string(level*100)
           ct = AxisIndicesArray(
               hcat(cc,se,tt,p,cc+ci,cc-ci),
               (coefnames(mm),
               CoefHeader())
           )
       end;

julia> cfa = coefarray(ols)
2-dimensional AxisIndicesArray{Float64,2,Array{Float64,2}...}
 ──────────────────────────────────────────────────────────────────────────────────────────────
                   Estimate   Std. Error       t value     Pr(>|t|)     Lower 95%    Upper 95%
 ──────────────────────────────────────────────────────────────────────────────────────────────
  (Intercept)   -0.66666667   0.62360956   -1.06904497   0.47876359   -8.59037747   7.25704413
            X           2.5   0.28867513    8.66025404    0.0731864   -1.16796536   6.16796536
 ──────────────────────────────────────────────────────────────────────────────────────────────

```
