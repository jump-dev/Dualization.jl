function sdpt1_test()
    # min X[1,1] + X[2,2]    max y
    #     X[2,1] = 1         [0   y/2     [ 1  0
    #                         y/2 0    <=   0  1]
    #     X >= 0              y free
    # Optimal solution:
    #     ⎛ 1   1 ⎞
    # X = ⎜       ⎟           y = 2
    #     ⎝ 1   1 ⎠

    model = TestModel{Float64}()

    X = MOI.add_variables(model, 3)

    vov = MOI.VectorOfVariables(X)
    
    cX = MOI.add_constraint(model, vov, MOI.PositiveSemidefiniteConeTriangle(2))

    c = MOI.add_constraint(model, MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(1.0, X[2])], 0.0), MOI.EqualTo(1.0))

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.(1.0, [X[1], X[end]]), 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    return  model
end

function sdpt2_test()
    #= 
        min TR(X)
    s.t.
        X[2,1] = 1
        X in PSD
    =#

    model = TestModel{Float64}()

    X = MOI.add_variables(model, 3)

    vov = MOI.VectorOfVariables(X)

    cX = MOI.add_constraint(model, MOI.VectorAffineFunction{Float64}(vov), MOI.PositiveSemidefiniteConeTriangle(2))

    c = MOI.add_constraint(model, MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(1.0, X[2])], 0.0), MOI.EqualTo(1.0))

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.(1.0, [X[1], X[end]]), 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    return  model
end

function sdpt3_test()
    # Problem SDP1 - sdo1 from MOSEK docs
    # From Mosek.jl/test/mathprogtestextra.jl, under license:
    #   Copyright (c) 2013 Ulf Worsoe, Mosek ApS
    #   Permission is hereby granted, free of charge, to any person obtaining a copy of this
    #   software and associated documentation files (the "Software"), to deal in the Software
    #   without restriction, including without limitation the rights to use, copy, modify, merge,
    #   publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
    #   to whom the Software is furnished to do so, subject to the following conditions:
    #   The above copyright notice and this permission notice shall be included in all copies or
    #   substantial portions of the Software.
    #
    #     | 2 1 0 |
    # min | 1 2 1 | . X + x1
    #     | 0 1 2 |
    #
    #
    # s.t. | 1 0 0 |
    #      | 0 1 0 | . X + x1 = 1
    #      | 0 0 1 |
    #
    #      | 1 1 1 |
    #      | 1 1 1 | . X + x2 + x3 = 1/2
    #      | 1 1 1 |
    #
    #      (x1,x2,x3) in C^3_q
    #      X in C_psd
    #
    # The dual is
    # max y1 + y2/2
    #
    # s.t. | y1+y2    y2    y2 |
    #      |    y2 y1+y2    y2 | in C_psd
    #      |    y2    y2 y1+y2 |
    #
    #      (1-y1, -y2, -y2) in C^3_q
    #
    # The dual of the SDP constraint is rank two of the form
    # [γ, 0, -γ] * [γ, 0, γ'] + [δ, ε, δ] * [δ, ε, δ]'
    # and the dual of the SOC constraint is of the form (√2*y2, -y2, -y2)
    #
    # The feasible set of the constraint dual contains only four points.
    # Eliminating, y1, y2 and γ from the dual constraints gives
    # -ε^2 + -εδ + 2δ^2 + 1
    # (√2-2)ε^2 + (-2√2+2)δ^2 + 1
    # Eliminating ε from this set of equation give
    # (-6√2+4)δ^4 + (3√2-2)δ^2 + (2√2-3)
    # from which we find the solution
    # δ = √(1 + (3*√2+2)*√(-116*√2+166) / 14) / 2
    # which is optimal
    # ε = √((1 - 2*(√2-1)*δ^2) / (2-√2))
    # y2 = 1 - ε*δ
    # y1 = 1 - √2*y2
    # obj = y1 + y2/2
    # The primal solution is rank one of the form
    # X = [α, β, α] * [α, β, α]'
    # and by complementary slackness, x is of the form (√2*x2, x2, x2)
    # The primal reduces to
    #      4α^2+4αβ+2β^2+√2*x2= obj
    #      2α^2    + β^2+√2*x2 = 1 (1)
    #      8α^2+8αβ+2β^2+ 4 x2 = 1
    # Eliminating β, we get
    # 4α^2 + 4x2 = 3 - 2obj (2)
    # By complementary slackness, we have β = kα where
    # k = -2*δ/ε
    # Replacing β by kα in (1) allows to eliminate α^2 in (2) to get
    # x2 = ((3-2obj)*(2+k^2)-4) / (4*(2+k^2)-4*√2)
    # With (2) we get
    # α = √(3-2obj-4x2)/2
    # β = k*α

   model = TestModel{Float64}()

    X = MOI.add_variables(model, 6)
    x = MOI.add_variables(model, 3)

    vov = MOI.VectorOfVariables(X)
    
    cX = MOI.add_constraint(model, vov, MOI.PositiveSemidefiniteConeTriangle(3))
    cx = MOI.add_constraint(model, MOI.VectorOfVariables(x), MOI.SecondOrderCone(3))

    c1 = MOI.add_constraint(model, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1., 1, 1, 1], [X[1], X[3], X[end], x[1]]), 0.), MOI.EqualTo(1.))
    c2 = MOI.add_constraint(model, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1., 2, 1, 2, 2, 1, 1, 1], [X; x[2]; x[3]]), 0.), MOI.EqualTo(1/2))

    objXidx = [1:3; 5:6]
    objXcoefs = 2*ones(5)
    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([objXcoefs; 1.0], [X[objXidx]; x[1]]), 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    return model
end

function sdpt4_test()
    # Problem SDP1 - sdo1 from MOSEK docs
    # From Mosek.jl/test/mathprogtestextra.jl, under license:
    #   Copyright (c) 2013 Ulf Worsoe, Mosek ApS
    #   Permission is hereby granted, free of charge, to any person obtaining a copy of this
    #   software and associated documentation files (the "Software"), to deal in the Software
    #   without restriction, including without limitation the rights to use, copy, modify, merge,
    #   publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
    #   to whom the Software is furnished to do so, subject to the following conditions:
    #   The above copyright notice and this permission notice shall be included in all copies or
    #   substantial portions of the Software.
    #
    #     | 2 1 0 |
    # min | 1 2 1 | . X + x1
    #     | 0 1 2 |
    #
    #
    # s.t. | 1 0 0 |
    #      | 0 1 0 | . X + x1 = 1
    #      | 0 0 1 |
    #
    #      | 1 1 1 |
    #      | 1 1 1 | . X + x2 + x3 = 1/2
    #      | 1 1 1 |
    #
    #      (x1,x2,x3) in C^3_q
    #      X in C_psd
    #
    # The dual is
    # max y1 + y2/2
    #
    # s.t. | y1+y2    y2    y2 |
    #      |    y2 y1+y2    y2 | in C_psd
    #      |    y2    y2 y1+y2 |
    #
    #      (1-y1, -y2, -y2) in C^3_q
    #
    # The dual of the SDP constraint is rank two of the form
    # [γ, 0, -γ] * [γ, 0, γ'] + [δ, ε, δ] * [δ, ε, δ]'
    # and the dual of the SOC constraint is of the form (√2*y2, -y2, -y2)
    #
    # The feasible set of the constraint dual contains only four points.
    # Eliminating, y1, y2 and γ from the dual constraints gives
    # -ε^2 + -εδ + 2δ^2 + 1
    # (√2-2)ε^2 + (-2√2+2)δ^2 + 1
    # Eliminating ε from this set of equation give
    # (-6√2+4)δ^4 + (3√2-2)δ^2 + (2√2-3)
    # from which we find the solution
    # δ = √(1 + (3*√2+2)*√(-116*√2+166) / 14) / 2
    # which is optimal
    # ε = √((1 - 2*(√2-1)*δ^2) / (2-√2))
    # y2 = 1 - ε*δ
    # y1 = 1 - √2*y2
    # obj = y1 + y2/2
    # The primal solution is rank one of the form
    # X = [α, β, α] * [α, β, α]'
    # and by complementary slackness, x is of the form (√2*x2, x2, x2)
    # The primal reduces to
    #      4α^2+4αβ+2β^2+√2*x2= obj
    #      2α^2    + β^2+√2*x2 = 1 (1)
    #      8α^2+8αβ+2β^2+ 4 x2 = 1
    # Eliminating β, we get
    # 4α^2 + 4x2 = 3 - 2obj (2)
    # By complementary slackness, we have β = kα where
    # k = -2*δ/ε
    # Replacing β by kα in (1) allows to eliminate α^2 in (2) to get
    # x2 = ((3-2obj)*(2+k^2)-4) / (4*(2+k^2)-4*√2)
    # With (2) we get
    # α = √(3-2obj-4x2)/2
    # β = k*α

    model = TestModel{Float64}()

    X = MOI.add_variables(model, 6)
    x = MOI.add_variables(model, 3)

    vov = MOI.VectorOfVariables(X)
    cX = MOI.add_constraint(model, MOI.VectorAffineFunction{Float64}(vov), MOI.PositiveSemidefiniteConeTriangle(3))
    cx = MOI.add_constraint(model, MOI.VectorOfVariables(x), MOI.SecondOrderCone(3))

    c1 = MOI.add_constraint(model, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1., 1, 1, 1], [X[1], X[3], X[end], x[1]]), 0.), MOI.EqualTo(1.))
    c2 = MOI.add_constraint(model, MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([1., 2, 1, 2, 2, 1, 1, 1], [X; x[2]; x[3]]), 0.), MOI.EqualTo(1/2))

    objXidx = [1:3; 5:6]
    objXcoefs = 2*ones(5)
    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.([objXcoefs; 1.0], [X[objXidx]; x[1]]), 0.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    return model
end