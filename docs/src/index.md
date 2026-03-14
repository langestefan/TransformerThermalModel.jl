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
      link: /15-constants
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
    link: /95-reference
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

# One-step construction — nameplate data + IEC defaults merged automatically
tr = PowerTransformer{ONAN}(P_fe = 800.0, P_cu = 8500.0, I_r = 630.0)

# Accessors follow IEC notation
τ_oil(tr)   # → 210.0 min  (ONAN default)
Δθ_or(tr)   # → 60.0 K
g_r(tr)     # → 17.0 K

# Override any default at construction time
tr2 = PowerTransformer{ONAF}(P_fe = 800.0, P_cu = 8500.0, I_r = 630.0, τ_oil = 120.0)
```

```@raw html
</div>
```
