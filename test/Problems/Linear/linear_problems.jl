function lp1_test()
    #=
        min -4x_2 - 1
    s.t.
        x_1 + 2x_2 <= 3
        x_1 >= 3
    =#
    model = TestModel{Float64}()
    
    X = MOI.add_variables(model, 2)
    
    MOI.add_constraint(model, 
        MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([1.0, 2.0], X), 0.0),
            MOI.LessThan(3.0))
    
    MOI.add_constraint(model, 
        MOI.SingleVariable(X[1]),
            MOI.GreaterThan(3.0))
    
    MOI.set(model, 
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0], [X[2]]), -1.0))
    
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    
    return model
end

function lp2_test()    
    #=     
        min -4x1 -3x2 -1
    s.t.
        2x1 + x2 + 1 <= 4
        x1 + 2x2 + 1 <= 4
        x1 >= 1
        x2 >= 0
    =#
    model = TestModel{Float64}()
    
    X = MOI.add_variables(model, 2)
    
    MOI.add_constraint(model, 
        MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([2.0, 1.0], X), 0.0),
             MOI.LessThan(3.0))
    
    MOI.add_constraint(model, 
        MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([1.0, 2.0], X), 0.0),
             MOI.LessThan(3.0))
    
    MOI.add_constraint(model, 
        MOI.ScalarAffineFunction(
            [MOI.ScalarAffineTerm(1.0, X[1])], 0.0),
             MOI.GreaterThan(1.0))
    
    MOI.add_constraint(model, 
        MOI.ScalarAffineFunction(
            [MOI.ScalarAffineTerm(1.0, X[2])], 0.0),
             MOI.GreaterThan(0.0))
    
    MOI.set(model, 
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0, -3.0], X), -1.0))
    
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    return model
end    

function lp3_test()
    #= 
        min -4x1 -3x2 -1
    s.t.
        2x1 + x2 + 1 <= 4
        x1 + 2x2 + 1 <= 4
        x1 >= 1
        x2 >= 0
    =#
    model = TestModel{Float64}()
    
    X = MOI.add_variables(model, 2)
    
    MOI.add_constraint(model, 
        MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([2.0, 1.0], X), 0.0),
             MOI.LessThan(3.0))
    
    MOI.add_constraint(model, 
        MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([1.0, 2.0], X), 0.0),
             MOI.LessThan(3.0))
    
    MOI.add_constraint(model, 
        MOI.SingleVariable(X[1]),
             MOI.GreaterThan(1.0))
    
    MOI.add_constraint(model, 
        MOI.SingleVariable(X[2]),
             MOI.GreaterThan(0.0))
    
    MOI.set(model, 
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0, -3.0], X), -1.0))
    
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    
    return model
end    

function lp4_test()
    #= 
        max 4x1 + 3x2 
      s.t.
        x1 >= 1
        x2 >= 0
    =#
    model = TestModel{Float64}()
    
    X = MOI.add_variables(model, 2)
    
    MOI.add_constraint(model, 
        MOI.SingleVariable(X[1]),
             MOI.GreaterThan(1.0))
    
    MOI.add_constraint(model, 
        MOI.SingleVariable(X[2]),
             MOI.GreaterThan(0.0))
    
    MOI.set(model, 
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([4.0, 3.0], X), 0.0))
    
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    
    return model
end

function lp5_test()
    #= 
        min -4x1 -3x2 -1
    s.t.
        2x1 + x2  == 3
        x1 + 2x2  == 3
        x1 >= 1
        x2 == 0
    =#
    model= TestModel{Float64}()

    X = MOI.add_variables(model, 2)

    MOI.add_constraint(model, 
        MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([2.0, 1.0], X), 0.0),
            MOI.EqualTo(3.0))

    MOI.add_constraint(model, 
        MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([1.0, 2.0], X), 0.0),
            MOI.EqualTo(3.0))

    MOI.add_constraint(model, 
        MOI.SingleVariable(X[1]),
            MOI.GreaterThan(1.0))

    MOI.add_constraint(model, 
        MOI.SingleVariable(X[2]),
            MOI.EqualTo(0.0))

    MOI.set(model, 
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0, -3.0], X), -1.0))

    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    
    return model
end

function lp6_test()
    #= 
        min -4x1 -3x2 -1
    s.t.
        2x1 + x2 - 3 <= 0
        x1 + 2x2 - 3 <= 0
        x1 >= 1
        x2 >= 0
    =#
    model = TestModel{Float64}()

    X = MOI.add_variables(model, 2)

    c1 = MOI.VectorAffineFunction(
                MOI.VectorAffineTerm.([1, 1, 2, 2], MOI.ScalarAffineTerm.([2.0, 1.0, 1.0, 2.0], [X; X])),
                [-3.0, -3.0])

    MOI.add_constraint(model, c1, MOI.Nonpositives(2))

    MOI.add_constraint(model, 
        MOI.SingleVariable(X[1]),
            MOI.GreaterThan(1.0))

    MOI.add_constraint(model, 
        MOI.SingleVariable(X[2]),
            MOI.GreaterThan(0.0))

    MOI.set(model, 
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0, -3.0], X), -1.0))

    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    return model
end

function lp7_test()
    #=
        min -4x1 -3x2 -1
    s.t.
        2x1 + x2 - 3 <= 0
        x1 + 2x2 - 3 <= 0
        x1 >= 1
        x2 >= 0
    =#
    model= TestModel{Float64}()

    X = MOI.add_variables(model, 2)

    c1 = MOI.VectorAffineFunction(
            MOI.VectorAffineTerm.([1, 1, 2, 2], MOI.ScalarAffineTerm.([2.0, 1.0, 1.0, 2.0], [X; X])), 
            [-3.0, -3.0])

    MOI.add_constraint(model, c1, MOI.Nonpositives(2))


    MOI.add_constraint(model, 
        MOI.SingleVariable(X[1]),
            MOI.GreaterThan(1.0))

    MOI.add_constraint(model, 
        MOI.SingleVariable(X[2]),
            MOI.GreaterThan(0.0))

    MOI.set(model, 
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0, -3.0], X), -1.0))

    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    return model
end
    
function lp8_test()
    #=
        min -4x1 -3x2 -1
    s.t.
        2x1 + x2 - 3 <= 0
        x1 + 2x2 - 3 <= 0
        x1 >= 1
        x2 >= 0
    =#
    model = TestModel{Int64}()

    X = MOI.add_variables(model, 2)

    c1 = MOI.VectorAffineFunction(
            MOI.VectorAffineTerm.([1, 1, 2, 2], MOI.ScalarAffineTerm.([2, 1, 1, 2], [X; X])),
            [-3, -3])

    MOI.add_constraint(model, c1, MOI.Nonpositives(2))

    c2 = MOI.VectorAffineFunction(
            MOI.VectorAffineTerm.([1, 2], MOI.ScalarAffineTerm.([1, 1], X)), 
            [1, 0])

    MOI.add_constraint(model, c2, MOI.Nonnegatives(2))

    MOI.set(model, 
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4, -3], X), -1))

    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    return model
end

function lp9_test()
    #= 
        min x + y
    s.t.  
        -1 <= x + y <= 10
        x,  y >= 0
    =#
    model = TestModel{Float64}()

    x = MOI.add_variable(model)
    y = MOI.add_variable(model)

    vc = MOI.add_constraints(model,
        [MOI.SingleVariable(x), MOI.SingleVariable(y)],
        [MOI.GreaterThan(0.0), MOI.GreaterThan(0.0)])

    c = MOI.add_constraint(model, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0, 1.0], [x,y]), 0.0), MOI.Interval(-1.0, 10.0))

    MOI.set(model, 
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(),
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1.0, 1.0], [x, y]), 0.0))
        
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    return model
end

function lp10_test()
    #= 
        min x1
    s.t.
        2x1 + x2  == 3
        x1 + 2x2  == 3
        x1 >= 1
        x2 == 0
    =#
    model= TestModel{Float64}()

    X = MOI.add_variables(model, 2)

    MOI.add_constraint(model, 
        MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([2.0, 1.0], X), 0.0),
            MOI.EqualTo(3.0))

    MOI.add_constraint(model, 
        MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([1.0, 2.0], X), 0.0),
            MOI.EqualTo(3.0))

    MOI.add_constraint(model, 
        MOI.SingleVariable(X[1]),
            MOI.GreaterThan(1.0))

    MOI.add_constraint(model, 
        MOI.SingleVariable(X[2]),
            MOI.EqualTo(0.0))

    MOI.set(model, 
        MOI.ObjectiveFunction{MOI.SingleVariable}(), 
        MOI.SingleVariable(X[1]))

    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    
    return model
end

function lp11_test()
    #=  
        Feasibility
    s.t.
        x1 >= 1
        x2 >= 0
    =#
    model = TestModel{Float64}()
    
    X = MOI.add_variables(model, 2)
    
    MOI.add_constraint(model, 
        MOI.SingleVariable(X[1]),
             MOI.GreaterThan(1.0))
    
    MOI.add_constraint(model, 
        MOI.SingleVariable(X[2]),
             MOI.GreaterThan(0.0))
    
    MOI.set(model, 
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([4.0, 3.0], X), 0.0))
    
    return model
end

function lp12_test()
    #=
        min 4x_3 + 5
    s.t.
        x_1 + 2x_2 + x_3 <= 20
        x_1 <= 1
        x_2 <= 3
    =#
    model = TestModel{Float64}()
    
    X = MOI.add_variables(model, 3)
    
    MOI.add_constraint(model, 
        MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([1.0, 2.0, 1.0], X), 0.0),
            MOI.LessThan(20.0))
    
    MOI.add_constraint(model, 
        MOI.SingleVariable(X[1]),
            MOI.LessThan(1.0))
    
    MOI.add_constraint(model, 
        MOI.SingleVariable(X[2]),
            MOI.LessThan(3.0))
    
    MOI.set(model, 
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([4.0], [X[3]]), 5.0))
    
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    
    return model
end

function lp13_test()
    #=
        min -4x1 -3x2 -1
    s.t.
        2x1 + x2 - 3 <= 0
        x1 + 2x2 - 3 <= 0
        x1 >= 0
        x2 >= 0
    =#
    model= TestModel{Float64}()

    X = MOI.add_variables(model, 2)

    c1 = MOI.VectorAffineFunction(
            MOI.VectorAffineTerm.([1, 1, 2, 2], MOI.ScalarAffineTerm.([2.0, 1.0, 1.0, 2.0], [X; X])), 
            [-3.0, -3.0])

    MOI.add_constraint(model, c1, MOI.Nonpositives(2))

    MOI.add_constraint(model, MOI.VectorOfVariables(X), MOI.Nonnegatives(2))

    MOI.set(model, 
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0, -3.0], X), -1.0))

    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    return model
end