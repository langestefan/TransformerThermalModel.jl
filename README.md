# TransformerThermalModel.jl

[![Development documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://langestefan.github.io/TransformerThermalModel.jl/dev/)
[![Test workflow status](https://github.com/langestefan/TransformerThermalModel.jl/actions/workflows/Test.yml/badge.svg?branch=main)](https://github.com/langestefan/TransformerThermalModel.jl/actions/workflows/Test.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/langestefan/TransformerThermalModel.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/langestefan/TransformerThermalModel.jl)
[![Lint workflow Status](https://github.com/langestefan/TransformerThermalModel.jl/actions/workflows/Lint.yml/badge.svg?branch=main)](https://github.com/langestefan/TransformerThermalModel.jl/actions/workflows/Lint.yml?query=branch%3Amain)
[![Docs workflow Status](https://github.com/langestefan/TransformerThermalModel.jl/actions/workflows/Docs.yml/badge.svg?branch=main)](https://github.com/langestefan/TransformerThermalModel.jl/actions/workflows/Docs.yml?query=branch%3Amain)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![tested with JET.jl](https://img.shields.io/badge/%F0%9F%9B%A9%EF%B8%8F_tested_with-JET.jl-233f9a)](https://github.com/aviatesk/JET.jl)

TransformerThermalModel.jl is a Julia package for transformer thermal modelling following the **IEC 60076-7** standard (and the equivalent **IEEE C57.91** guide). It computes top-oil and hot-spot temperatures under arbitrary load profiles using a continuous-time ODE system that can be solved with any SciML-compatible solver.

## Features

- **IEC 60076-7 compliant** — implements the standard thermal model with default parameters for ONAN and ONAF cooling classes
- **Multiple transformer types** — supports `PowerTransformer`, `DistributionTransformer`, and `ThreeWindingTransformer`
- **Composable data model** — `TransformerSpec`, `OilSpec`, and `WindingSpec` compose cleanly; defaults merge with nameplate data via Julia's multiple dispatch
- **Continuous-time ODE** — built on [ModelingToolkit.jl](https://docs.sciml.ai/ModelingToolkit/stable/); solve with any ODE solver from the SciML ecosystem
- **Flexible inputs** — arbitrary time-varying load and ambient temperature profiles via [ModelingToolkitInputs.jl](https://github.com/bradcarman/ModelingToolkitInputs.jl)

## Quick start

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

K_in = Input(sys.K,   [1.0, 1.0],   [0.0, 1440.0])
θ_in = Input(sys.θ_a, [20.0, 20.0], [0.0, 1440.0])

sol = solve(prob, Tsit5(); inputs = [K_in, θ_in])

sol(1440.0; idxs = sys.θ_oil)   # top-oil temperature at t = 24 h
sol(1440.0; idxs = sys.θ_H)     # hot-spot temperature at t = 24 h
```

## How to Cite

If you use TransformerThermalModel.jl in your work, please cite using the reference given in [CITATION.cff](https://github.com/langestefan/TransformerThermalModel.jl/blob/main/CITATION.cff).

## Contributing

If you want to make contributions of any kind, please first take a look into our [contributing guide directly on GitHub](docs/src/90-contributing.md).

---

### Contributors

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->
