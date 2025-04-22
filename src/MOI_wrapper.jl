# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

export DualOptimizer, dual_optimizer

function dual_optimizer(
    optimizer_constructor;
    coefficient_type::Type{T} = Float64,
) where {T<:Number}
    return () -> DualOptimizer{T}(MOI.instantiate(optimizer_constructor))
end

struct DualOptimizer{T,OT<:MOI.ModelLike} <: MOI.AbstractOptimizer
    dual_problem::DualProblem{T,OT}

    function DualOptimizer{T,OT}(
        dual_problem::DualProblem{T,OT},
    ) where {T,OT<:MOI.ModelLike}
        return new{T,OT}(dual_problem)
    end
end

"""
    DualOptimizer(dual_optimizer::OT) where {OT <: MOI.ModelLike}

The DualOptimizer finds the solution for a problem by solving its dual
representation. It builds the dual model internally and solve it using the
`dual_optimizer` as the solver.

Primal results are obtained by querying dual results of the internal problem
solved by `dual_optimizer`. Analogously, dual results are obtained by querying
primal results of the internal problem.

The user can define the model providing the `DualOptimizer` and the solver of
its choice.

## Example

```julia
julia> using Dualization, JuMP, HiGHS

julia> model = Model(dual_optimizer(HiGHS.Optimizer))
A JuMP Model
Feasibility problem with:
Variables: 0
Model mode: AUTOMATIC
CachingOptimizer state: EMPTY_OPTIMIZER
Solver name: Dual model with HiGHS attached
```
"""
function DualOptimizer(dual_optimizer::OT) where {OT<:MOI.ModelLike}
    return DualOptimizer{Float64}(dual_optimizer)
end

function DualOptimizer{T}(dual_optimizer::OT) where {T,OT<:MOI.ModelLike}
    dual_problem = DualProblem{T}(
        MOI.Bridges.full_bridge_optimizer(
            MOI.Utilities.CachingOptimizer(
                MOI.Utilities.UniversalFallback(DualizableModel{T}()),
                dual_optimizer,
            ),
            T,
        ),
    )
    # discover the type of
    # MOI.Utilities.CachingOptimizer(DualizableModel{T}(), dual_optimizer)
    OptimizerType = typeof(dual_problem.dual_model)
    return DualOptimizer{T,OptimizerType}(dual_problem)
end

DualOptimizer() = error("DualOptimizer must have a solver attached")

MOI.supports(::DualOptimizer, ::MOI.ObjectiveSense) = true

function MOI.supports(
    optimizer::DualOptimizer{T},
    ::MOI.ObjectiveFunction{F},
) where {T,F}
    # If the objective function is `MOI.VariableIndex` or
    # `MOI.ScalarAffineFunction`, then a `MOI.ScalarAffineFunction` is set as
    # the objective function for the dual problem.
    # If it is `MOI.ScalarQuadraticFunction` , a `MOI.ScalarQuadraticFunction`
    # is set as objective function for the dual problem.
    attr = if F <: MOI.ScalarQuadraticFunction
        MOI.ObjectiveFunction{MOI.ScalarQuadraticFunction{T}}()
    else
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{T}}()
    end
    return supported_objective(F) &&
           MOI.supports(optimizer.dual_problem.dual_model, attr)
end

function MOI.supports_constraint(
    optimizer::DualOptimizer{T},
    ::Type{<:Union{MOI.VariableIndex,MOI.ScalarAffineFunction{T}}},
    S::Type{<:MOI.AbstractScalarSet},
) where {T}
    D = _dual_set_type(S)
    if D === nothing
        return false
    end
    model = optimizer.dual_problem.dual_model
    if D <: MOI.AbstractVectorSet # The dual of `EqualTo` is `Reals`
        return MOI.supports_add_constrained_variables(model, D)
    else
        return MOI.supports_add_constrained_variable(model, D)
    end
end

function MOI.supports_constraint(
    optimizer::DualOptimizer{T},
    ::Type{<:Union{MOI.VectorOfVariables,MOI.VectorAffineFunction{T}}},
    S::Type{<:MOI.AbstractVectorSet},
) where {T}
    D = _dual_set_type(S)
    if D === nothing
        return false
    end
    model = optimizer.dual_problem.dual_model
    return MOI.supports_add_constrained_variables(model, D)
end

function _change_constant(
    model,
    ci::MOI.ConstraintIndex{<:MOI.ScalarAffineFunction,S},
    constant,
    ::Int,
) where {S}
    MOI.set(model, MOI.ConstraintSet(), ci, S(constant))
    return
end

function _change_constant(
    model,
    ci::MOI.ConstraintIndex{<:MOI.VectorAffineFunction},
    constant,
    idx::Int,
)
    func = MOI.get(model, MOI.ConstraintFunction(), ci)
    constants = copy(func.constant)
    constants[idx] = -constant
    MOI.modify(model, ci, MOI.VectorConstantChange(constants))
    return
end

function MOI.modify(
    optimizer::DualOptimizer{T},
    ::MOI.ObjectiveFunction{MOI.ScalarAffineFunction{T}},
    obj_change::MOI.ScalarCoefficientChange{T},
) where {T}
    primal_dual_map = optimizer.dual_problem.primal_dual_map
    # We must find the constraint corresponding to the variable in the objective
    # function and change its coefficient on the constraint.
    constant = obj_change.new_coefficient
    if MOI.get(optimizer.dual_problem.dual_model, MOI.ObjectiveSense()) ==
       MOI.MIN_SENSE
        constant = -constant
    end
    vi = obj_change.variable
    # if haskey(primal_dual_map.primal_convar_to_primal_convarcon_and_index, vi)
    #     ci_primal, index =
    #         primal_dual_map.primal_convar_to_primal_convarcon_and_index[vi]
    #     ci_dual = primal_dual_map.primal_convarcon_to_dual_con[ci_primal]
    #     if ci_dual === NO_CONSTRAINT
    #         return
    #     end
    #     constant = -constant
    # else
    #     ci_dual = primal_dual_map.primal_var_to_dual_con[vi]
    #     index = 1
    # end
    data = get(primal_dual_map.primal_variable_data, vi, nothing)
    if data === nothing
        # error
    elseif data.dual_constraint == NO_CONSTRAINT
        return
    end
    _change_constant(
        optimizer.dual_problem.dual_model,
        data.dual_constraint,
        constant,
        data.primal_constrained_variable_index,
    )
    return
end

function MOI.supports_add_constrained_variables(
    optimizer::DualOptimizer{T},
    S::Type{MOI.Reals},
) where {T}
    return MOI.supports_constraint(
        optimizer.dual_problem.dual_model,
        MOI.ScalarAffineFunction{T},
        MOI.EqualTo{T},
    )
    # If `_dual_set_type(MOI.Reals)` was `MOI.Zeros`,
    # we would not need this method as special case of the one below
end

function MOI.supports_add_constrained_variables(
    optimizer::DualOptimizer{T},
    S::Type{<:MOI.AbstractVectorSet},
) where {T}
    D = _dual_set_type(S)
    if D === nothing
        return false
    end
    return MOI.supports_constraint(
        optimizer.dual_problem.dual_model,
        MOI.VectorAffineFunction{T},
        D,
    )
end

function MOI.copy_to(dest::DualOptimizer, src::MOI.ModelLike)
    dualize(src, dest.dual_problem)
    idx_map = MOI.Utilities.IndexMap()
    for vi in MOI.get(src, MOI.ListOfVariableIndices())
        setindex!(idx_map, vi, vi)
    end
    for (F, S) in MOI.get(src, MOI.ListOfConstraintTypesPresent())
        for con in MOI.get(src, MOI.ListOfConstraintIndices{F,S}())
            setindex!(idx_map, con, con)
        end
    end
    return idx_map
end

function MOI.optimize!(optimizer::DualOptimizer)
    return MOI.optimize!(optimizer.dual_problem.dual_model)
end

function MOI.is_empty(optimizer::DualOptimizer)
    return (MOI.is_empty(optimizer.dual_problem.dual_model)) &&
           is_empty(optimizer.dual_problem.primal_dual_map)
end

function MOI.empty!(optimizer::DualOptimizer)
    MOI.empty!(optimizer.dual_problem.dual_model)
    empty!(optimizer.dual_problem.primal_dual_map)
    return
end

function MOI.get(optimizer::DualOptimizer, ::MOI.SolverName)
    name = MOI.get(optimizer.dual_problem.dual_model, MOI.SolverName())
    return "Dual model with $name attached"
end

function MOI.get(
    optimizer::DualOptimizer{T},
    ::MOI.VariablePrimal,
    vi::MOI.VariableIndex,
)::T where {T}
    primal_dual_map = optimizer.dual_problem.primal_dual_map
    data = get(primal_dual_map.primal_variable_data, vi, nothing)
    if data === nothing
        # error
    elseif data.dual_constraint == NO_CONSTRAINT
        return zero(T)
    elseif data.primal_constrained_variable_constraint === nothing
        return -MOI.get(
            optimizer.dual_problem.dual_model,
            MOI.ConstraintDual(),
            primal_dual_map.primal_var_to_dual_con[vi],
        )
    elseif data.dual_constraint isa MOI.ConstraintIndex{<:MOI.AbstractVectorFunction}
        return MOI.get(
                optimizer.dual_problem.dual_model,
                MOI.ConstraintDual(),
                data.dual_constraint,
            )[data.primal_constrained_variable_index]
    else
        return MOI.get(
                optimizer.dual_problem.dual_model,
                MOI.ConstraintDual(),
                ci_dual,
            )
    end
    # if haskey(primal_dual_map.primal_convar_to_primal_convarcon_and_index, vi)
    #     ci_primal, idx =
    #         primal_dual_map.primal_convar_to_primal_convarcon_and_index[vi]
    #     ci_dual = primal_dual_map.primal_convarcon_to_dual_con[ci_primal]
    #     if ci_dual === NO_CONSTRAINT
    #         return zero(T)
    #     elseif ci_dual isa MOI.ConstraintIndex{<:MOI.AbstractVectorFunction}
    #         return MOI.get(
    #             optimizer.dual_problem.dual_model,
    #             MOI.ConstraintDual(),
    #             ci_dual,
    #         )[idx]
    #     else
    #         return MOI.get(
    #             optimizer.dual_problem.dual_model,
    #             MOI.ConstraintDual(),
    #             ci_dual,
    #         )
    #     end
    # else
    #     return -MOI.get(
    #         optimizer.dual_problem.dual_model,
    #         MOI.ConstraintDual(),
    #         primal_dual_map.primal_var_to_dual_con[vi],
    #     )
    # end
end

function MOI.get(
    optimizer::DualOptimizer,
    ::MOI.ConstraintDual,
    ci::MOI.ConstraintIndex{F,S},
) where {F<:MOI.AbstractScalarFunction,S<:MOI.AbstractScalarSet}
    primal_dual_map = optimizer.dual_problem.primal_dual_map
    if haskey(primal_dual_map.primal_convarcon_to_dual_con, ci)
        ci_dual = primal_dual_map.primal_convarcon_to_dual_con[ci]
        if ci_dual === NO_CONSTRAINT
            return MOI.Utilities.eval_variables(
                primal_dual_map.primal_convarcon_to_dual_function[ci],
            ) do vi
                return MOI.get(
                    optimizer.dual_problem.dual_model,
                    MOI.VariablePrimal(),
                    vi,
                )
            end
        end
        set = MOI.get(
            optimizer.dual_problem.dual_model,
            MOI.ConstraintSet(),
            ci_dual,
        )
        return MOI.get(
            optimizer.dual_problem.dual_model,
            MOI.ConstraintPrimal(),
            ci_dual,
        ) - MOI.constant(set)
    else
        return MOI.get(
            optimizer.dual_problem.dual_model,
            MOI.VariablePrimal(),
            primal_dual_map.primal_con_to_dual_var_vec[ci][],
        )
    end
end

function MOI.get(
    optimizer::DualOptimizer,
    ::MOI.ConstraintDual,
    ci::MOI.ConstraintIndex{F,S},
) where {F<:MOI.AbstractVectorFunction,S<:MOI.AbstractVectorSet}
    primal_dual_map = optimizer.dual_problem.primal_dual_map
    if haskey(primal_dual_map.primal_convarcon_to_dual_con, ci)
        ci_dual = primal_dual_map.primal_convarcon_to_dual_con[ci]
        if ci_dual === NO_CONSTRAINT
            return MOI.Utilities.eval_variables(
                primal_dual_map.primal_convarcon_to_dual_function[ci],
            ) do vi
                return MOI.get(
                    optimizer.dual_problem.dual_model,
                    MOI.VariablePrimal(),
                    vi,
                )
            end
        end
        return MOI.get(
            optimizer.dual_problem.dual_model,
            MOI.ConstraintPrimal(),
            primal_dual_map.primal_convarcon_to_dual_con[ci],
        )
    else
        return MOI.get.(
            optimizer.dual_problem.dual_model,
            MOI.VariablePrimal(),
            primal_dual_map.primal_con_to_dual_var_vec[ci],
        )
    end
end

function MOI.get(
    optimizer::DualOptimizer{T},
    ::MOI.ConstraintPrimal,
    ci::MOI.ConstraintIndex{F,S},
) where {T,F<:MOI.AbstractScalarFunction,S<:MOI.AbstractScalarSet}
    primal_dual_map = optimizer.dual_problem.primal_dual_map
    if haskey(primal_dual_map.primal_convarcon_to_dual_con, ci)
        ci_dual = primal_dual_map.primal_convarcon_to_dual_con[ci]
        if ci_dual === NO_CONSTRAINT
            return zero(T)
        else
            return MOI.get(
                optimizer.dual_problem.dual_model,
                MOI.ConstraintDual(),
                ci_dual,
            )
        end
    else
        primal_ci_constant =
            primal_dual_map.primal_con_to_primal_constants_vec[ci][1]
        # If it has no key then there is no dual constraint
        if !haskey(primal_dual_map.primal_con_to_dual_convarcon, ci)
            return -primal_ci_constant
        end
        ci_dual_problem = primal_dual_map.primal_con_to_dual_convarcon[ci]
        return MOI.get(
            optimizer.dual_problem.dual_model,
            MOI.ConstraintDual(),
            ci_dual_problem,
        ) - primal_ci_constant
    end
end

function MOI.get(
    optimizer::DualOptimizer{T},
    ::MOI.ConstraintPrimal,
    ci::MOI.ConstraintIndex{F,S},
) where {T,F<:MOI.AbstractVectorFunction,S<:MOI.AbstractVectorSet}
    primal_dual_map = optimizer.dual_problem.primal_dual_map
    if haskey(primal_dual_map.primal_convarcon_to_dual_con, ci)
        ci_dual = primal_dual_map.primal_convarcon_to_dual_con[ci]
        if ci_dual === NO_CONSTRAINT
            n = MOI.output_dimension(
                primal_dual_map.primal_convarcon_to_dual_function[ci],
            )
            return zeros(T, n)
        else
            return MOI.get(
                optimizer.dual_problem.dual_model,
                MOI.ConstraintDual(),
                ci_dual,
            )
        end
    else
        # If it has no key then there is no dual constraint
        if !haskey(primal_dual_map.primal_con_to_dual_convarcon, ci)
            # The number of dual variable associated with the primal constraint is the ci dimension
            ci_dimension =
                length(primal_dual_map.primal_con_to_dual_var_vec[ci])
            return zeros(T, ci_dimension)
        end
        ci_dual_problem = primal_dual_map.primal_con_to_dual_convarcon[ci]
        return MOI.get(
            optimizer.dual_problem.dual_model,
            MOI.ConstraintDual(),
            ci_dual_problem,
        )
    end
end

function MOI.get(optimizer::DualOptimizer, ::MOI.TerminationStatus)
    return _dual_status(
        MOI.get(optimizer.dual_problem.dual_model, MOI.TerminationStatus()),
    )
end

function _dual_status(term::MOI.TerminationStatusCode)
    if term == MOI.INFEASIBLE
        return MOI.DUAL_INFEASIBLE
    elseif term == MOI.DUAL_INFEASIBLE
        return MOI.INFEASIBLE
    elseif term == MOI.ALMOST_INFEASIBLE
        return MOI.ALMOST_DUAL_INFEASIBLE
    elseif term == MOI.ALMOST_DUAL_INFEASIBLE
        return MOI.ALMOST_INFEASIBLE
    end
    return term
end

function MOI.get(optimizer::DualOptimizer, ::MOI.ObjectiveValue)
    return MOI.get(optimizer.dual_problem.dual_model, MOI.DualObjectiveValue())
end

function MOI.get(optimizer::DualOptimizer, ::MOI.DualObjectiveValue)
    return MOI.get(optimizer.dual_problem.dual_model, MOI.ObjectiveValue())
end

function MOI.get(optimizer::DualOptimizer, ::MOI.PrimalStatus)
    return MOI.get(optimizer.dual_problem.dual_model, MOI.DualStatus())
end

function MOI.get(optimizer::DualOptimizer, ::MOI.DualStatus)
    return MOI.get(optimizer.dual_problem.dual_model, MOI.PrimalStatus())
end

function MOI.set(
    optimizer::DualOptimizer,
    attr::MOI.AbstractOptimizerAttribute,
    value,
)
    return MOI.set(optimizer.dual_problem.dual_model, attr, value)
end

function MOI.get(
    optimizer::DualOptimizer,
    attr::Union{MOI.AbstractModelAttribute,MOI.AbstractOptimizerAttribute},
)
    return MOI.get(optimizer.dual_problem.dual_model, attr)
end
