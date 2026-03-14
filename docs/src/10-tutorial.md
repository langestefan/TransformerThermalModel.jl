# Tutorial

This page walks through the full workflow: building a transformer, constructing
the thermal ODE system, setting initial conditions, and solving for temperatures
over time.

---

## Setup

```@example tutorial
using TransformerThermalModel
using OrdinaryDiffEq
nothing  # hide
```

---

## 1. Construct a transformer

Each transformer type has a keyword-argument constructor that merges nameplate
data with the IEC 60076-7 defaults for the chosen cooling class.

```@example tutorial
tr = PowerTransformer{ONAN}(P_fe = 100.0, P_cu = 5000.0, I_r = 400.0)
```

Any default can be overridden at construction time:

```@example tutorial
tr_onaf = PowerTransformer{ONAF}(P_fe = 100.0, P_cu = 5000.0, I_r = 400.0, τ_w = 12.0)
```

---

## 2. Build the thermal ODE system

[`thermal_system`](@ref) returns a compiled `InputSystem` (a
[ModelingToolkitInputs.jl](https://github.com/JuliaSMLM/ModelingToolkitInputs.jl)
wrapper around a [ModelingToolkit.jl](https://docs.sciml.ai/ModelingToolkit/stable/)
`System`).  Time is in **minutes**.

```@example tutorial
sys = thermal_system(tr);
nothing  # hide
```

The system has three ODE states and two observed outputs:

| Variable      | Description                           |
|---------------|---------------------------------------|
| `sys.Δθ_o`    | Top-oil temperature rise (K)          |
| `sys.W`       | Winding hot-spot component (K)        |
| `sys.O_state` | Oil hot-spot correction component (K) |
| `sys.θ_oil`   | Top-oil temperature (°C) — observed   |
| `sys.θ_H`     | Hot-spot temperature (°C) — observed  |

Inputs `sys.K` (per-unit load) and `sys.θ_a` (ambient °C) are fed via
`Input` objects at solve time.

---

## 3. Set initial conditions

Three strategies are available.  All return a `Vector{Pair}` ready for
`ODEProblem`:

```@example tutorial
# Cold start — all states zero (transformer just energised at ambient)
u0_cold = initial_conditions(sys, tr, ColdStart())
```

```@example tutorial
# Warm start at a known load — states at the K = 0.8 steady state
u0_load = initial_conditions(sys, tr, InitialLoad(0.8))
```

```@example tutorial
# Warm start at a known top-oil temperature, windings at rest
u0_toil = initial_conditions(sys, tr, InitialTopOil(55.0); θ_a_0 = 20.0)
```

---

## 4. Solve

Construct an `ODEProblem`, then call `solve` with `Input` objects that carry
the time-series load and ambient profiles:

```@example tutorial
θ_a   = 20.0     # °C, constant ambient
K     = 1.0      # rated load
tspan = (0.0, 1440.0)   # 24 h = 1440 min

u0   = initial_conditions(sys, tr, ColdStart())
prob = ODEProblem(sys, u0, tspan)

K_in = Input(sys.K,   [K,   K],     [0.0, tspan[2]])
θ_in = Input(sys.θ_a, [θ_a, θ_a],  [0.0, tspan[2]])

sol = solve(prob, Tsit5(); inputs = [K_in, θ_in])
```

---

## 5. Read results

The solution supports continuous interpolation and symbolic indexing:

```@example tutorial
# Top-oil and hot-spot at t = 12 h (720 min)
θ_oil_12h = sol(720.0; idxs = sys.θ_oil)
```

```@example tutorial
θ_H_12h = sol(720.0; idxs = sys.θ_H)
```

```@example tutorial
# Final values at t = 24 h
θ_oil_24h = sol(tspan[2]; idxs = sys.θ_oil)
```

```@example tutorial
θ_H_24h = sol(tspan[2]; idxs = sys.θ_H)
```

---

## 6. Variable load profile

Pass as many time points as needed.  The solver stops at every `Input`
time point and updates the parameter exactly:

```@example tutorial
# Step from 0 → 1 p.u. at t = 60 min, back to 0.5 p.u. at t = 720 min
K_times  = [0.0,  60.0,  720.0, tspan[2]]
K_values = [0.0,   1.0,    0.5,      0.5]

K_in2 = Input(sys.K,   K_values,       K_times)
θ_in2 = Input(sys.θ_a, fill(θ_a, 4),  K_times)

sol2 = solve(prob, Tsit5(); inputs = [K_in2, θ_in2])
sol2(tspan[2]; idxs = sys.θ_H)
```

---

## 7. Plotting results

Use [CairoMakie.jl](https://docs.makie.org/stable/) to visualise the temperature profiles.
The example below uses the variable-load solution `sol2` from the previous section.

```@example tutorial
using CairoMakie

t_h = sol2.t ./ 60    # convert minutes → hours

fig = Figure(size = (800, 480))
ax = Axis(fig[1, 1];
    xlabel = "Time (h)",
    ylabel = "Temperature (°C)",
    title  = "IEC 60076-7 Thermal Response — Variable Load",
)

for obs in [sys.θ_H, sys.θ_oil]
    lines!(ax, t_h, sol2(sol2.t; idxs = obs).u; linewidth = 2, label = string(obs))
end
hlines!(ax, [98.0]; color = :firebrick, linewidth = 1, linestyle = :dot, label = "Hot-spot limit")
hlines!(ax, [90.0]; color = :steelblue, linewidth = 1, linestyle = :dot, label = "Top-oil limit")

axislegend(ax; position = :rb)
fig
```

---

## 8. Three-winding transformer

The API is identical for `ThreeWindingTransformer`.  Each winding requires a
[`WindingSpec`](@ref) with its own nameplate ratings.  There are three
per-unit load inputs (`K_lv`, `K_mv`, `K_hv`) instead of one:

```@example threewinding
using TransformerThermalModel
using OrdinaryDiffEq

lv = WindingSpec(I_r = 1649.6, S_r = 30.0,  g_r = 25.4, τ_w = 10.0, H = 1.3)
mv = WindingSpec(I_r = 1099.7, S_r = 100.0, g_r = 18.6, τ_w = 10.0, H = 1.3)
hv = WindingSpec(I_r = 384.9,  S_r = 100.0, g_r = 17.6, τ_w = 10.0, H = 1.3)

tr3 = ThreeWindingTransformer{ONAN}(
    P_fe       = 51740.0,
    lv         = lv,
    mv         = mv,
    hv         = hv,
    P_ll_hv_lv = 184439.0,
    P_ll_hv_mv =  93661.0,
    P_ll_mv_lv =  46531.0;
    P_ll_total = 329800.0,
)
```

```@example threewinding
sys3  = thermal_system(tr3)
tspan = (0.0, 1440.0)
θ_a   = 20.0

u0   = initial_conditions(sys3, tr3, ColdStart())
prob = ODEProblem(sys3, u0, tspan)

K_lv_in = Input(sys3.K_lv, [0.8, 0.8], [0.0, tspan[2]])
K_mv_in = Input(sys3.K_mv, [1.0, 1.0], [0.0, tspan[2]])
K_hv_in = Input(sys3.K_hv, [0.9, 0.9], [0.0, tspan[2]])
θ_in    = Input(sys3.θ_a,  [θ_a, θ_a], [0.0, tspan[2]])

sol3 = solve(prob, Tsit5(); inputs = [K_lv_in, K_mv_in, K_hv_in, θ_in])
sol3(tspan[2]; idxs = sys3.θ_H_hv)   # HV winding hot-spot at end of simulation
```
