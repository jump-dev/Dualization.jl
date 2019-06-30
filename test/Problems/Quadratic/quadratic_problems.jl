function qp1_test()
    #= 
        min x^2 + xy + y^2 + yz + z^2
    s.t.
        x + 2y + 3z >= 4 (c1)
        x +  y      >= 1 (c2)
        x,y \in R
    =#
    model= TestModel{Float64}()

    v = MOI.add_variables(model, 3)

    cf1 = MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0,2.0,3.0], v), 0.0)

    c1 = MOI.add_constraint(model, cf1, MOI.GreaterThan(4.0))
    c2 = MOI.add_constraint(model, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0,1.0], [v[1],v[2]]), 0.0), MOI.GreaterThan(1.0))

    obj = MOI.ScalarQuadraticFunction(MOI.ScalarAffineTerm{Float64}[], MOI.ScalarQuadraticTerm.([2.0, 1.0, 2.0, 1.0, 2.0], v[[1,1,2,2,3]], v[[1,2,2,3,3]]), 0.0)
    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarQuadraticFunction{Float64}}(), obj)
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    return model
end

function qp2_test()
    #=
        min 2 x^2 + y^2 + xy + x + y + 1
    s.t. 
        x, y >= 0
        x + y = 1
    =#

    model= TestModel{Float64}()

    x = MOI.add_variable(model)
    y = MOI.add_variable(model)

    MOI.add_constraint(model,
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0,1.0], [x,y]), 0.0),
        MOI.EqualTo(1.0))

    vc1 = MOI.add_constraint(model, MOI.SingleVariable(x), MOI.GreaterThan(0.0))
    vc2 = MOI.add_constraint(model, MOI.SingleVariable(y), MOI.GreaterThan(0.0))

    obj = MOI.ScalarQuadraticFunction(
            MOI.ScalarAffineTerm.([1.0,1.0], [x,y]),
            MOI.ScalarQuadraticTerm.([4.0, 2.0, 1.0], [x,y,x], [x,y,y]),
            1.0)
            
    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarQuadraticFunction{Float64}}(), obj)
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    return model
end