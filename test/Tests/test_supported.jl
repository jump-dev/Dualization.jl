@testset "supported.jl" begin

    @testset "supported_objective" begin
        Dualization.supported_objective(lp1_test()) # ScalarAffineFucntion Objective
        Dualization.supported_objective(lp10_test()) # SingleVariable Objective
        @test_throws ErrorException Dualization.supported_objective(qp1_test()) # SingleVariable Objective
    end

    @testset "supported_constraints" begin
        # All supported SAFs
        con_types = MOI.get(lp1_test(), MOI.ListOfConstraints())
        Dualization.supported_constraints(con_types) 

        # Intervals Set is not supported
        con_types = MOI.get(lp9_test(), MOI.ListOfConstraints())
        @test_throws ErrorException Dualization.supported_constraints(con_types) # Throws an error if constraint cannot be dualized
    end
    
end