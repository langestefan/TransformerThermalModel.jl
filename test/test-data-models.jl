# SPDX-FileCopyrightText: Contributors to the Transformer Thermal Model project
#
# SPDX-License-Identifier: MPL-2.0

# ---------------------------------------------------------------------------
# ThermalOverrides
# ---------------------------------------------------------------------------

@testitem "ThermalOverrides default constructor" tags = [:unit, :fast] begin
    using TransformerThermalModel
    ov = ThermalOverrides()
    @test ov.τ_oil === nothing
    @test ov.τ_w === nothing
    @test ov.Δθ_or === nothing
    @test ov.g_r === nothing
    @test ov.H === nothing
    @test ov.k₁₁ === nothing
    @test ov.k₂₁ === nothing
    @test ov.k₂₂ === nothing
    @test ov.x_oil === nothing
    @test ov.y_wdg === nothing
    @test ov.Δθ_end === nothing
    @test ov.Δθ_amb === nothing
end

@testitem "ThermalOverrides keyword constructor" tags = [:unit, :fast] begin
    using TransformerThermalModel
    ov = ThermalOverrides(τ_oil = 180.0, H = 1.5)
    @test ov.τ_oil == 180.0
    @test ov.H == 1.5
    @test ov.τ_w === nothing
    @test ov.Δθ_or === nothing
end

# ---------------------------------------------------------------------------
# PowerTransformer
# ---------------------------------------------------------------------------

@testitem "PowerTransformer ONAN defaults" tags = [:unit, :fast] begin
    using TransformerThermalModel
    spec = PowerTransformer(
        PowerTransformerParams(no_load_loss = 200.0, load_loss = 1000.0, nom_load = 1500.0),
    )
    @test spec.no_load_loss == 200.0
    @test spec.load_loss == 1000.0
    @test spec.nom_load == 1500.0
    @test spec.τ_oil == 210.0
    @test spec.τ_w == 10.0
    @test spec.Δθ_or == 60.0
    @test spec.g_r == 17.0
    @test spec.H == 1.3
    @test spec.k₁₁ == 0.5
    @test spec.k₂₁ == 2.0
    @test spec.k₂₂ == 2.0
    @test spec.x_oil == 0.8
    @test spec.y_wdg == 1.3
    @test spec.Δθ_end == 0.0
    @test spec.Δθ_amb == 0.0
    @test spec.add_surcharge_to_ambient == true
end

@testitem "PowerTransformer ONAF defaults" tags = [:unit, :fast] begin
    using TransformerThermalModel
    spec = PowerTransformer(
        PowerTransformerParams(
            no_load_loss = 200.0,
            load_loss = 1000.0,
            nom_load = 1500.0,
            cooler = ONAF,
        ),
    )
    @test spec.τ_oil == 150.0
    @test spec.τ_w == 7.0
    @test spec.add_surcharge_to_ambient == true
end

@testitem "PowerTransformer overrides" tags = [:unit, :fast] begin
    using TransformerThermalModel
    spec = PowerTransformer(
        PowerTransformerParams(
            no_load_loss = 200.0,
            load_loss = 1000.0,
            nom_load = 1500.0,
            overrides = ThermalOverrides(H = 1.5, Δθ_amb = 5.0),
        ),
    )
    @test spec.H == 1.5
    @test spec.Δθ_amb == 5.0
    @test spec.τ_oil == 210.0  # default unchanged
end

# ---------------------------------------------------------------------------
# DistributionTransformer
# ---------------------------------------------------------------------------

@testitem "DistributionTransformer defaults" tags = [:unit, :fast] begin
    using TransformerThermalModel
    spec = DistributionTransformer(
        DistributionTransformerParams(
            no_load_loss = 800.0,
            load_loss = 5200.0,
            nom_load = 900.0,
        ),
    )
    @test spec.no_load_loss == 800.0
    @test spec.load_loss == 5200.0
    @test spec.nom_load == 900.0
    @test spec.τ_oil == 180.0
    @test spec.τ_w == 4.0
    @test spec.Δθ_or == 60.0
    @test spec.g_r == 23.0
    @test spec.H == 1.2
    @test spec.k₁₁ == 1.0
    @test spec.k₂₁ == 1.0
    @test spec.k₂₂ == 2.0
    @test spec.x_oil == 0.8
    @test spec.y_wdg == 1.6
    @test spec.Δθ_end == 0.0
    @test spec.Δθ_amb == 10.0
    @test spec.add_surcharge_to_ambient == false
end

@testitem "DistributionTransformer overrides" tags = [:unit, :fast] begin
    using TransformerThermalModel
    spec = DistributionTransformer(
        DistributionTransformerParams(
            no_load_loss = 800.0,
            load_loss = 5200.0,
            nom_load = 900.0,
            overrides = ThermalOverrides(τ_oil = 120.0),
        ),
    )
    @test spec.τ_oil == 120.0
    @test spec.τ_w == 4.0  # default unchanged
end

# ---------------------------------------------------------------------------
# WindingSpec
# ---------------------------------------------------------------------------

@testitem "WindingSpec construction" tags = [:unit, :fast] begin
    using TransformerThermalModel
    w = WindingSpec(nom_load = 1000.0, nom_power = 10.0, g_r = 17.0, τ_w = 10.0, H = 1.3)
    @test w.nom_load == 1000.0
    @test w.nom_power == 10.0
    @test w.g_r == 17.0
    @test w.τ_w == 10.0
    @test w.H == 1.3
end

# ---------------------------------------------------------------------------
# ThreeWindingTransformer
# ---------------------------------------------------------------------------

@testitem "ThreeWindingTransformer ONAN defaults" tags = [:unit, :fast] begin
    using TransformerThermalModel
    w = WindingSpec(nom_load = 1000.0, nom_power = 10.0, g_r = 20.0, τ_w = 5.0, H = 1.2)
    spec = ThreeWindingTransformer(
        ThreeWindingTransformerParams(
            no_load_loss = 20.0,
            lv_winding = w,
            mv_winding = w,
            hv_winding = w,
            load_loss_hv_lv = 100.0,
            load_loss_hv_mv = 100.0,
            load_loss_mv_lv = 100.0,
        ),
    )
    @test spec.no_load_loss == 20.0
    @test spec.τ_oil == 210.0
    @test spec.Δθ_or == 60.0
    @test spec.k₁₁ == 0.5
    @test spec.Δθ_amb == 0.0
    @test spec.load_loss_total === nothing
end

@testitem "ThreeWindingTransformer ONAF defaults" tags = [:unit, :fast] begin
    using TransformerThermalModel
    w = WindingSpec(nom_load = 1000.0, nom_power = 10.0, g_r = 20.0, τ_w = 5.0, H = 1.2)
    spec = ThreeWindingTransformer(
        ThreeWindingTransformerParams(
            no_load_loss = 20.0,
            lv_winding = w,
            mv_winding = w,
            hv_winding = w,
            load_loss_hv_lv = 100.0,
            load_loss_hv_mv = 100.0,
            load_loss_mv_lv = 100.0,
            cooler = ONAF,
        ),
    )
    @test spec.τ_oil == 150.0
end

@testitem "ThreeWindingTransformer windings preserved" tags = [:unit, :fast] begin
    using TransformerThermalModel
    lv = WindingSpec(nom_load = 500.0, nom_power = 5.0, g_r = 15.0, τ_w = 4.0, H = 1.1)
    mv = WindingSpec(nom_load = 800.0, nom_power = 8.0, g_r = 18.0, τ_w = 8.0, H = 1.2)
    hv = WindingSpec(nom_load = 1000.0, nom_power = 10.0, g_r = 20.0, τ_w = 10.0, H = 1.3)
    spec = ThreeWindingTransformer(
        ThreeWindingTransformerParams(
            no_load_loss = 20.0,
            lv_winding = lv,
            mv_winding = mv,
            hv_winding = hv,
            load_loss_hv_lv = 80.0,
            load_loss_hv_mv = 90.0,
            load_loss_mv_lv = 70.0,
            load_loss_total = 500.0,
        ),
    )
    @test spec.lv_winding === lv
    @test spec.mv_winding === mv
    @test spec.hv_winding === hv
    @test spec.load_loss_hv_lv == 80.0
    @test spec.load_loss_hv_mv == 90.0
    @test spec.load_loss_mv_lv == 70.0
    @test spec.load_loss_total == 500.0
end
