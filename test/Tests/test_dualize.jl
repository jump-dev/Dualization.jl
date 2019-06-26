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
        y_1 + y_2 + y_3 == 0  :x1  
        2_y3 == -4            :x2
        y_1 >= 0
        y_2 >= 0
        y_3 <= 0
    =#
        primal_model = lp1_test()
        dual_model, primal_dual_map = get_dual_model_and_map(primal_model)
        dual_model.objective

        @test dual_model.num_variables_created == 3
        
    end

    @testset "lp10_test" begin
        primal_model = lp10_test()
        dual_model, primal_dual_map = get_dual_model_and_map(primal_model)
    end

    @testset "lp12_test" begin
        primal_model = lp12_test()
        dual_model, primal_dual_map = get_dual_model_and_map(primal_model)
    end

end