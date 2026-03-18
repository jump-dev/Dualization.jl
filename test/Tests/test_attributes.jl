# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

module TestAttributes

using Test

import MathOptInterface as MOI
import MathOptInterface.Utilities as MOIU
import Dualization

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
        MOI.set(dual, attr, ci, value)
        @test MOI.get(dual, attr, ci) == value
    end

    if vector && constrained_variable
        value = zeros(T, 1)
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

end  # module

TestAttributes.runtests()
