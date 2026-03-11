# SPDX-FileCopyrightText: Contributors to the Transformer Thermal Model project
#
# SPDX-License-Identifier: MPL-2.0

import ModelingToolkit as MTK

# ---------------------------------------------------------------------------
# IEC 60076-7 exponential thermal model — ETDRK2 discretization
#
# States  x = [Δθ_o, W, O]  (ordering determined by MTK, tracked via indices)
#   Δθ_o : top-oil temperature rise above effective ambient             [K]
#   W    : hot-spot winding component                                   [K]
#   O    : hot-spot oil component                                       [K]
#   hot-spot gradient above top-oil: δθ_H = W − O
#
# Input   u = [K]
#   K    : per-unit load current                                        [-]
#
# Parameters p = [τ_oil, τ_w, Δθ_or_eff, g_r_eff, k₁₁, k₂₁, k₂₂, x_oil, y_wdg, R]
#   Δθ_or_eff = Δθ_or              (power transformer)
#             = Δθ_or + Δθ_amb     (distribution transformer)
#   g_r_eff   = H · g_r
#
# The ODE is semilinear: dx/dt = L·x + N(K, p) with diagonal L
#   L = diag(−1/(k₁₁τ_oil), −1/(k₂₂τ_w), −k₂₂/τ_oil)
#   N(K,p) drives Δθ_o → Δθ_o∞, W → k₂₁·g, O → (k₂₁−1)·g
#   g = g_r_eff · K^y_wdg,  Δθ_o∞ = Δθ_or_eff·((1+K²R)/(1+R))^x_oil
#
# ETDRK2 step (exact for piecewise-constant K over each interval Δt):
#   aᵢ     = exp(λᵢ·Δt)   where λᵢ are the diagonal entries of L
#   x[k+1] = x∞ + (x[k] − x∞) · a,   x∞ = steady-state target
# ---------------------------------------------------------------------------

function _build_thermal_model()
    MTK.@parameters t τ_oil_p τ_w_p Δθ_or_eff_p g_r_eff_p k₁₁_p k₂₁_p k₂₂_p x_oil_p y_wdg_p R_p
    MTK.@variables Δθ_o(t) W(t) O(t) K(t)
    D = MTK.Differential(t)

    # Steady-state targets (nonlinear in K only — state-independent)
    Δθ_o_inf = Δθ_or_eff_p * ((1 + K^2 * R_p) / (1 + R_p))^x_oil_p
    g = g_r_eff_p * K^y_wdg_p
    W_inf = k₂₁_p * g
    O_inf = (k₂₁_p - 1) * g

    params =
        [τ_oil_p, τ_w_p, Δθ_or_eff_p, g_r_eff_p, k₁₁_p, k₂₁_p, k₂₂_p, x_oil_p, y_wdg_p, R_p]

    # Compile f_inf([K], p) → [Δθ_o∞, W∞, O∞].
    # Built before mtkcompile since targets are state-independent.
    f_inf =
        MTK.build_function([Δθ_o_inf, W_inf, O_inf], [K], params; expression = Val(false))[1]

    # ODE system — used only to recover MTK's internal state ordering.
    eqs = [
        D(Δθ_o) ~ (Δθ_o_inf - Δθ_o) / (k₁₁_p * τ_oil_p),
        D(W) ~ (W_inf - W) / (k₂₂_p * τ_w_p),
        D(O) ~ (O_inf - O) / (τ_oil_p / k₂₂_p),
    ]

    MTK.@named sys = MTK.ODESystem(eqs, t)
    sys = MTK.mtkcompile(sys; inputs = [K])

    sts = MTK.unknowns(sys)
    idx_Δθ_o = findfirst(s -> MTK.getname(s) == :Δθ_o, sts)
    idx_W = findfirst(s -> MTK.getname(s) == :W, sts)
    idx_O = findfirst(s -> MTK.getname(s) == :O, sts)

    return f_inf, idx_Δθ_o, idx_W, idx_O
end

# Compiled model — built once on first use, shared across all calls.
const _THERMAL_MODEL = Ref{Any}(nothing)

function _thermal_model()
    if _THERMAL_MODEL[] === nothing
        _THERMAL_MODEL[] = _build_thermal_model()
    end
    return _THERMAL_MODEL[]
end

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

"""Effective rated top-oil rise: adds Δθ_amb for distribution transformers."""
function _Δθ_or_eff(spec::TransformerSpec)
    return spec.add_surcharge_to_ambient ? spec.Δθ_or : spec.Δθ_or + spec.Δθ_amb
end

"""Effective ambient temperature: adds Δθ_amb offset for power transformers."""
function _ambient_eff(spec::TransformerSpec, ambient::AbstractVector{<:Real})
    return spec.add_surcharge_to_ambient ? ambient .+ spec.Δθ_amb : ambient
end

"""Extract the ODE parameter vector from a `TransformerSpec`."""
function _spec_to_p(spec::TransformerSpec)
    return [
        spec.τ_oil,
        spec.τ_w,
        _Δθ_or_eff(spec),
        spec.H * spec.g_r,
        spec.k₁₁,
        spec.k₂₁,
        spec.k₂₂,
        spec.x_oil,
        spec.y_wdg,
        spec.load_loss / spec.no_load_loss,
    ]
end

"""Initial ODE state (Δθ_o, W, O) from an `InitialState`."""
function _initial_xyz(::TransformerSpec, ::ColdStart, ::Real)
    return 0.0, 0.0, 0.0
end

function _initial_xyz(::TransformerSpec, init::InitialTopOilTemp, θ_a0::Real)
    return init.temp - θ_a0, 0.0, 0.0
end

function _initial_xyz(spec::TransformerSpec, init::InitialLoad, ::Real)
    K = init.load
    τ_oil, τ_w, Δθ_or_eff, g_r_eff, k₁₁, k₂₁, k₂₂, x_oil, y_wdg, R = _spec_to_p(spec)
    Δθ_o_ss = Δθ_or_eff * ((1 + K^2 * R) / (1 + R))^x_oil
    g = g_r_eff * K^y_wdg
    return Δθ_o_ss, k₂₁ * g, (k₂₁ - 1) * g
end

# ---------------------------------------------------------------------------
# ETDRK2 core step
# ---------------------------------------------------------------------------

"""
Single ETDRK2 step for the diagonal semilinear thermal ODE.

Exact for piecewise-constant input K over interval Δt:
  x_new[i] = x∞[i] + (x[i] − x∞[i]) · exp(λᵢ·Δt)
"""
@inline function _etdrk2_step!(
    x_new,
    x,
    f_inf,
    K::Real,
    a_oil::Real,
    a_w::Real,
    a_o::Real,
    p,
    idx_Δθ_o::Int,
    idx_W::Int,
    idx_O::Int,
)
    x_inf = f_inf([K], p)

    x_new[idx_Δθ_o] = x_inf[1] + (x[idx_Δθ_o] - x_inf[1]) * a_oil
    x_new[idx_W] = x_inf[2] + (x[idx_W] - x_inf[2]) * a_w
    x_new[idx_O] = x_inf[3] + (x[idx_O] - x_inf[3]) * a_o

    return x_new
end

# ---------------------------------------------------------------------------
# Simulate
# ---------------------------------------------------------------------------

"""
    simulate(spec, profile[, init]) -> ThermalResult

Run the IEC 60076-7 exponential thermal model for a single-winding transformer.

The ODE is built symbolically with ModelingToolkit and discretized with an
exact ETDRK2 scheme (exact for piecewise-constant load over each interval).
The same step function can be embedded directly in a JuMP optimization model
via [`thermal_step_function`](@ref).

# Arguments
- `spec`: [`TransformerSpec`](@ref) (from `PowerTransformer` or `DistributionTransformer`)
- `profile`: [`InputProfile`](@ref) with uniform time spacing
- `init`: [`InitialState`](@ref) — defaults to [`ColdStart`](@ref)

# Returns
[`ThermalResult`](@ref) with `top_oil` and `hot_spot` temperature profiles [°C].
"""
function simulate(
    spec::TransformerSpec,
    profile::InputProfile,
    init::InitialState = ColdStart(),
)
    n = length(profile.time)
    n >= 2 || throw(ArgumentError("profile must have at least 2 time steps"))

    # Timestep in minutes (profile timestamps are DateTime; diff in milliseconds)
    Δt_ms = Dates.value(profile.time[2] - profile.time[1])
    Δt = Δt_ms / 60_000.0

    # Validate uniform spacing
    for k = 2:(n-1)
        Dates.value(profile.time[k+1] - profile.time[k]) == Δt_ms ||
            throw(ArgumentError("simulate requires uniform time spacing"))
    end

    f_inf, idx_Δθ_o, idx_W, idx_O = _thermal_model()

    # Parameters and effective ambient
    p = _spec_to_p(spec)
    θ_a = _ambient_eff(spec, profile.ambient)

    # Precompute decay factors — depend only on p and Δt, not on K or state
    τ_oil, τ_w, k₁₁, k₂₂ = p[1], p[2], p[5], p[7]
    a_oil = exp(-Δt / (k₁₁ * τ_oil))
    a_w = exp(-Δt / (k₂₂ * τ_w))
    a_o = exp(-Δt * k₂₂ / τ_oil)

    # Initial state in MTK's unknown ordering
    Δθ_o0, W0, O0 = _initial_xyz(spec, init, θ_a[1])
    x = zeros(3)
    x[idx_Δθ_o] = Δθ_o0
    x[idx_W] = W0
    x[idx_O] = O0
    x_new = similar(x)

    # Allocate output
    Δθ_o_vec = Vector{Float64}(undef, n)
    δθ_H_vec = Vector{Float64}(undef, n)

    # Step through profile.
    # Convention: load[k] is the load that was applied during interval (k−1, k),
    # matching the Python reference model. Steps are driven by load[k+1].
    # (load[1] is present but unused; load[n] drives the last step.)
    for k = 1:n
        Δθ_o_vec[k] = x[idx_Δθ_o]
        δθ_H_vec[k] = x[idx_W] - x[idx_O]
        if k < n
            _etdrk2_step!(
                x_new,
                x,
                f_inf,
                profile.load[k+1],
                a_oil,
                a_w,
                a_o,
                p,
                idx_Δθ_o,
                idx_W,
                idx_O,
            )
            x, x_new = x_new, x
        end
    end

    # Absolute temperatures
    θ_oil = θ_a .+ Δθ_o_vec
    θ_H = θ_oil .+ δθ_H_vec .- spec.Δθ_end

    return ThermalResult(profile.time, θ_oil, θ_H)
end

# ---------------------------------------------------------------------------
# JuMP interface helpers
# ---------------------------------------------------------------------------

"""
    thermal_step_function(Δt) -> f_disc

Return the ETDRK2-discretized IEC thermal step function for timestep `Δt` [minutes].

The returned function has the signature:
```
f_disc(x, u, p, t) -> x_next
```
where:
- `x`       — state vector in MTK's internal ordering (use [`thermal_state_indices`](@ref))
- `u = [K]` — per-unit load input
- `p`       — parameter vector from [`thermal_params`](@ref)

This is the building block for embedding the transformer thermal model as
constraints in a JuMP optimization model.
"""
function thermal_step_function(Δt::Real)
    f_inf, idx_Δθ_o, idx_W, idx_O = _thermal_model()
    Δt_f = Float64(Δt)
    # Decay factors depend on p (passed at call time), so computed inside the closure.
    # They are independent of K and x, so cache them keyed on p to avoid recomputing
    # across repeated calls with the same parameters.
    last_p = Ref{Any}(nothing)
    cached = Ref{NTuple{3,Float64}}((0.0, 0.0, 0.0))
    return function f_disc(x, u, p, _t)
        if p !== last_p[]
            τ_oil, τ_w, k₁₁, k₂₂ = p[1], p[2], p[5], p[7]
            cached[] = (
                exp(-Δt_f / (k₁₁ * τ_oil)),
                exp(-Δt_f / (k₂₂ * τ_w)),
                exp(-Δt_f * k₂₂ / τ_oil),
            )
            last_p[] = p
        end
        a_oil, a_w, a_o = cached[]
        x_inf = f_inf([u[1]], p)
        # Compute new state values; let Julia infer the element type so this
        # works for both Float64 arrays (simulate) and JuMP variable arrays.
        Δθ_o_new = x_inf[1] + (x[idx_Δθ_o] - x_inf[1]) * a_oil
        W_new = x_inf[2] + (x[idx_W] - x_inf[2]) * a_w
        O_new = x_inf[3] + (x[idx_O] - x_inf[3]) * a_o
        x_new = similar(x, typeof(Δθ_o_new))
        x_new[idx_Δθ_o] = Δθ_o_new
        x_new[idx_W] = W_new
        x_new[idx_O] = O_new
        return x_new
    end
end

"""
    thermal_state_indices() -> (idx_Δθ_o, idx_W, idx_O)

Return the indices of the three thermal state variables in the state vector used
by [`thermal_step_function`](@ref):
- `idx_Δθ_o`: top-oil rise above effective ambient [K]
- `idx_W`:    hot-spot winding component [K]
- `idx_O`:    hot-spot oil component [K]

Hot-spot gradient above top-oil: `δθ_H = x[idx_W] - x[idx_O]`.
"""
function thermal_state_indices()
    _, idx_Δθ_o, idx_W, idx_O = _thermal_model()
    return idx_Δθ_o, idx_W, idx_O
end

"""
    thermal_params(spec) -> Vector{Float64}

Return the ODE parameter vector for `spec`, compatible with [`thermal_step_function`](@ref).

Parameter order: `[τ_oil, τ_w, Δθ_or_eff, g_r_eff, k₁₁, k₂₁, k₂₂, x_oil, y_wdg, R]`

where `Δθ_or_eff = Δθ_or` (power) or `Δθ_or + Δθ_amb` (distribution),
and `g_r_eff = H · g_r`.
"""
thermal_params(spec::TransformerSpec) = _spec_to_p(spec)
