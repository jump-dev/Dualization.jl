struct PrimalDualLink
    dual_var_primal_con::Dict{VI, CI}
    primal_var_dual_con::Dict{VI, CI}
end

const PDLink = PrimalDualLink
