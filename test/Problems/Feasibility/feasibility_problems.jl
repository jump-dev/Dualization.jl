function feasibility_1_test()
    #=
        min 0
    s.t.
        x_1 + 2x_2 <= 3
        x_1 >= 3
    =#
    model = TestModel{Float64}()

    X = MOI.add_variables(model, 2)

    MOI.add_constraint(
        model,
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0, 2.0], X), 0.0),
        MOI.LessThan(3.0),
    )

    MOI.add_constraint(model, X[1], MOI.GreaterThan(3.0))

    return model
end
