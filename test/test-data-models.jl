
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
