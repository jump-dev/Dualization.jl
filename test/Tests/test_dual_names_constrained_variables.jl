# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

#=
Tests for the name of the dual constraint associated with a vector of
constrained variables.

The dual object is a single constraint while the primal side is a vector of
variables, so one name has to be derived from several. When the variables are
all entries of the same container, the name of the container is used, otherwise
the name of the first variable is.
=#

function _soc_constrained_variables_model(names::Vector{String})
    model = MOI.Utilities.Model{Float64}()
    x, _ =
        MOI.add_constrained_variables(model, MOI.SecondOrderCone(length(names)))
    for (vi, name) in zip(x, names)
        MOI.set(model, MOI.VariableName(), vi, name)
    end
    MOI.add_constraint(
        model,
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.(1.0, x), 0.0),
        MOI.EqualTo(1.0),
    )
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    MOI.set(
        model,
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(),
        MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(1.0, first(x))], 0.0),
    )
    return model
end

function _dual_soc_constraint_name(model, dual_names)
    dual_model = dualize(model; dual_names = dual_names).dual_model
    ci = only(
        MOI.get(
            dual_model,
            MOI.ListOfConstraintIndices{
                MOI.VectorAffineFunction{Float64},
                MOI.SecondOrderCone,
            }(),
        ),
    )
    return MOI.get(dual_model, MOI.ConstraintName(), ci)
end

@testset "names for constrained variables" begin
    @testset "_container_name" begin
        # All the names are entries of the same container.
        @test Dualization._container_name(["x[1]", "x[2]", "x[3]"]) == "x"
        @test Dualization._container_name(["y[1,1]", "y[2,1]"]) == "y"
        @test Dualization._container_name(["x[1]"]) == "x"
        # Containers with a Unicode name are sliced at the right offset.
        @test Dualization._container_name(["λ[1]", "λ[2]"]) == "λ"
        # Not all the names belong to the same container.
        @test Dualization._container_name(["x[1]", "y[2]"]) === nothing
        # No index at all.
        @test Dualization._container_name(["a", "b"]) === nothing
        @test Dualization._container_name(["x[1]", "y"]) === nothing
        # A name that is only an index has no container.
        @test Dualization._container_name(["[1]", "[2]"]) === nothing
        # An unnamed variable.
        @test Dualization._container_name([""]) === nothing
        # No variable at all.
        @test Dualization._container_name(String[]) === nothing
    end

    @testset "container name is used" begin
        # `@variable(model, x[1:3] in SecondOrderCone())` names the variables
        # `x[i]` and leaves the name of the constraint empty, so the dual
        # constraint takes the name of the container.
        model = _soc_constrained_variables_model(["x[1]", "x[2]", "x[3]"])
        @test _dual_soc_constraint_name(
            model,
            DualNames(; constraint_prefix = "dc_"),
        ) == "dc_x"
        # The mapping applies to the container name too.
        @test _dual_soc_constraint_name(
            model,
            DualNames(; mapping = ["x" => "α"]),
        ) == "α"
    end

    @testset "first variable name is the fallback" begin
        # Unrelated variables have no common container.
        model = _soc_constrained_variables_model(["a", "b", "c"])
        @test _dual_soc_constraint_name(
            model,
            DualNames(; constraint_prefix = "dc_"),
        ) == "dc_a"
        # Entries of different containers, likewise.
        model = _soc_constrained_variables_model(["x[1]", "y[1]", "z[1]"])
        @test _dual_soc_constraint_name(
            model,
            DualNames(; constraint_prefix = "dc_"),
        ) == "dc_x[1]"
    end

    @testset "unnamed primal stays unnamed" begin
        # An empty primal name must not produce a name made of the sole prefix.
        model = _soc_constrained_variables_model(["", "", ""])
        @test _dual_soc_constraint_name(
            model,
            DualNames(; constraint_prefix = "dc_"),
        ) == ""
        # And nothing is named at all without `dual_names`.
        @test _dual_soc_constraint_name(
            _soc_constrained_variables_model(["x[1]", "x[2]", "x[3]"]),
            Dualization.EMPTY_DUAL_NAMES,
        ) == ""
    end

    @testset "no warning is emitted" begin
        # Naming a vector of constrained variables used to warn that it was not
        # supported, see https://github.com/jump-dev/Dualization.jl/issues/193.
        model = _soc_constrained_variables_model(["x[1]", "x[2]", "x[3]"])
        @test_logs dualize(
            model;
            dual_names = DualNames(; constraint_prefix = "dc_"),
        )
    end
end
