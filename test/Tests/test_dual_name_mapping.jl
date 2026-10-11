# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

#=
Tests for the `mapping` field of `DualNames`.

The names of the dual objects are derived from the names of the primal objects
they come from. `mapping` rewrites those names instead of prefixing them; the
primal model itself is never modified.
=#

@testset "DualNames mapping" begin
    @testset "dual_name" begin
        names = DualNames(; mapping = ["affine_cons" => "α"])
        # The entry is applied only at the beginning of the name, so the index
        # part of a container name is preserved.
        for f in [
            Dualization._dual_variable_name,
            Dualization._dual_constraint_name,
            Dualization._dual_parameter_name,
            Dualization._dual_quadratic_slack_name,
        ]
            @test f(names, "affine_cons[1]") == "α[1]"
            @test f(names, "affine_cons") == "α"
            # The entry only matches a prefix, not an inner occurrence.
            # Note that the parameters and the quadratic slacks fall back to
            # their default prefix when the mapping does not match.
            @test endswith(f(names, "x_affine_cons"), "x_affine_cons")
        end
        # Entries are tried in order and the first match is applied, so a more
        # specific entry must come before a more general one.
        ordered = DualNames(; mapping = ["ab" => "1", "a" => "2"])
        @test Dualization._dual_variable_name(ordered, "abc") == "1c"
        @test Dualization._dual_variable_name(ordered, "acb") == "2cb"
        # Reversing the order lets the general entry shadow the specific one.
        shadowed = DualNames(; mapping = ["a" => "2", "ab" => "1"])
        @test Dualization._dual_variable_name(shadowed, "abc") == "2bc"
        # Unicode entries are sliced by byte offset, not by character index.
        unicode = DualNames(; mapping = ["λμ" => "y"])
        @test Dualization._dual_variable_name(unicode, "λμ[2]") == "y[2]"
    end

    @testset "prefixes are the fallback" begin
        names = DualNames(;
            variable_prefix = "dual_var_",
            constraint_prefix = "dual_con_",
            mapping = ["mapped" => "α"],
        )
        # A mapped name is renamed and *not* prefixed.
        @test Dualization._dual_variable_name(names, "mapped[1]") == "α[1]"
        @test Dualization._dual_constraint_name(names, "mapped") == "α"
        # An unmapped name falls back to the prefix of its kind.
        @test Dualization._dual_variable_name(names, "other") ==
              "dual_var_other"
        @test Dualization._dual_constraint_name(names, "other") ==
              "dual_con_other"
        # The historical defaults of parameters and quadratic slacks are still
        # applied when they are not mapped, and are bypassed when they are.
        @test Dualization._dual_parameter_name(names, "other") == "param_other"
        @test Dualization._dual_quadratic_slack_name(names, "other") ==
              "quadslack_other"
        @test Dualization._dual_parameter_name(names, "mapped") == "α"
        @test Dualization._dual_quadratic_slack_name(names, "mapped") == "α"
        custom = DualNames(;
            variable_prefix = "v",
            constraint_prefix = "c",
            parameter_prefix = "par_",
            quadratic_slack_prefix = "slack_",
        )
        @test Dualization._dual_parameter_name(custom, "p") == "par_p"
        @test Dualization._dual_quadratic_slack_name(custom, "q") == "slack_q"
        @test Dualization._dual_variable_name(custom, "x") == "vx"
        @test Dualization._dual_constraint_name(custom, "c") == "cc"
    end

    @testset "constructors and is_empty" begin
        # The keyword constructor is the documented one.
        @test isempty(DualNames().mapping)
        @test DualNames(; variable_prefix = "v").dual_variable_name_prefix ==
              "v"
        @test DualNames(;
            constraint_prefix = "c",
        ).dual_constraint_name_prefix == "c"
        @test DualNames(; parameter_prefix = "p").parameter_name_prefix == "p"
        @test DualNames(;
            quadratic_slack_prefix = "s",
        ).quadratic_slack_name_prefix == "s"
        # `mapping` alone is enough, no prefix required.
        only_mapping = DualNames(; mapping = ["a" => "b"])
        @test only_mapping.mapping == ["a" => "b"]
        @test only_mapping.dual_variable_name_prefix == ""
        # Any iterable of pairs is accepted and normalized to a vector.
        @test DualNames(; mapping = ("a" => "b",)).mapping == ["a" => "b"]
        @test DualNames(; mapping = Dict("a" => "b")).mapping == ["a" => "b"]
        @test DualNames(; mapping = ["a" => "b"]).mapping isa
              Vector{Pair{String,String}}
        # The legacy positional constructors keep working.
        @test DualNames("v", "c").dual_variable_name_prefix == "v"
        @test DualNames("v", "c").dual_constraint_name_prefix == "c"
        @test isempty(DualNames("v", "c").mapping)
        legacy = DualNames("v", "c", "p", "s")
        @test legacy.parameter_name_prefix == "p"
        @test legacy.quadratic_slack_name_prefix == "s"
        # `is_empty` is an identity check against the sentinel used as the
        # default of the `dual_names` keyword, so the sentinel is the only
        # `DualNames` that names nothing. In particular a `DualNames()` built
        # by the user is *not* empty: it asks for the dual model to be named
        # with the fallback prefixes.
        @test Dualization.is_empty(Dualization.EMPTY_DUAL_NAMES)
        @test !Dualization.is_empty(DualNames())
        @test !Dualization.is_empty(DualNames("", ""))
        @test !Dualization.is_empty(DualNames(; mapping = ["a" => "b"]))
        @test !Dualization.is_empty(DualNames("v", "c"))
        @test !Dualization.is_empty(DualNames(; parameter_prefix = "p"))
        @test !Dualization.is_empty(DualNames(; quadratic_slack_prefix = "s"))
    end

    @testset "DualNames() names the dual model" begin
        #=
        Regression test: `DualNames()` must keep naming the dual model, while
        omitting `dual_names` entirely must leave it unnamed. Making `is_empty`
        compare the fields instead of the identity silently collapses the two
        and drops every name, including the `param_`/`quadslack_` defaults.
        =#
        model = Model()
        @variable(model, x)
        @variable(model, p in Parameter(2.0))
        @constraint(model, c, x <= p)
        @objective(model, Max, 3x + x^2)
        named = dualize(model; dual_names = DualNames())
        param = Dualization._get_dual_parameter(named, p)
        @test MOI.get(named, MOI.VariableName(), param) == "param_p"
        slack = Dualization._get_dual_slack_variable(named, x)
        @test MOI.get(named, MOI.VariableName(), slack) == "quadslack_x"
        dual_var = Dualization._get_dual_variables(named, c)[]
        @test MOI.get(named, MOI.VariableName(), dual_var) == "c"
        # Omitting `dual_names` leaves everything unnamed.
        unnamed = dualize(model)
        for v in all_variables(unnamed)
            @test MOI.get(unnamed, MOI.VariableName(), v) == ""
        end
    end

    @testset "dualize" begin
        #=
        primal
            min λ
        s.t.
            λ - c[j] >= 0, j = 1, 2, 3  :affine_cons[j]

        Renaming `affine_cons` to `α` must give the dual constraint
        `α[1] + α[2] + α[3] == 1` associated with the primal variable `λ`.
        =#
        model = MOI.Utilities.Model{Float64}()
        λ = MOI.add_variable(model)
        MOI.set(model, MOI.VariableName(), λ, "λ")
        for j in 1:3
            ci = MOI.add_constraint(
                model,
                MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(1.0, λ)], 0.0),
                MOI.GreaterThan(Float64(j)),
            )
            MOI.set(model, MOI.ConstraintName(), ci, "affine_cons[$j]")
        end
        MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
        MOI.set(
            model,
            MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(),
            MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(1.0, λ)], 0.0),
        )

        function _dual_names(dual_model)
            return Set(
                MOI.get(dual_model, MOI.VariableName(), vi) for
                vi in MOI.get(dual_model, MOI.ListOfVariableIndices())
            )
        end

        function _get_dual_constraint_name(dual_model)
            ci = only(
                MOI.get(
                    dual_model,
                    MOI.ListOfConstraintIndices{
                        MOI.ScalarAffineFunction{Float64},
                        MOI.EqualTo{Float64},
                    }(),
                ),
            )
            return MOI.get(dual_model, MOI.ConstraintName(), ci)
        end

        dual = dualize(
            model;
            dual_names = DualNames(; mapping = ["affine_cons" => "α"]),
        )
        @test _dual_names(dual.dual_model) == Set(["α[1]", "α[2]", "α[3]"])
        # `λ` is not mapped and the prefixes are empty, so the dual constraint
        # keeps the name of the primal variable.
        @test _get_dual_constraint_name(dual.dual_model) == "λ"
        # The primal model is left untouched.
        @test MOI.get(model, MOI.VariableName(), λ) == "λ"

        # Mapping the primal variable too renames the dual constraint.
        dual = dualize(
            model;
            dual_names = DualNames(;
                mapping = ["affine_cons" => "α", "λ" => "stationarity"],
            ),
        )
        @test _get_dual_constraint_name(dual.dual_model) == "stationarity"

        # Mixing the two: the mapping covers the constraints and the prefixes
        # take care of everything else.
        dual = dualize(
            model;
            dual_names = DualNames(;
                variable_prefix = "dual_var_",
                constraint_prefix = "dual_con_",
                mapping = ["affine_cons" => "α"],
            ),
        )
        @test _dual_names(dual.dual_model) == Set(["α[1]", "α[2]", "α[3]"])
        @test _get_dual_constraint_name(dual.dual_model) == "dual_con_λ"

        # The default `dual_names` names nothing.
        @test all(isempty, _dual_names(dualize(model).dual_model))
        # But an explicit `DualNames()` does name: with no prefix and no
        # mapping, the dual variables simply take the name of the primal
        # constraint they come from.
        dual = dualize(model; dual_names = DualNames())
        @test _dual_names(dual.dual_model) ==
              Set(["affine_cons[1]", "affine_cons[2]", "affine_cons[3]"])
    end

    @testset "parameters and quadratic slacks" begin
        #=
        A mapping alone enables the naming, and the parameters and quadratic
        slacks still fall back to their default prefixes, because the name of
        the primal variable they come from is already taken by a dual
        constraint.
        =#
        model = MOI.Utilities.Model{Float64}()
        x = MOI.add_variable(model)
        p = MOI.add_variable(model)
        MOI.set(model, MOI.VariableName(), x, "x")
        MOI.set(model, MOI.VariableName(), p, "p")
        MOI.add_constraint(model, p, MOI.Parameter(2.0))
        ci = MOI.add_constraint(
            model,
            MOI.ScalarAffineFunction(
                [MOI.ScalarAffineTerm(1.0, x), MOI.ScalarAffineTerm(-1.0, p)],
                0.0,
            ),
            MOI.LessThan(0.0),
        )
        MOI.set(model, MOI.ConstraintName(), ci, "c")
        MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
        MOI.set(
            model,
            MOI.ObjectiveFunction{MOI.ScalarQuadraticFunction{Float64}}(),
            MOI.ScalarQuadraticFunction(
                [MOI.ScalarQuadraticTerm(-2.0, x, x)],
                [MOI.ScalarAffineTerm(3.0, x)],
                0.0,
            ),
        )
        dual = dualize(model; dual_names = DualNames(; mapping = ["c" => "γ"]))
        names = Set(
            MOI.get(dual.dual_model, MOI.VariableName(), vi) for
            vi in MOI.get(dual.dual_model, MOI.ListOfVariableIndices())
        )
        @test names == Set(["γ", "param_p", "quadslack_x"])
    end

    @testset "dualize vector constraint suffix" begin
        #=
        A vector constraint creates one dual variable per row, which are
        distinguished by a `_i` suffix appended after the renaming.
        =#
        model = MOI.Utilities.Model{Float64}()
        x = MOI.add_variables(model, 3)
        ci = MOI.add_constraint(
            model,
            MOI.VectorAffineFunction(
                [
                    MOI.VectorAffineTerm(i, MOI.ScalarAffineTerm(1.0, x[i])) for i in 1:3
                ],
                zeros(3),
            ),
            MOI.Nonnegatives(3),
        )
        MOI.set(model, MOI.ConstraintName(), ci, "vec_cons")
        MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
        MOI.set(
            model,
            MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(),
            MOI.ScalarAffineFunction(
                [MOI.ScalarAffineTerm(1.0, x[i]) for i in 1:3],
                0.0,
            ),
        )
        dual = dualize(
            model;
            dual_names = DualNames(; mapping = ["vec_cons" => "γ"]),
        )
        names = Set(
            MOI.get(dual.dual_model, MOI.VariableName(), vi) for
            vi in MOI.get(dual.dual_model, MOI.ListOfVariableIndices())
        )
        @test names == Set(["γ_1", "γ_2", "γ_3"])
    end
end
