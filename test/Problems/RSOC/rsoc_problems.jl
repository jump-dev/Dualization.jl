function rsoc1_test()
    #=
        min 0a + 0b - 1x - 1y
    s.t.
        a    == 1/2
        b    == 1
        2a*b >= x^2+y^2
    =#
    model = TestModel{Float64}()

    x = MOI.add_variables(model, 2)

    a = MOI.add_variable(model)
    b = MOI.add_variable(model)
    vc1 = MOI.add_constraint(model, MOI.SingleVariable(a), MOI.EqualTo(0.5))
    # We test this after the creation of every `SingleVariable` constraint
    # to ensure a good coverage of corner cases.
    vc2 = MOI.add_constraint(model, MOI.SingleVariable(b), MOI.EqualTo(1.0))
    rsoc = MOI.add_constraint(model, MOI.VectorOfVariables([a; b; x]), MOI.RotatedSecondOrderCone(4))

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
            MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.(-1.0, x), 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    
    return model
end

function rsoc2_test()
    #=
        min 0a + 0b - 1x - 1y
    s.t.
        a    == 1/2
        b    == 1
        2a*b >= x^2+y^2
    =#
    model = TestModel{Float64}()

    x = MOI.add_variables(model, 2)
    a = 0.5
    b = 1.0
    rsoc = MOI.add_constraint(model, MOI.VectorAffineFunction(MOI.VectorAffineTerm.([3, 4], 
            MOI.ScalarAffineTerm.([1., 1.], x)), [a, b, 0., 0.]), MOI.RotatedSecondOrderCone(4))

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
            MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.(-1.0, x), 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    
    return model
end

function rsoc3_test()
    #=
        min x + 1
    s.t.
        x ≤ 1
        y = 1/2
        z ≥ 2
        z^2 ≤ 2x*y
    =#
    model = TestModel{Float64}()

    b = [-2, -1, 1/2]
    c = [1.0,0.0,0.0]

    x = MOI.add_variables(model, 3)

    vc1 = MOI.add_constraint(model, MOI.SingleVariable(x[1]), MOI.LessThan(1.0))
    vc2 = MOI.add_constraint(model, MOI.SingleVariable(x[2]), MOI.EqualTo(0.5))
    vc3 = MOI.add_constraint(model, MOI.SingleVariable(x[3]), MOI.GreaterThan(2.0))

    rsoc = MOI.add_constraint(model, MOI.VectorOfVariables(x), MOI.RotatedSecondOrderCone(3))
    
    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.(c, x), 1.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
   
    return model
end

function rsoc4_test()
    #=
        max v
    s.t.
        x[1:10] ≥ 0
        0 ≤ u ≤ 3.0
        v
        t1 == 1
        t2 == 1
        [t1/√2, t2/√2, x] in RSOC4
        [x1/√2, u/√2,  v] in RSOC3
    =#
    model = TestModel{Float64}()

    x = MOI.add_variables(model, 2)
    u = MOI.add_variable(model)
    v = MOI.add_variable(model)
    t = MOI.add_variables(model, 2)

    ct1 = MOI.add_constraint(model, MOI.SingleVariable(t[1]), MOI.EqualTo(1.0))
    ct2 = MOI.add_constraint(model, MOI.SingleVariable(t[2]), MOI.EqualTo(1.0))
    cx  = MOI.add_constraint(model, MOI.VectorOfVariables(x), MOI.Nonnegatives(2))
    cu1 = MOI.add_constraint(model, MOI.SingleVariable(u), MOI.GreaterThan(0.0))
    cu2 = MOI.add_constraint(model, MOI.SingleVariable(u), MOI.LessThan(3.0))

    c1 = MOI.add_constraint(model, MOI.VectorAffineFunction(MOI.VectorAffineTerm.(1:(2+2), MOI.ScalarAffineTerm.([1/√2; 1/√2; ones(2)], [t; x])), zeros(2+2)), MOI.RotatedSecondOrderCone(2+2))
    c2 = MOI.add_constraint(model, MOI.VectorAffineFunction(MOI.VectorAffineTerm.([1, 2, 3], MOI.ScalarAffineTerm.([1/√2; 1/√2; 1.0], [x[1], u, v])), zeros(3)), MOI.RotatedSecondOrderCone(3))

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(1.0, v)], 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)

    return model
end

function rsoc5_test()
    #=
        max v
    s.t.
        x[1:10] ≥ 0
        0 ≤ u ≤ 3.0
        v
        t1 == 1
        t2 == 1
        [t1/√2, t2/√2, x] in RSOC12
        [x1/√2, u/√2,  v] in RSOC3
    =#
    model = TestModel{Float64}()

    x = MOI.add_variables(model, 10)
    u = MOI.add_variable(model)
    v = MOI.add_variable(model)
    t = MOI.add_variables(model, 2)

    ct1 = MOI.add_constraint(model, MOI.SingleVariable(t[1]), MOI.EqualTo(1.0))
    ct2 = MOI.add_constraint(model, MOI.SingleVariable(t[2]), MOI.EqualTo(1.0))
    cx  = MOI.add_constraint(model, MOI.VectorOfVariables(x), MOI.Nonnegatives(10))
    cu1 = MOI.add_constraint(model, MOI.SingleVariable(u), MOI.GreaterThan(0.0))
    cu2 = MOI.add_constraint(model, MOI.SingleVariable(u), MOI.LessThan(3.0))

    c1 = MOI.add_constraint(model, MOI.VectorAffineFunction(MOI.VectorAffineTerm.(1:(2+10), MOI.ScalarAffineTerm.([1/√2; 1/√2; ones(10)], [t; x])), zeros(2+10)), MOI.RotatedSecondOrderCone(2+10))
    c2 = MOI.add_constraint(model, MOI.VectorAffineFunction(MOI.VectorAffineTerm.([1, 2, 3], MOI.ScalarAffineTerm.([1/√2; 1/√2; 1.0], [x[1], u, v])), zeros(3)), MOI.RotatedSecondOrderCone(3))

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(1.0, v)], 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)

    return model
end