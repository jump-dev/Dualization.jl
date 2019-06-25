function lp1_test()
    #=
        min -4x_2 - 1
    st
        x_1 + 2x_2 <= 3
        x_1 >= 1
        x_1 >= 3
    =#

    lp1 = TestModel{Float64}()
    
    X = MOI.add_variables(lp1, 2)
    
    MOI.add_constraint(lp1, 
        MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([1.0, 2.0], X), 0.0),
            MOI.LessThan(3.0))
    
    MOI.add_constraint(lp1, 
        MOI.SingleVariable(X[1]),
            MOI.GreaterThan(1.0))
    
    MOI.add_constraint(lp1, 
        MOI.SingleVariable(X[1]),
            MOI.GreaterThan(3.0))
    
    MOI.set(lp1, 
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0], [X[2]]), -1.0))
    
    MOI.set(lp1, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    
    return lp1
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
    lp2 = TestModel{Float64}()
    
    X = MOI.add_variables(lp2, 2)
    
    MOI.add_constraint(lp2, 
        MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([2.0, 1.0], X), 0.0),
             MOI.LessThan(3.0))
    
    MOI.add_constraint(lp2, 
        MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([1.0, 2.0], X), 0.0),
             MOI.LessThan(3.0))
    
    MOI.add_constraint(lp2, 
        MOI.ScalarAffineFunction(
            [MOI.ScalarAffineTerm(1.0, X[1])], 0.0),
             MOI.GreaterThan(1.0))
    
    MOI.add_constraint(lp2, 
        MOI.ScalarAffineFunction(
            [MOI.ScalarAffineTerm(1.0, X[2])], 0.0),
             MOI.GreaterThan(0.0))
    
    MOI.set(lp2, 
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0, -3.0], [X[1], X[2]]), -1.0))
    
    MOI.set(lp2, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    return lp2
end    

function lp3_test()
    #= 
    min -4x1 -3x2 -1
      s.a.
        2x1 + x2 + 1 <= 4
        x1 + 2x2 + 1 <= 4
        x1 >= 1
        x2 >= 0
    =#
    lp3 = TestModel{Float64}()
    
    X = MOI.add_variables(lp3, 2)
    
    MOI.add_constraint(lp3, 
        MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([2.0, 1.0], X), 0.0),
             MOI.LessThan(3.0))
    
    MOI.add_constraint(lp3, 
        MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([1.0, 2.0], X), 0.0),
             MOI.LessThan(3.0))
    
    MOI.add_constraint(lp3, 
        MOI.SingleVariable(X[1]),
             MOI.GreaterThan(1.0))
    
    MOI.add_constraint(lp3, 
        MOI.SingleVariable(X[2]),
             MOI.GreaterThan(0.0))
    
    MOI.set(lp3, 
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0, -3.0], [X[1], X[2]]), -1.0))
    
    MOI.set(lp3, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    
    return lp3
end    

function lp4_test()
    #= 
    max 4x1 3x2 
      s.a.
        x1 >= 1
        x2 >= 0
    =#
    lp4 = TestModel{Float64}()
    
    X = MOI.add_variables(lp4, 2)
    
    MOI.add_constraint(lp4, 
        MOI.SingleVariable(X[1]),
             MOI.GreaterThan(1.0))
    
    MOI.add_constraint(lp4, 
        MOI.SingleVariable(X[2]),
             MOI.GreaterThan(0.0))
    
    MOI.set(lp4, 
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([4.0, 3.0], [X[1], X[2]]), 0.0))
    
    MOI.set(lp4, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    
    return lp4
end

function lp5_test()
    #= 
        min -4x1 -3x2 -1
    s.a.
        2x1 + x2  == 3
        x1 + 2x2  == 3
        x1 >= 1
        x2 == 0
    =#
    lp5= TestModel{Float64}()

    X = MOI.add_variables(lp5, 2)

    MOI.add_constraint(lp5, 
        MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([2.0, 1.0], X), 0.0),
            MOI.EqualTo(3.0))

    MOI.add_constraint(lp5, 
        MOI.ScalarAffineFunction(
            MOI.ScalarAffineTerm.([1.0, 2.0], X), 0.0),
            MOI.EqualTo(3.0))

    MOI.add_constraint(lp5, 
        MOI.SingleVariable(X[1]),
            MOI.GreaterThan(1.0))

    MOI.add_constraint(lp5, 
        MOI.SingleVariable(X[2]),
            MOI.EqualTo(0.0))

    MOI.set(lp5, 
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0, -3.0], [X[1], X[2]]), -1.0))

    MOI.set(lp5, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    
    return lp5
end

function lp6_test()
    #= 
    Model: 
        min -4x1 -3x2 -1
    s.a.
        2x1 + x2 - 3 <= 0
        x1 + 2x2 - 3 <= 0
        x1 >= 1
        x2 >= 0
    =#
    lp6 = TestModel{Float64}()

    X = MOI.add_variables(lp6, 2)

    c1 = MOI.VectorAffineFunction(
                MOI.VectorAffineTerm.([1, 1, 2, 2], MOI.ScalarAffineTerm.([2.0, 1.0, 1.0, 2.0], [X; X])),
                [-3.0, -3.0])

    MOI.add_constraint(lp6, c1, MOI.Nonpositives(2))

    MOI.add_constraint(lp6, 
        MOI.SingleVariable(X[1]),
            MOI.GreaterThan(1.0))

    MOI.add_constraint(lp6, 
        MOI.SingleVariable(X[2]),
            MOI.GreaterThan(0.0))

    MOI.set(lp6, 
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0, -3.0], [X[1], X[2]]), -1.0))

    MOI.set(lp6, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    return lp6
end

function lp7_test()
    #=
    min -4x1 -3x2 -1
  s.a.
    2x1 + x2 - 3 <= 0
    x1 + 2x2 - 3 <= 0
    x1 >= 1
    x2 >= 0
    =#
    lp7= TestModel{Float64}()

    X = MOI.add_variables(lp7, 2)

    c1 = MOI.VectorAffineFunction(
                MOI.VectorAffineTerm.([1, 1, 2, 2], MOI.ScalarAffineTerm.([2.0, 1.0, 1.0, 2.0], [X; X])),
                [-3.0, -3.0])

    MOI.add_constraint(lp7, c1, MOI.Nonpositives(2))


    MOI.add_constraint(lp7, 
        MOI.SingleVariable(X[1]),
            MOI.GreaterThan(1.0))

    MOI.add_constraint(lp7, 
        MOI.SingleVariable(X[2]),
            MOI.GreaterThan(0.0))

    MOI.set(lp7, 
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4.0, -3.0], [X[1], X[2]]), -1.0))

    MOI.set(lp7, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    return lp7
end
    
function lp8_test()
    #=
        min -4x1 -3x2 -1
    s.a.
        2x1 + x2 - 3 <= 0
        x1 + 2x2 - 3 <= 0
        x1 >= 1
        x2 >= 0
    =#
    lp8= TestModel{Int64}()

    X = MOI.add_variables(lp8, 2)

    c1 = MOI.VectorAffineFunction(
                MOI.VectorAffineTerm.([1, 1, 2, 2], MOI.ScalarAffineTerm.([2, 1, 1, 2], [X; X])),
                [-3, -3])

    MOI.add_constraint(lp8, c1, MOI.Nonpositives(2))

    c2 = MOI.VectorAffineFunction(
                MOI.VectorAffineTerm.([1, 2], MOI.ScalarAffineTerm.([1, 1], X)),
                [1, 0])

    MOI.add_constraint(lp8, c2, MOI.Nonnegatives(2))

    MOI.set(lp8, 
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), 
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([-4, -3], X), -1))

    MOI.set(lp8, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    return lp8
end