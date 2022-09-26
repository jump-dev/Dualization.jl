# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

@testset "supported.jl" begin
    @testset "supported_objective" begin
        Dualization.supported_objective(lp1_test()) # ScalarAffineFucntion Objective
        Dualization.supported_objective(lp10_test()) # VariableIndex Objective
        Dualization.supported_objective(qp1_test()) # VariableIndex Objective
        obj_typ_svf = MOI.get(lp1_test(), MOI.ObjectiveFunctionType())
        obj_typ_saf = MOI.get(lp10_test(), MOI.ObjectiveFunctionType())
        obj_typ_qp = MOI.get(qp1_test(), MOI.ObjectiveFunctionType())
        @test Dualization.supported_obj(obj_typ_svf)
        @test Dualization.supported_obj(obj_typ_saf)
        @test Dualization.supported_obj(obj_typ_qp)
    end

    @testset "supported_constraints" begin
        # All supported SAFs
        con_types = MOI.get(lp1_test(), MOI.ListOfConstraintTypesPresent())
        Dualization.supported_constraints(con_types)

        # Intervals Set is not supported
        con_types = MOI.get(lp9_test(), MOI.ListOfConstraintTypesPresent())
        @test_throws ErrorException Dualization.supported_constraints(con_types) # Throws an error if constraint cannot be dualized
    end
end
