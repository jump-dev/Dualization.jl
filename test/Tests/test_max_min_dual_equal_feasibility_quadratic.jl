function get_DualMinModel_no_bounds()
    MinModel = Model()
    @variable(MinModel, Q₁)
    @variable(MinModel, Q₂)

    @objective(MinModel, Min, (Q₁ + Q₂)^2)
    @constraint(MinModel, C₁, Q₁ + 1 >= 0)
    @constraint(MinModel, C₂, Q₂ + 1 >= 0)

    DualMinModel = dualize(MinModel; dual_names = DualNames("dual", ""))
    return DualMinModel
end

function get_DualMaxModel_no_bounds()
    MaxModel = Model()
    @variable(MaxModel, Q₁)
    @variable(MaxModel, Q₂)
    @objective(MaxModel, Max, -(Q₁ + Q₂)^2)
    @constraint(MaxModel, C₁, Q₁ + 1 >= 0)
    @constraint(MaxModel, C₂, Q₂ + 1 >= 0)

    DualMaxModel = dualize(MaxModel; dual_names = DualNames("dual", ""))
    return DualMaxModel
end

function get_DualMinModel_with_bounds()
    MinModel = Model()
    @variable(MinModel, Q₁ >= 0)
    @variable(MinModel, Q₂ >= 0)

    @objective(MinModel, Min, (Q₁ + Q₂)^2)
    @constraint(MinModel, C₁, Q₁ + 1 >= 0)
    @constraint(MinModel, C₂, Q₂ + 1 >= 0)

    DualMinModel = dualize(MinModel; dual_names = DualNames("dual", ""))
    return DualMinModel
end

function get_DualMaxModel_with_bounds()
    MaxModel = Model()

    @variable(MaxModel, Q₁ >= 0)
    @variable(MaxModel, Q₂ >= 0)
    @objective(MaxModel, Max, -(Q₁ + Q₂)^2)
    @constraint(MaxModel, C₁, Q₁ + 1 >= 0)
    @constraint(MaxModel, C₂, Q₂ + 1 >= 0)

    DualMaxModel = dualize(MaxModel; dual_names = DualNames("dual", ""))
    return DualMaxModel
end

function test_equivalence_max_min(DualMinModel, DualMaxModel)
    for (F, S) in list_of_constraint_types(DualMinModel)
        DualMinModel_eq_con_funs = [
            MOI.get(backend(DualMinModel), MOI.ConstraintFunction(), ctr_idx) for
            ctr_idx in JuMP.index.(all_constraints(DualMinModel, F, S))
        ]
        DualMaxModel_eq_con_funs = [
            MOI.get(backend(DualMaxModel), MOI.ConstraintFunction(), ctr_idx) for
            ctr_idx in JuMP.index.(all_constraints(DualMaxModel, F, S))
        ]
        @test length(DualMinModel_eq_con_funs) ==
              length(DualMaxModel_eq_con_funs)
        for i in eachindex(DualMinModel_eq_con_funs)
            if typeof(DualMinModel_eq_con_funs[i]) != MOI.VariableIndex
                @test MOI.coefficient.(DualMinModel_eq_con_funs[i].terms) ==
                      MOI.coefficient.(DualMaxModel_eq_con_funs[i].terms)
                @test MOI.constant.(DualMinModel_eq_con_funs[i]) ==
                      MOI.constant.(DualMaxModel_eq_con_funs[i])
            end
        end
        DualMinModel_eq_con_sets = [
            MOI.get(backend(DualMinModel), MOI.ConstraintSet(), ctr_idx) for
            ctr_idx in JuMP.index.(all_constraints(DualMinModel, F, S))
        ]
        DualMaxModel_eq_con_sets = [
            MOI.get(backend(DualMaxModel), MOI.ConstraintSet(), ctr_idx) for
            ctr_idx in JuMP.index.(all_constraints(DualMaxModel, F, S))
        ]
        @test length(DualMinModel_eq_con_sets) ==
              length(DualMaxModel_eq_con_sets)
        for i in eachindex(DualMinModel_eq_con_sets)
            @test MOI.constant.(DualMinModel_eq_con_sets[i]) ==
                  MOI.constant.(DualMaxModel_eq_con_sets[i])
        end
    end
end

@testset "max min dual equal feasibility quadratic" begin
    @testset "max min dual equal feasibility quadratic no variable bounds" begin
        DualMinModel = get_DualMinModel_no_bounds()
        DualMaxModel = get_DualMaxModel_no_bounds()
        test_equivalence_max_min(DualMinModel, DualMaxModel)
    end

    @testset "max min dual equal feasibility quadratic with variable bounds" begin
        DualMinModel = get_DualMinModel_with_bounds()
        DualMaxModel = get_DualMaxModel_with_bounds()
        test_equivalence_max_min(DualMinModel, DualMaxModel)
    end
end
