# IEC 60076-7 continuous-time thermal model (ModelingToolkit v11)
#
# Time unit: minutes  (matches IEC convention and spec field units)
# Temperature unit: °C / K  (additive, so interchangeable in rise equations)

# ---------------------------------------------------------------------------
# Steady-state helpers — pure Julia, no MTK
# ---------------------------------------------------------------------------

"""
    _steady_state(s::TransformerSpec, K) -> NamedTuple

Return the IEC 60076-7 steady-state temperatures for a two-winding transformer
at per-unit load `K`.  Fields: `Δθ_o`, `W`, `O`.
"""
function _steady_state(s::TransformerSpec, K::Float64)
    R = s.P_cu / s.P_fe
    o = s.oil
    Δθ_or_eff = s.scale_amb ? o.Δθ_or : o.Δθ_or + o.Δθ_amb
    Δθ_o_ss = Δθ_or_eff * ((1 + K^2 * R) / (1 + R))^o.x
    g = s.H * s.g_r * K^o.y
    W_ss = o.k₂₁ * g
    O_ss = (o.k₂₁ - 1) * g
    return (; Δθ_o = Δθ_o_ss, W = W_ss, O = O_ss)
end

"""
    _star_circuit_losses(s::ThreeWindingSpec) -> (P_ll_lv, P_ll_mv, P_ll_hv)

Recover the individual winding load losses from the pairwise short-circuit
measurements stored in `s`, using the IEC star-circuit decomposition.
"""
function _star_circuit_losses(s::ThreeWindingSpec)
    c₁ = (s.mv.S_r / s.hv.S_r)^2
    c₂ = (s.lv.S_r / s.mv.S_r)^2
    P_hv = (0.5 / c₁) * (s.P_ll_hv_mv - (1 / c₂) * s.P_ll_mv_lv + (1 / c₂) * s.P_ll_hv_lv)
    P_mv = (0.5 / c₂) * (c₂ * s.P_ll_hv_mv - s.P_ll_hv_lv + s.P_ll_mv_lv)
    P_lv = 0.5 * (s.P_ll_hv_lv - c₂ * s.P_ll_hv_mv + s.P_ll_mv_lv)
    return (P_lv, P_mv, P_hv)
end

"""
    _steady_state(s::ThreeWindingSpec, K_lv, K_mv, K_hv) -> NamedTuple

Return IEC 60076-7 steady-state temperatures for a three-winding transformer.
Fields: `Δθ_o`, `W_lv`, `O_lv`, `W_mv`, `O_mv`, `W_hv`, `O_hv`.
"""
function _steady_state(s::ThreeWindingSpec, K_lv::Float64, K_mv::Float64, K_hv::Float64)
    (P_ll_lv, P_ll_mv, P_ll_hv) = _star_circuit_losses(s)
    P_load_total = P_ll_lv + P_ll_mv + P_ll_hv
    R = P_load_total / s.P_fe
    o = s.oil

    K_oil_sq = (P_ll_lv * K_lv^2 + P_ll_mv * K_mv^2 + P_ll_hv * K_hv^2) / P_load_total
    Δθ_o_ss = o.Δθ_or * ((1 + K_oil_sq * R) / (1 + R))^o.x

    function winding_ss(w::WindingSpec, K::Float64)
        g = w.H * w.g_r * K^o.y
        return (W = o.k₂₁ * g, O = (o.k₂₁ - 1) * g)
    end

    lv_ss = winding_ss(s.lv, K_lv)
    mv_ss = winding_ss(s.mv, K_mv)
    hv_ss = winding_ss(s.hv, K_hv)

    return (;
        Δθ_o = Δθ_o_ss,
        W_lv = lv_ss.W,
        O_lv = lv_ss.O,
        W_mv = mv_ss.W,
        O_mv = mv_ss.O,
        W_hv = hv_ss.W,
        O_hv = hv_ss.O,
    )
end

# ---------------------------------------------------------------------------
# System builders
# ---------------------------------------------------------------------------

function _two_winding_system(s::TransformerSpec)
    R = s.P_cu / s.P_fe
    o = s.oil
    # Ambient handling: power transformer adds fixed offset; distribution folds
    # Δθ_amb into the rated top-oil rise pre-factor (load-scaled).
    Δθ_or_eff = s.scale_amb ? o.Δθ_or : o.Δθ_or + o.Δθ_amb
    Δθ_amb_offset = s.scale_amb ? o.Δθ_amb : 0.0

    @variables begin
        Δθ_o(t) = 0.0
        W(t) = 0.0
        O_state(t) = 0.0
        K(t), [input = true]
        θ_a(t), [input = true]
        θ_oil(t)
        θ_H(t)
    end

    Δθ_o∞ = Δθ_or_eff * ((1 + K^2 * R) / (1 + R))^o.x
    g = s.H * s.g_r * K^o.y
    W∞ = o.k₂₁ * g
    O∞ = (o.k₂₁ - 1) * g
    θ_a_eff = θ_a + Δθ_amb_offset

    eqs = [
        D(Δθ_o) ~ (Δθ_o∞ - Δθ_o) / (o.k₁₁ * o.τ_oil),
        D(W) ~ (W∞ - W) / (o.k₂₂ * s.τ_w),
        D(O_state) ~ (O∞ - O_state) / (o.τ_oil / o.k₂₂),
        θ_oil ~ θ_a_eff + Δθ_o,
        θ_H ~ θ_oil + W - O_state - o.Δθ_end,
    ]

    sys = InputSystem(eqs, t; name = :thermal)
    return MTK.mtkcompile(sys; inputs = [K, θ_a])
end

function _three_winding_system(s::ThreeWindingSpec)
    (P_ll_lv, P_ll_mv, P_ll_hv) = _star_circuit_losses(s)
    P_load_total = P_ll_lv + P_ll_mv + P_ll_hv
    R = P_load_total / s.P_fe
    o = s.oil
    lv, mv, hv = s.lv, s.mv, s.hv

    @variables begin
        Δθ_o(t) = 0.0
        W_lv(t) = 0.0
        O_lv(t) = 0.0
        W_mv(t) = 0.0
        O_mv(t) = 0.0
        W_hv(t) = 0.0
        O_hv(t) = 0.0
        K_lv(t), [input = true]
        K_mv(t), [input = true]
        K_hv(t), [input = true]
        θ_a(t), [input = true]
        θ_oil(t)
        θ_H_lv(t)
        θ_H_mv(t)
        θ_H_hv(t)
    end

    K_oil_sq = (P_ll_lv * K_lv^2 + P_ll_mv * K_mv^2 + P_ll_hv * K_hv^2) / P_load_total
    Δθ_o∞ = o.Δθ_or * ((1 + K_oil_sq * R) / (1 + R))^o.x

    g_lv = lv.H * lv.g_r * K_lv^o.y
    g_mv = mv.H * mv.g_r * K_mv^o.y
    g_hv = hv.H * hv.g_r * K_hv^o.y
    W_lv∞ = o.k₂₁ * g_lv
    O_lv∞ = (o.k₂₁ - 1) * g_lv
    W_mv∞ = o.k₂₁ * g_mv
    O_mv∞ = (o.k₂₁ - 1) * g_mv
    W_hv∞ = o.k₂₁ * g_hv
    O_hv∞ = (o.k₂₁ - 1) * g_hv

    eqs = [
        D(Δθ_o) ~ (Δθ_o∞ - Δθ_o) / (o.k₁₁ * o.τ_oil),
        D(W_lv) ~ (W_lv∞ - W_lv) / (o.k₂₂ * lv.τ_w),
        D(O_lv) ~ (O_lv∞ - O_lv) / (o.τ_oil / o.k₂₂),
        D(W_mv) ~ (W_mv∞ - W_mv) / (o.k₂₂ * mv.τ_w),
        D(O_mv) ~ (O_mv∞ - O_mv) / (o.τ_oil / o.k₂₂),
        D(W_hv) ~ (W_hv∞ - W_hv) / (o.k₂₂ * hv.τ_w),
        D(O_hv) ~ (O_hv∞ - O_hv) / (o.τ_oil / o.k₂₂),
        θ_oil ~ θ_a + o.Δθ_amb + Δθ_o,
        θ_H_lv ~ θ_oil + W_lv - O_lv - o.Δθ_end,
        θ_H_mv ~ θ_oil + W_mv - O_mv - o.Δθ_end,
        θ_H_hv ~ θ_oil + W_hv - O_hv - o.Δθ_end,
    ]

    sys = InputSystem(eqs, t; name = :thermal)
    return MTK.mtkcompile(sys; inputs = [K_lv, K_mv, K_hv, θ_a])
end

# ---------------------------------------------------------------------------
# Public dispatch
# ---------------------------------------------------------------------------

"""
    thermal_system(tr) -> InputSystem

Build and compile the IEC 60076-7 continuous-time thermal ODE system for
transformer `tr`.  Returns a compiled `InputSystem` ready for use with
`ODEProblem`.

Time unit: **minutes**.  Inputs `K` (per-unit load) and `θ_a` (ambient °C)
are fed via `Input` objects at solve time.

# Example
```julia
tr  = PowerTransformer{ONAN}(P_fe=100.0, P_cu=5000.0, I_r=400.0)
sys = thermal_system(tr)
u0  = initial_conditions(sys, tr, ColdStart())
prob = ODEProblem(sys, u0, (0.0, 1440.0))   # 24 h = 1440 min
K_in  = Input(sys.K,   [1.0, 1.0], [0.0, 1440.0])
θ_in  = Input(sys.θ_a, [20.0, 20.0], [0.0, 1440.0])
sol   = solve(prob, Tsit5(); inputs=[K_in, θ_in])
```
"""
thermal_system(tr::PowerTransformer) = _two_winding_system(spec(tr))
thermal_system(tr::DistributionTransformer) = _two_winding_system(spec(tr))
thermal_system(tr::ThreeWindingTransformer) = _three_winding_system(spec(tr))

# ---------------------------------------------------------------------------
# Initial conditions
# ---------------------------------------------------------------------------

"""
    initial_conditions(sys, tr, state) -> Vector{Pair}

Return a `Vector{Pair}` mapping state variables of `sys` to their initial
values, suitable for passing directly to `ODEProblem`.

# Methods

- `initial_conditions(sys, tr, ColdStart())` — all states zero (cold start).
- `initial_conditions(sys, tr, InitialLoad(K))` — steady state at load `K`.
- `initial_conditions(sys, tr, InitialTopOil(θ_oil); θ_a_0)` — known top-oil
  temperature, windings at rest.
"""
function initial_conditions(
    sys::InputSystem,
    ::Union{PowerTransformer,DistributionTransformer},
    ::ColdStart,
)
    return [sys.Δθ_o => 0.0, sys.W => 0.0, sys.O_state => 0.0]
end

function initial_conditions(sys::InputSystem, ::ThreeWindingTransformer, ::ColdStart)
    return [
        sys.Δθ_o => 0.0,
        sys.W_lv => 0.0,
        sys.O_lv => 0.0,
        sys.W_mv => 0.0,
        sys.O_mv => 0.0,
        sys.W_hv => 0.0,
        sys.O_hv => 0.0,
    ]
end

function initial_conditions(
    sys::InputSystem,
    tr::Union{PowerTransformer,DistributionTransformer},
    init::InitialLoad,
)
    ss = _steady_state(spec(tr), init.K)
    return [sys.Δθ_o => ss.Δθ_o, sys.W => ss.W, sys.O_state => ss.O]
end

function initial_conditions(
    sys::InputSystem,
    tr::ThreeWindingTransformer,
    init::InitialLoad,
)
    K = init.K
    ss = _steady_state(spec(tr), K, K, K)
    return [
        sys.Δθ_o => ss.Δθ_o,
        sys.W_lv => ss.W_lv,
        sys.O_lv => ss.O_lv,
        sys.W_mv => ss.W_mv,
        sys.O_mv => ss.O_mv,
        sys.W_hv => ss.W_hv,
        sys.O_hv => ss.O_hv,
    ]
end

function initial_conditions(
    sys::InputSystem,
    tr::Union{PowerTransformer,DistributionTransformer},
    init::InitialTopOil;
    θ_a_0::Real,
)
    s = spec(tr)
    θ_a_eff = s.scale_amb ? θ_a_0 + s.oil.Δθ_amb : θ_a_0
    Δθ_o = init.θ_oil - θ_a_eff
    return [sys.Δθ_o => Δθ_o, sys.W => 0.0, sys.O_state => 0.0]
end

function initial_conditions(
    sys::InputSystem,
    tr::ThreeWindingTransformer,
    init::InitialTopOil;
    θ_a_0::Real,
)
    s = spec(tr)
    Δθ_o = init.θ_oil - (θ_a_0 + s.oil.Δθ_amb)
    return [
        sys.Δθ_o => Δθ_o,
        sys.W_lv => 0.0,
        sys.O_lv => 0.0,
        sys.W_mv => 0.0,
        sys.O_mv => 0.0,
        sys.W_hv => 0.0,
        sys.O_hv => 0.0,
    ]
end
