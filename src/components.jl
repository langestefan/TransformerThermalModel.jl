
# ---------------------------------------------------------------------------
# Bushing configuration
# ---------------------------------------------------------------------------

"""Abstract supertype for bushing configurations."""
abstract type BushingConfig end

"""Single bushing per phase."""
struct SingleBushing <: BushingConfig end

"""Double bushing per phase."""
struct DoubleBushing <: BushingConfig end

"""Triangle inside bushing arrangement."""
struct TriangleBushing <: BushingConfig end

# ---------------------------------------------------------------------------
# Transformer side
# ---------------------------------------------------------------------------

"""Abstract supertype for transformer sides."""
abstract type TransformerSide end

"""Primary (source) side of the transformer."""
struct Primary <: TransformerSide end

"""Secondary (load) side of the transformer."""
struct Secondary <: TransformerSide end

# ---------------------------------------------------------------------------
# Vector / winding configuration
# ---------------------------------------------------------------------------

"""Abstract supertype for vector (winding) configurations."""
abstract type VectorConfig end

"""Star (Y) connection."""
struct StarVector <: VectorConfig end

"""Triangle inside (Δ inside) connection."""
struct TriangleInsideVector <: VectorConfig end

"""Triangle outside (Δ outside) connection."""
struct TriangleOutsideVector <: VectorConfig end

# ---------------------------------------------------------------------------
# Transformer kind — abstract tag type for multiple dispatch
# ---------------------------------------------------------------------------

"""
Abstract supertype used to select the correct IEC 60076-7 default parameters
via multiple dispatch on [`default_spec`](@ref).
"""
abstract type TransformerKind end

"""
Power transformer parametrised by cooler type `C <: CoolerType`.
Defaults to `ONAN` when no type parameter is given.

```julia
PowerTransformer{ONAN}(P_fe=100.0, P_cu=5000.0, I_r=400.0)
PowerTransformer{ONAF}(P_fe=100.0, P_cu=5000.0, I_r=400.0)
PowerTransformer(P_fe=100.0, P_cu=5000.0, I_r=400.0)  # → PowerTransformer{ONAN}
```
"""
struct PowerTransformer{C<:CoolerType} <: TransformerKind
    spec::TransformerSpec
end

"""
Distribution transformer (always ONAN; `Δθ_amb` acts as a pre-factor offset
rather than a fixed ambient surcharge).
"""
struct DistributionTransformer <: TransformerKind
    spec::TransformerSpec
end

"""
Three-winding power transformer parametrised by cooler type `C <: CoolerType`.
Defaults to `ONAN` when no type parameter is given.

```julia
ThreeWindingTransformer{ONAN}(P_fe=..., lv=lv, mv=mv, hv=hv, ...)
ThreeWindingTransformer{ONAF}(P_fe=..., lv=lv, mv=mv, hv=hv, ...)
ThreeWindingTransformer(P_fe=..., lv=lv, mv=mv, hv=hv, ...)  # → ThreeWindingTransformer{ONAN}
```
"""
struct ThreeWindingTransformer{C<:CoolerType} <: TransformerKind
    spec::ThreeWindingSpec
end

# ---------------------------------------------------------------------------
# spec accessor and forwarding to AbstractTransformerSpec accessors
# ---------------------------------------------------------------------------

"""Return the resolved spec of a transformer."""
spec(t::TransformerKind) = t.spec

oil(t::TransformerKind) = oil(spec(t))
Δθ_amb(t::TransformerKind) = Δθ_amb(spec(t))
τ_oil(t::TransformerKind) = τ_oil(spec(t))
Δθ_or(t::TransformerKind) = Δθ_or(spec(t))
k₁₁(t::TransformerKind) = k₁₁(spec(t))
k₂₁(t::TransformerKind) = k₂₁(spec(t))
k₂₂(t::TransformerKind) = k₂₂(spec(t))
x(t::TransformerKind) = x(spec(t))
y(t::TransformerKind) = y(spec(t))
Δθ_end(t::TransformerKind) = Δθ_end(spec(t))
windings(t::ThreeWindingTransformer) = windings(spec(t))

# ---------------------------------------------------------------------------
# Pretty-printing
# ---------------------------------------------------------------------------

function _show_oil_tree(io::IO, o::OilSpec, cont::String)
    println(io, cont, "├ τ_oil:  ", o.τ_oil, " min")
    println(io, cont, "├ Δθ_or:  ", o.Δθ_or, " K")
    println(io, cont, "├ Δθ_amb: ", o.Δθ_amb, " K")
    println(io, cont, "├ k₁₁:    ", o.k₁₁)
    println(io, cont, "├ k₂₁:    ", o.k₂₁)
    println(io, cont, "├ k₂₂:    ", o.k₂₂)
    println(io, cont, "├ x:      ", o.x)
    println(io, cont, "├ y:      ", o.y)
    print(io, cont, "└ Δθ_end: ", o.Δθ_end, " K")
end

function _show_winding_tree(io::IO, w::WindingSpec, cont::String)
    println(io, cont, "├ I_r: ", w.I_r, " A")
    println(io, cont, "├ S_r: ", w.S_r, " MVA")
    println(io, cont, "├ g_r: ", w.g_r, " K")
    println(io, cont, "├ τ_w: ", w.τ_w, " min")
    print(io, cont, "└ H:   ", w.H)
end

function Base.show(io::IO, tr::PowerTransformer{C}) where {C}
    s = tr.spec
    if get(io, :compact, false)
        print(
            io,
            "PowerTransformer{",
            C,
            "}(P_fe=",
            s.P_fe,
            " W, P_cu=",
            s.P_cu,
            " W, I_r=",
            s.I_r,
            " A)",
        )
        return
    end
    println(io, "PowerTransformer{", C, "}")
    println(io, "├ P_fe:      ", s.P_fe, " W")
    println(io, "├ P_cu:      ", s.P_cu, " W")
    println(io, "├ I_r:       ", s.I_r, " A")
    println(io, "├ scale_amb: ", s.scale_amb)
    println(io, "├ g_r:       ", s.g_r, " K")
    println(io, "├ τ_w:       ", s.τ_w, " min")
    println(io, "├ H:         ", s.H)
    println(io, "└ oil:")
    _show_oil_tree(io, s.oil, "   ")
end

function Base.show(io::IO, tr::DistributionTransformer)
    s = tr.spec
    if get(io, :compact, false)
        print(
            io,
            "DistributionTransformer(P_fe=",
            s.P_fe,
            " W, P_cu=",
            s.P_cu,
            " W, I_r=",
            s.I_r,
            " A)",
        )
        return
    end
    println(io, "DistributionTransformer")
    println(io, "├ P_fe:      ", s.P_fe, " W")
    println(io, "├ P_cu:      ", s.P_cu, " W")
    println(io, "├ I_r:       ", s.I_r, " A")
    println(io, "├ scale_amb: ", s.scale_amb)
    println(io, "├ g_r:       ", s.g_r, " K")
    println(io, "├ τ_w:       ", s.τ_w, " min")
    println(io, "├ H:         ", s.H)
    println(io, "└ oil:")
    _show_oil_tree(io, s.oil, "   ")
end

function Base.show(io::IO, tr::ThreeWindingTransformer{C}) where {C}
    s = tr.spec
    if get(io, :compact, false)
        print(
            io,
            "ThreeWindingTransformer{",
            C,
            "}(P_fe=",
            s.P_fe,
            " W, P_ll_total=",
            s.P_ll_total,
            " W)",
        )
        return
    end
    println(io, "ThreeWindingTransformer{", C, "}")
    println(io, "├ P_fe:       ", s.P_fe, " W")
    println(io, "├ P_ll_hv_lv: ", s.P_ll_hv_lv, " W")
    println(io, "├ P_ll_hv_mv: ", s.P_ll_hv_mv, " W")
    println(io, "├ P_ll_mv_lv: ", s.P_ll_mv_lv, " W")
    println(io, "├ P_ll_total: ", s.P_ll_total, " W")
    println(io, "├ lv:")
    _show_winding_tree(io, s.lv, "│  ")
    println(io)
    println(io, "├ mv:")
    _show_winding_tree(io, s.mv, "│  ")
    println(io)
    println(io, "├ hv:")
    _show_winding_tree(io, s.hv, "│  ")
    println(io)
    println(io, "└ oil:")
    _show_oil_tree(io, s.oil, "   ")
end
