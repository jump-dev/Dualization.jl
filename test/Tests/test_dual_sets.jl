@testset "dual_sets.jl" begin
    greater_than_Float64 = MOI.GreaterThan(0.0)
    greater_than_Int64 = MOI.GreaterThan(0)
    less_than_Float64 = MOI.LessThan(0.0)
    less_than_Int64 = MOI.LessThan(0)
    nonpositives_3 = MOI.Nonpositives(3)
    nonnegatives_3 = MOI.Nonnegatives(3)
    zeros_3 = MOI.Zeros(3)
    nonpositives_4 = MOI.Nonpositives(4)
    nonnegatives_4 = MOI.Nonnegatives(4)
    zeros_4 = MOI.Zeros(4)

    # GreaterThan
    @test MOI.dual_set(MOI.GreaterThan(0.0)) == greater_than_Float64
    @test MOI.dual_set(MOI.GreaterThan(1.0)) == greater_than_Float64
    @test MOI.dual_set(MOI.GreaterThan(-1.0)) == greater_than_Float64
    @test MOI.dual_set(MOI.GreaterThan(0)) == greater_than_Int64
    @test MOI.dual_set(MOI.GreaterThan(1)) == greater_than_Int64
    @test MOI.dual_set(MOI.GreaterThan(-1)) == greater_than_Int64

    # LessThan
    @test MOI.dual_set(MOI.LessThan(0.0)) == less_than_Float64
    @test MOI.dual_set(MOI.LessThan(1.0)) == less_than_Float64
    @test MOI.dual_set(MOI.LessThan(-1.0)) == less_than_Float64
    @test MOI.dual_set(MOI.LessThan(0)) == less_than_Int64
    @test MOI.dual_set(MOI.LessThan(1)) == less_than_Int64
    @test MOI.dual_set(MOI.LessThan(-1)) == less_than_Int64

    # EqualTo
    @test MOI.dual_set(MOI.EqualTo(0.0)) == nothing
    @test MOI.dual_set(MOI.EqualTo(1.0)) == nothing
    @test MOI.dual_set(MOI.EqualTo(-1.0)) == nothing
    @test MOI.dual_set(MOI.EqualTo(0)) == nothing
    @test MOI.dual_set(MOI.EqualTo(1)) == nothing
    @test MOI.dual_set(MOI.EqualTo(-1)) == nothing

    # Nonpositives
    @test MOI.dual_set(nonpositives_3) == nonpositives_3
    @test MOI.dual_set(nonpositives_4) == nonpositives_4
    
    # Nonnegatives
    @test MOI.dual_set(nonnegatives_3) == nonnegatives_3
    @test MOI.dual_set(nonnegatives_4) == nonnegatives_4

    # Zeros
    @test MOI.dual_set(zeros_3) == MOI.Reals(3)
    @test MOI.dual_set(zeros_4) == MOI.Reals(4)

    #SOC
    soc = MOI.SecondOrderCone(2)
    soc3 = MOI.SecondOrderCone(3)
    @test MOI.dual_set(soc) == soc
    @test MOI.dual_set(soc) != soc3
    @test MOI.dual_set(soc3) == soc3

    #RSOC
    rsoc = MOI.RotatedSecondOrderCone(2)
    rsoc3 = MOI.RotatedSecondOrderCone(3)
    @test MOI.dual_set(rsoc) == rsoc
    @test MOI.dual_set(rsoc) != rsoc3
    @test MOI.dual_set(rsoc3) == rsoc3

    #PSD
    psd = MOI.PositiveSemidefiniteConeTriangle(2)
    psd3 = MOI.PositiveSemidefiniteConeTriangle(3)
    @test MOI.dual_set(psd) == psd
    @test MOI.dual_set(psd) != psd3
    @test MOI.dual_set(psd3) == psd3

    # Exponential
    exp = MOI.ExponentialCone()
    dual_exp = MOI.DualExponentialCone()
    @test MOI.dual_set(exp) == dual_exp
    @test MOI.dual_set(exp) != exp
    @test MOI.dual_set(dual_exp) == exp
    @test MOI.dual_set(dual_exp) != dual_exp

    # Power
    pow = MOI.PowerCone(0.3)
    pow4 = MOI.PowerCone(0.4)
    dual_pow = MOI.DualPowerCone(0.3)
    @test MOI.dual_set(pow) == dual_pow
    @test MOI.dual_set(pow) != pow
    @test MOI.dual_set(dual_pow) == pow
    @test MOI.dual_set(dual_pow) != pow4
    @test MOI.dual_set(dual_pow) != dual_pow
end