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
    @test Dualization.dual_set(MOI.GreaterThan(0.0)) == greater_than_Float64
    @test Dualization.dual_set(MOI.GreaterThan(1.0)) == greater_than_Float64
    @test Dualization.dual_set(MOI.GreaterThan(-1.0)) == greater_than_Float64
    @test Dualization.dual_set(MOI.GreaterThan(0)) == greater_than_Int64
    @test Dualization.dual_set(MOI.GreaterThan(1)) == greater_than_Int64
    @test Dualization.dual_set(MOI.GreaterThan(-1)) == greater_than_Int64

    # LessThan
    @test Dualization.dual_set(MOI.LessThan(0.0)) == less_than_Float64
    @test Dualization.dual_set(MOI.LessThan(1.0)) == less_than_Float64
    @test Dualization.dual_set(MOI.LessThan(-1.0)) == less_than_Float64
    @test Dualization.dual_set(MOI.LessThan(0)) == less_than_Int64
    @test Dualization.dual_set(MOI.LessThan(1)) == less_than_Int64
    @test Dualization.dual_set(MOI.LessThan(-1)) == less_than_Int64

    # EqualTo
    @test Dualization.dual_set(MOI.EqualTo(0.0)) == nothing
    @test Dualization.dual_set(MOI.EqualTo(1.0)) == nothing
    @test Dualization.dual_set(MOI.EqualTo(-1.0)) == nothing
    @test Dualization.dual_set(MOI.EqualTo(0)) == nothing
    @test Dualization.dual_set(MOI.EqualTo(1)) == nothing
    @test Dualization.dual_set(MOI.EqualTo(-1)) == nothing

    # Nonpositives
    @test Dualization.dual_set(nonpositives_3) == nonpositives_3
    @test Dualization.dual_set(nonpositives_4) == nonpositives_4
    
    # Nonnegatives
    @test Dualization.dual_set(nonnegatives_3) == nonnegatives_3
    @test Dualization.dual_set(nonnegatives_4) == nonnegatives_4

    # Zeros
    @test Dualization.dual_set(zeros_3) == nothing
    @test Dualization.dual_set(zeros_4) == nothing
    
end