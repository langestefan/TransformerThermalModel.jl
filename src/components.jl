
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
