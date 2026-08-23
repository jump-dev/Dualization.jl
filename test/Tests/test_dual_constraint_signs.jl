# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

#=
Every dual constraint associated with a primal variable `x_j` is built as

    -A_{.j}^T y + a_j  in V_j^*    (minimization)
    -A_{.j}^T y - a_j  in V_j^*    (maximization)

where `A_{.j}` is the column of `x_j` in the primal constraints and `a_j` is
its objective coefficient.

For an equality (`V_j^*` being `Reals`, i.e. `x_j` is a free variable) both
sides could be negated without changing the model. That is
undesirable for downstream users that read the dual constraints as the
stationarity rows of a KKT system.

These tests pin the uniform convention down.
=#

# Return the terms of the single dual constraint associated with the only
# primal variable of `primal_model`, as a `(coefficients, constant)` pair.
# `MOI.Utilities.normalize_and_add_constraint` moves the constant of a scalar
# constraint into the set, so the constant is read back from the set when the
# dual constraint is a scalar one.
function _dual_constraint_terms(primal_model)
    dual_model = Dualization.dualize(primal_model).dual_model
    cons = MOI.get(dual_model, MOI.ListOfConstraintTypesPresent())
    for (F, S) in cons
        if F === MOI.VariableIndex
            continue # a bound on a dual variable, not a dual constraint
        end
        ci = only(MOI.get(dual_model, MOI.ListOfConstraintIndices{F,S}()))
        f = MOI.get(dual_model, MOI.ConstraintFunction(), ci)
        set = MOI.get(dual_model, MOI.ConstraintSet(), ci)
        if f isa MOI.ScalarAffineFunction
            # `f in EqualTo(b)` is the same as `f - b in EqualTo(0)`
            return MOI.coefficient.(f.terms),
            MOI.constant(f) - MOI.constant(set)
        else
            scalars = MOI.Utilities.scalarize(f)
            return reduce(vcat, MOI.coefficient.(s.terms) for s in scalars),
            only(unique(MOI.constant.(scalars)))
        end
    end
    return error("no dual constraint found")
end

@testset "dual constraint signs (issue #70)" begin
    # A primal with a single variable `x`, one constraint `2x >= 3` and the
    # objective `11x + 13`. The dual constraint must be `-2y + 11` for `Min`
    # and `-2y - 11` for `Max`, no matter how `x` is declared.
    function _single_variable_model(::Type{T}, sense, variable) where {T}
        model = TestModel{T}()
        x, _ = variable(model)
        MOI.add_constraint(
            model,
            MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(T(2), x)], zero(T)),
            MOI.GreaterThan(T(3)),
        )
        MOI.set(model, MOI.ObjectiveSense(), sense)
        MOI.set(
            model,
            MOI.ObjectiveFunction{MOI.ScalarAffineFunction{T}}(),
            MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(T(11), x)], T(13)),
        )
        return model
    end

    # `x` is free because no variable-wise constraint is added at all.
    _free(model) = (MOI.add_variable(model), nothing)
    # `x` is free, but stated explicitly as a constrained variable in `Reals`.
    function _reals(model)
        x, ci = MOI.add_constrained_variables(model, MOI.Reals(1))
        return only(x), ci
    end
    # `x` is free, but stated explicitly as a constrained variable in `Zeros`,
    # whose dual set is `Reals`.
    function _zeros_dual(model)
        x, ci = MOI.add_constrained_variables(model, MOI.Zeros(1))
        return only(x), ci
    end
    # `x >= 0`: the dual constraint is an inequality instead of an equality.
    function _nonnegative(model)
        x, ci = MOI.add_constrained_variable(model, MOI.GreaterThan(0.0))
        return x, ci
    end

    @testset "uniform sign for $(nameof(variable))" for variable in [
        _free,
        _reals,
        _zeros_dual,
        _nonnegative,
    ]
        # Minimization: `-A^T y + a_0`.
        model = _single_variable_model(Float64, MOI.MIN_SENSE, variable)
        coefficients, constant = _dual_constraint_terms(model)
        @test coefficients == [-2.0]
        @test constant == 11.0
        # Maximization: `-A^T y - a_0`.
        model = _single_variable_model(Float64, MOI.MAX_SENSE, variable)
        coefficients, constant = _dual_constraint_terms(model)
        @test coefficients == [-2.0]
        @test constant == -11.0
    end

    @testset "free variable matches Reals and Zeros" begin
        # This is the invariant the issue is about: the way a free variable is
        # spelled in the primal must not change the dual constraint.
        for sense in [MOI.MIN_SENSE, MOI.MAX_SENSE]
            reference = _dual_constraint_terms(
                _single_variable_model(Float64, sense, _free),
            )
            for variable in [_reals, _zeros_dual]
                @test _dual_constraint_terms(
                    _single_variable_model(Float64, sense, variable),
                ) == reference
            end
        end
    end

    @testset "equality and inequality rows agree" begin
        #=
        primal
            min -4x1 -3x2 -1
        s.t.
            2x1 + x2 <= 3  :y_1
            x1 + 2x2 <= 3  :y_2
            x2 >= 0

        `x1` is free, so its dual constraint is an equality, while `x2` is
        constrained, so its dual constraint is an inequality. Both must expose
        the same `-A_{.j}^T y` sign; only the set differs.
        =#
        primal_model = TestModel{Float64}()
        x1 = MOI.add_variable(primal_model)
        x2, _ = MOI.add_constrained_variable(primal_model, MOI.GreaterThan(0.0))
        MOI.add_constraint(primal_model, 1.0 * x1 + 2.0 * x2, MOI.LessThan(3.0))
        MOI.set(primal_model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
        MOI.set(
            primal_model,
            MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(),
            -4.0 * x1 - 3.0 * x2 - 1.0,
        )
        dual_model = Dualization.dualize(primal_model).dual_model
        # `x1` is free: `-y - 4 == 0`.
        eq_ci = only(
            MOI.get(
                dual_model,
                MOI.ListOfConstraintIndices{
                    MOI.ScalarAffineFunction{Float64},
                    MOI.EqualTo{Float64},
                }(),
            ),
        )
        eq_f = MOI.get(dual_model, MOI.ConstraintFunction(), eq_ci)
        eq_set = MOI.get(dual_model, MOI.ConstraintSet(), eq_ci)
        @test MOI.coefficient.(eq_f.terms) == [-1.0]
        @test MOI.constant(eq_f) - MOI.constant(eq_set) == -4.0
        # `x2 >= 0`: `-2y - 3 >= 0`.
        ineq_ci = only(
            MOI.get(
                dual_model,
                MOI.ListOfConstraintIndices{
                    MOI.ScalarAffineFunction{Float64},
                    MOI.GreaterThan{Float64},
                }(),
            ),
        )
        ineq_f = MOI.get(dual_model, MOI.ConstraintFunction(), ineq_ci)
        ineq_set = MOI.get(dual_model, MOI.ConstraintSet(), ineq_ci)
        @test MOI.coefficient.(ineq_f.terms) == [-2.0]
        @test MOI.constant(ineq_f) - MOI.constant(ineq_set) == -3.0
    end

    @testset "quadratic objective keeps +P w" begin
        #=
        primal
            min 0.5 * 4 * x^2 + 11x + 13
        s.t.
            2x >= 3  :y

        The dual constraint follows the KKT stationarity row
        `a_0 - A^T y + P w = 0`, that is, `11 - 2y + 4w == 0`. The sign in
        front of `P` is a free choice (`w` is free and only appears in a
        symmetric quadratic term elsewhere), and `+P` is the one that matches
        the documented stationarity condition.

        For a maximization problem with a concave objective `0.5 x^T N x`,
        the documented dual row is `-a_0 - A^T y - N w = 0`, so the slack
        term keeps the coefficient `-N`, which is positive again here.
        =#
        for (sense, a_0, w_coefficient) in
            [(MOI.MIN_SENSE, 11.0, 4.0), (MOI.MAX_SENSE, -11.0, 4.0)]
            primal_model = TestModel{Float64}()
            x = MOI.add_variable(primal_model)
            MOI.add_constraint(primal_model, 2.0 * x, MOI.GreaterThan(3.0))
            MOI.set(primal_model, MOI.ObjectiveSense(), sense)
            # `Max` needs a concave objective, hence the flipped `P`.
            P = sense == MOI.MIN_SENSE ? 4.0 : -4.0
            MOI.set(
                primal_model,
                MOI.ObjectiveFunction{MOI.ScalarQuadraticFunction{Float64}}(),
                MOI.ScalarQuadraticFunction(
                    [MOI.ScalarQuadraticTerm(P, x, x)],
                    [MOI.ScalarAffineTerm(11.0, x)],
                    13.0,
                ),
            )
            dual_model = Dualization.dualize(primal_model).dual_model
            ci = only(
                MOI.get(
                    dual_model,
                    MOI.ListOfConstraintIndices{
                        MOI.ScalarAffineFunction{Float64},
                        MOI.EqualTo{Float64},
                    }(),
                ),
            )
            f = MOI.get(dual_model, MOI.ConstraintFunction(), ci)
            set = MOI.get(dual_model, MOI.ConstraintSet(), ci)
            # The dual variable `y` comes first, then the slack `w`.
            @test MOI.coefficient.(f.terms) == [-2.0, w_coefficient]
            @test MOI.constant(f) - MOI.constant(set) == a_0
        end
    end
end
