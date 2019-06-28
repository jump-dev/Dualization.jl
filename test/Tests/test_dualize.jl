@testset "dualize.jl" begin
    function get_dual_model_and_map(primal_model::MOI.ModelLike)
        dual = Dualization.dualize(primal_model)
        return dual.dual_model, dual.primal_dual_map
    end
    
    @testset "lp1_test" begin
    #=
    primal
        min -4x_2 - 1 
    s.t.
        x_1 + 2x_2 <= 3  :y_3
        x_1 >= 1         :y_1
        x_1 >= 3         :y_2

    dual
        max y_1 + 3y_2 + 3y_3 - 1 
    s.t.
        y_1 + y_2 + y_3 == 0    :z_4
        2y_3 == -4              :z_5
        y_1 >= 0                :z_1
        y_2 >= 0                :z_2
        y_3 <= 0                :z_3
    =#
        primal_model = lp1_test()
        dual_model, primal_dual_map = get_dual_model_and_map(primal_model)
        dual_model.objective

        @test dual_model.num_variables_created == 3
    end

    @testset "lp7_test" begin
    #=
    primal
        min -4x1 -3x2 -1
    s.t.
        2x1 + x2 - 3 <= 0  :y_3
        x1 + 2x2 - 3 <= 0  :y_4
        x1 >= 1            :y_1
        x2 >= 0            :y_2

    dual
        max 3y_4 + 3y_3 + y_1 - 1
    s.a.
        y_1 + 2y_3 + y_4 = -4 :x_1
        y_2 + y_3 + 2y_4 = -3 :x_2
        y_1 >= 0
        y_2 >= 0
        y_3 <= 0
        y_4 <= 0
    =#
        primal_model = lp7_test()
        dual_model, primal_dual_map = get_dual_model_and_map(primal_model)

        dual_model.num_variables_created 
        dual_model.objective
        @test dual_model.num_variables_created == 4
        ddual_model, primal_dual_map = get_dual_model_and_map(dual_model)
        ddual_model.num_variables_created 
        ddual_model.objective
        ddual_model.nextconstraintid
    end

    @testset "lp10_test" begin
        primal_model = lp10_test()
        dual_model, primal_dual_map = get_dual_model_and_map(primal_model)
        
        dual_model.num_variables_created 
        @test dual_model.num_variables_created == 4
    end

    @testset "lp12_test" begin
        primal_model = lp12_test()
        dual_model, primal_dual_map = get_dual_model_and_map(primal_model)
    end

end