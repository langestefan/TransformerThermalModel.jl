```@raw html
---
layout: home

hero:
  name: "TransformerThermalModel.jl"
  text: "Thermal Modelling for Grid Transformers"
  tagline: IEC 60076-7 hot-spot and top-oil temperature calculations for power, distribution, and three-winding transformers.
  image:
    src: /logo.svg
    alt: TransformerThermalModel
  actions:
    - theme: brand
      text: Get Started
      link: /10-tutorial
    - theme: alt
      text: Default Parameters
      link: /20-default-parameters
    - theme: alt
      text: View on GitHub
      link: https://github.com/langestefan/TransformerThermalModel.jl

features:
  - icon: 📐
    title: IEC 60076-7 compliant
    details: Follows the IEC 60076-7 thermal model with standard default parameters for ONAN and ONAF cooling classes.
    link: /15-constants
  - icon: ⚡
    title: Multiple transformer types
    details: Supports PowerTransformer, DistributionTransformer, and ThreeWindingTransformer, each with their own IEC defaults.
    link: /20-default-parameters
  - icon: 🔧
    title: Composable data model
    details: TransformerSpec, OilSpec, and WindingSpec compose cleanly. Defaults merge with nameplate data via Julia's multiple dispatch.
    link: /10-tutorial
---
```

```@raw html
<p style="margin-bottom:2cm"></p>

<div class="vp-doc" style="width:80%; margin:auto">
<h2>What is TransformerThermalModel.jl?</h2>
<p>
<code>TransformerThermalModel.jl</code> is a Julia package for transformer thermal modelling
following the <strong>IEC 60076-7</strong> standard (and the equivalent <strong>IEEE C57.91</strong> guide).
It computes top-oil and hot-spot temperatures under arbitrary load profiles.
</p>
<h2>Quick start</h2>
```

```julia
using TransformerThermalModel
using OrdinaryDiffEq

# One-step construction — nameplate data + IEC defaults merged automatically
tr  = PowerTransformer{ONAN}(P_fe = 800.0, P_cu = 8500.0, I_r = 630.0)

# Build the continuous-time IEC 60076-7 ODE system (time unit: minutes)
sys = thermal_system(tr)

# Solve from a cold start under rated load for 24 h
u0   = initial_conditions(sys, tr, ColdStart())
prob = ODEProblem(sys, u0, (0.0, 1440.0))

K_in = Input(sys.K,   [1.0, 1.0], [0.0, 1440.0])
θ_in = Input(sys.θ_a, [20.0, 20.0], [0.0, 1440.0])

sol = solve(prob, Tsit5(); inputs = [K_in, θ_in])

sol(1440.0; idxs = sys.θ_oil)   # top-oil temperature at t = 24 h
sol(1440.0; idxs = sys.θ_H)     # hot-spot temperature at t = 24 h
```

```@raw html
</div>
```
