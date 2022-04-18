@testset "test_dot.jl" begin
    a = Dualization.CanonicalVector{Int}(1, 3)
    @test collect(a) == [1, 0, 0]
    b = Dualization.CanonicalVector{Int}(2, 3)
    @test collect(b) == [0, 1, 0]
    set = MOI.PositiveSemidefiniteConeTriangle(2)
    @test MOI.Utilities.set_dot(a, b, set) == 0
    @test MOI.Utilities.set_dot(a, a, set) == 1
    @test MOI.Utilities.set_dot(b, b, set) == 2
    a = Dualization.CanonicalVector{Int}(1, 4)
    b = Dualization.CanonicalVector{Int}(2, 4)
    c = Dualization.CanonicalVector{Int}(3, 4)
    set = MOI.RootDetConeTriangle(2)
    @test MOI.Utilities.set_dot(a, b, set) == 0
    @test MOI.Utilities.set_dot(b, c, set) == 0
    @test MOI.Utilities.set_dot(c, a, set) == 0
    @test MOI.Utilities.set_dot(a, a, set) == 1
    @test MOI.Utilities.set_dot(b, b, set) == 1
    @test MOI.Utilities.set_dot(c, c, set) == 2
    set = MOI.PositiveSemidefiniteConeSquare(2)
    @test MOI.Utilities.set_dot(a, b, set) == 0
    @test MOI.Utilities.set_dot(b, c, set) == 0
    @test MOI.Utilities.set_dot(c, a, set) == 0
    @test MOI.Utilities.set_dot(a, a, set) == 1
    @test MOI.Utilities.set_dot(b, b, set) == 1
    @test MOI.Utilities.set_dot(c, c, set) == 1
end
