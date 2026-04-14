# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

module TestAttributes

using Test

import MathOptInterface as MOI
import MathOptInterface.Utilities as MOIU
import Dualization
import SCS

function runtests()
    for name in names(@__MODULE__; all = true)
        if startswith("$(name)", "test_")
            @testset "$(name)" begin
                getfield(@__MODULE__, name)()
            end
        end
    end
    return
end

###
### Helper structs
###

struct DummyModelAttribute <: MOI.AbstractModelAttribute end

struct DummyVariableAttribute <: MOI.AbstractVariableAttribute end

struct DummyConstraintAttribute <: MOI.AbstractConstraintAttribute end

###
### The tests
###

function _test_constraint_attribute(; constrained_variable::Bool, vector::Bool)
    T = Float64
    function rand_value()
        value = rand(T)
        if vector
            return [value]
        end
        return value
    end
    mock = MOI.Utilities.MockOptimizer(
        MOI.Utilities.UniversalFallback(MOI.Utilities.Model{T}());
        eval_variable_constraint_dual = false,
    )
    dual = MOI.Utilities.CachingOptimizer(
        MOI.Utilities.UniversalFallback(MOI.Utilities.Model{T}()),
        MOI.Utilities.MANUAL, # easier to debug with less try-catch hidding stuff
    )
    MOI.Utilities.reset_optimizer(dual, Dualization.DualOptimizer(mock))
    set_constant = T(-4)
    if vector
        set = MOI.Nonnegatives(1)
    else
        set = MOI.GreaterThan(set_constant)
    end
    if constrained_variable
        if vector
            X, ci = MOI.add_constrained_variables(dual, set)
            x = X[]
        else
            x, ci = MOI.add_constrained_variable(dual, set)
        end
    else
        x = MOI.add_variable(dual)
        func = T(1) * x
        if vector
            func = MOI.Utilities.operate(vcat, T, func - set_constant)
        end
        ci = MOI.add_constraint(dual, func, set)
    end
    MOI.set(dual, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    obj = T(2) * x
    MOI.set(dual, MOI.ObjectiveFunction{typeof(obj)}(), obj)
    MOI.Utilities.attach_optimizer(dual)
    MOI.optimize!(dual)
    for attr in [MOI.ConstraintDualStart(), MOI.ConstraintPrimalStart()]
        attr = MOI.ConstraintDualStart()
        @test MOI.supports(dual, attr, typeof(ci))
        value = rand_value()
        if constrained_variable && vector
            # FIXME not supported yet
            @test_throws MOI.SetAttributeNotAllowed{MOI.ConstraintDualStart} MOI.set(
                dual,
                attr,
                ci,
                value,
            )
        else
            MOI.set(dual, attr, ci, value)
            @test MOI.get(dual, attr, ci) == value
        end
    end

    if vector && constrained_variable
        value = 2ones(T, 1)
    else
        value = rand(T)
        mock_vi = MOI.get(mock, MOI.ListOfVariableIndices())[]
        MOI.set(mock, MOI.VariablePrimal(), mock_vi, value)
        if vector
            value = [value]
        end
    end
    #MOI.set(mock, MOI.ConstraintPrimal(), mock_ci, value)
    @test MOI.get(dual.optimizer, MOI.ConstraintDual(), ci) ≈ value

    value = rand_value()
    if vector && constrained_variable
        F = MOI.VectorAffineFunction{T}
        mock_ci = MOI.get(mock, MOI.ListOfConstraintIndices{F,typeof(set)}())[]
    else
        F = vector ? MOI.VectorOfVariables : MOI.VariableIndex
        mock_ci = MOI.get(mock, MOI.ListOfConstraintIndices{F,typeof(set)}())[]
    end
    MOI.set(mock, MOI.ConstraintDual(), mock_ci, value)
    if !vector
        value += set_constant
    end
    @test MOI.get(dual.optimizer, MOI.ConstraintPrimal(), ci) ≈ value
    return
end

function test_constraint_attribute_VariableIndex()
    return _test_constraint_attribute(;
        constrained_variable = true,
        vector = false,
    )
end

function test_constraint_attribute_ScalarAffineFunction()
    return _test_constraint_attribute(;
        constrained_variable = false,
        vector = false,
    )
end

function test_constraint_attribute_VectorOfVariables()
    return _test_constraint_attribute(;
        constrained_variable = true,
        vector = true,
    )
end

function test_constraint_attribute_VectorAffineFunction()
    return _test_constraint_attribute(;
        constrained_variable = false,
        vector = true,
    )
end

function _test_fixed(T, dual_model)
    model = MOI.Utilities.UniversalFallback(MOI.Utilities.Model{T}())
    x, cx = MOI.add_constrained_variable(model, MOI.EqualTo(T(1)))
    c = MOI.add_constraint(model, T(2) * x, MOI.LessThan(T(3)))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

    MOI.set(model, MOI.VariablePrimalStart(), x, T(4))
    MOI.set(model, MOI.ConstraintPrimalStart(), c, T(5))
    MOI.set(model, MOI.ConstraintDualStart(), c, T(6))

    dual_problem = Dualization.DualProblem{T}(dual_model)
    OptimizerType = typeof(dual_problem.dual_model)
    dual = Dualization.DualOptimizer{T,OptimizerType}(dual_problem)
    @test MOI.supports(dual, MOI.VariablePrimalStart(), typeof(x))
    @test MOI.supports(dual, MOI.ConstraintDualStart(), typeof(c))
    @test MOI.supports(dual, MOI.ConstraintPrimalStart(), typeof(c))

    MOI.copy_to(dual, model)
    @test dual_model === dual.dual_problem.dual_model

    @test MOI.get(dual, MOI.VariablePrimalStart(), x) == 4
    @test MOI.get(dual, MOI.ConstraintPrimalStart(), cx) == 1
    @test isnothing(MOI.get(dual, MOI.ConstraintDualStart(), cx))
    @test MOI.get(dual, MOI.ConstraintPrimalStart(), c) == 5
    @test MOI.get(dual, MOI.ConstraintDualStart(), c) == 6
    return
end

function test_fixed()
    for T in [Int, Float64]
        dual_model = MOI.Utilities.UniversalFallback(MOI.Utilities.Model{T}())
        _test_fixed(T, dual_model)
    end
    dual_model = MOI.instantiate(
        SCS.Optimizer,
        with_bridge_type = nothing,
        with_cache_type = Float64,
    )
    _test_fixed(Float64, dual_model)
    return
end

function _test_simple(T, dual_model)
    model = MOI.Utilities.UniversalFallback(MOI.Utilities.Model{T}())
    x = MOI.add_variable(model)
    c = MOI.add_constraint(model, T(2) * x, MOI.GreaterThan(T(0)))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    MOI.set(model, MOI.VariablePrimalStart(), x, T(1))
    MOI.set(model, MOI.ConstraintPrimalStart(), c, T(3))
    MOI.set(model, MOI.ConstraintDualStart(), c, T(4))

    dual_problem = Dualization.DualProblem{T}(dual_model)
    OptimizerType = typeof(dual_problem.dual_model)
    dual = Dualization.DualOptimizer{T,OptimizerType}(dual_problem)

    @test MOI.supports(dual, MOI.VariablePrimalStart(), typeof(x))
    @test MOI.supports(dual, MOI.ConstraintDualStart(), typeof(c))
    @test MOI.supports(dual, MOI.ConstraintPrimalStart(), typeof(c))
    @test MOI.supports(dual, MOI.VariableName(), typeof(x))
    @test MOI.supports(dual, MOI.ConstraintName(), typeof(c))

    index_map = MOI.copy_to(dual, model)
    @test dual_model === dual.dual_problem.dual_model

    vars = MOI.get(dual_model, MOI.ListOfVariableIndices())
    @test MOI.get(dual_model, MOI.VariablePrimalStart(), vars[]) == 4

    dual_eq = MOI.get(
        dual_model,
        MOI.ListOfConstraintIndices{
            MOI.ScalarAffineFunction{T},
            MOI.EqualTo{T},
        }(),
    )[]
    @test MOI.get(dual, MOI.VariablePrimalStart(), x) == 1
    @test MOI.get(dual_model, MOI.ConstraintDualStart(), dual_eq) == -1
    # We could set it to zero, but `nothing` should be fine for the solver,
    # let's only revisit if we have a convincing use case
    @test isnothing(MOI.get(dual_model, MOI.ConstraintPrimalStart(), dual_eq))

    dual_bound = MOI.get(
        dual_model,
        MOI.ListOfConstraintIndices{MOI.VariableIndex,MOI.GreaterThan{T}}(),
    )[]
    @test MOI.get(dual_model, MOI.ConstraintDualStart(), dual_bound) == 3
    # We could set it to the value of the variable, but `nothing` should be fine for the solver.
    # Let's revisit only if we have a solver needing `ConstraintPrimalStart` for `VariableIndex`-in-`S`
    # constraints.
    @test isnothing(
        MOI.get(dual_model, MOI.ConstraintPrimalStart(), dual_bound),
    )

    MOI.set(dual, MOI.VariablePrimalStart(), vars[], nothing)
    @test isnothing(MOI.get(dual, MOI.VariablePrimalStart(), vars[]))
    return
end

function test_simple()
    for T in [Int, Float64]
        dual_model = MOI.Utilities.UniversalFallback(MOI.Utilities.Model{T}())
        _test_simple(T, dual_model)
    end
    dual_model = MOI.instantiate(
        SCS.Optimizer,
        with_bridge_type = nothing,
        with_cache_type = Float64,
    )
    _test_simple(Float64, dual_model)
    return
end

function _test_conic(T, dual_model, cone1, cone2)
    model = MOI.Utilities.UniversalFallback(MOI.Utilities.Model{T}())
    x, cx = MOI.add_constrained_variables(model, cone1)
    c = MOI.add_constraint(model, MOI.Utilities.vectorize(x .+ T(1)), cone2)
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    MOI.set.(model, MOI.VariablePrimalStart(), x, T.(1:2))
    MOI.set(model, MOI.ConstraintPrimalStart(), cx, T.(3:4))
    MOI.set(model, MOI.ConstraintDualStart(), cx, T.(4:5))
    MOI.set(model, MOI.ConstraintPrimalStart(), c, T.(6:7))
    MOI.set(model, MOI.ConstraintDualStart(), c, T.(8:9))

    dual_problem = Dualization.DualProblem{T}(dual_model)
    OptimizerType = typeof(dual_problem.dual_model)
    dual = Dualization.DualOptimizer{T,OptimizerType}(dual_problem)
    @test MOI.supports(dual, MOI.VariablePrimalStart(), eltype(x))
    @test MOI.supports(dual, MOI.ConstraintDualStart(), typeof(cx))
    @test MOI.supports(dual, MOI.ConstraintPrimalStart(), typeof(cx))
    @test MOI.supports(dual, MOI.ConstraintDualStart(), typeof(c))
    @test MOI.supports(dual, MOI.ConstraintPrimalStart(), typeof(c))

    attr = MOI.VariablePrimalStart()
    msg = "Setting $attr for variables constrained at creation is not supported yet"
    err = MOI.SetAttributeNotAllowed(attr, msg)
    @test_throws err MOI.copy_to(dual, model)

    MOI.set.(model, MOI.VariablePrimalStart(), x, [nothing, nothing])
    attr1 = MOI.ConstraintPrimalStart()
    attr2 = MOI.ConstraintDualStart()
    msg1 = "Setting $attr1 for variables constrained at creation is not supported yet"
    msg2 = "Setting $attr2 for variables constrained at creation is not supported yet"
    err1 = MOI.SetAttributeNotAllowed(attr1, msg1)
    err2 = MOI.SetAttributeNotAllowed(attr2, msg2)
    @test_throws Union{typeof(err1),typeof(err2)} MOI.copy_to(dual, model)

    MOI.set(model, MOI.ConstraintPrimalStart(), cx, nothing)
    MOI.set(model, MOI.ConstraintDualStart(), cx, nothing)
    MOI.copy_to(dual, model)

    @test dual_model === dual.dual_problem.dual_model

    vars = MOI.get(dual_model, MOI.ListOfVariableIndices())
    @test MOI.get(dual_model, MOI.VariablePrimalStart(), vars) == T[8, 9]

    if !(cone2 isa MOI.Zeros)
        dual_c = MOI.get(
            dual_model,
            MOI.ListOfConstraintIndices{MOI.VectorOfVariables,typeof(cone2)}(),
        )[]
        @test isnothing(
            MOI.get(dual_model, MOI.ConstraintPrimalStart(), dual_c),
        )
        @test MOI.get(dual_model, MOI.ConstraintDualStart(), dual_c) == T[6, 7]
    end

    @test MOI.get(model, MOI.ConstraintPrimalStart(), c) == T.(6:7)
    @test MOI.get(model, MOI.ConstraintDualStart(), c) == T.(8:9)
    return
end

function test_conic()
    cones = [MOI.SecondOrderCone(2), MOI.Zeros(2)]
    for cone1 in cones
        for cone2 in cones
            for T in [Float32, Float64]
                dual_model =
                    MOI.Utilities.UniversalFallback(MOI.Utilities.Model{T}())
                _test_conic(T, dual_model, cone1, cone2)
            end
            dual_model = MOI.instantiate(
                SCS.Optimizer,
                with_bridge_type = nothing,
                with_cache_type = Float64,
            )
            _test_conic(Float64, dual_model, cone1, cone2)
        end
    end
    return
end

end  # module

TestAttributes.runtests()
