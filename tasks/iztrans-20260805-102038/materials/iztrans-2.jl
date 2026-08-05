@register_symbolic iZtrans(F, var, transvar) false

function iztrans(expr::Union{Number,AbstractArray{<:Number}})
    var, transvar = _iztrans_get_independent_variable(expr)
    return iztrans_core.(expr, var, transvar)
end

function iztrans(
    expr::Union{Number,AbstractArray{<:Number}}, transvar::Union{Num,AbstractArray{<:Num}}
)
    var, = _iztrans_get_independent_variable(expr)
    return iztrans_core.(expr, var, transvar)
end

function iztrans(
    expr::Union{Number,AbstractArray{<:Number}},
    var::Union{Number,AbstractArray{<:Num}},
    transvar::Union{Num,AbstractArray{<:Num}},
)
    return iztrans_core.(expr, var, transvar)
end

function iztrans_core(expr, var, transvar)
    if expr isa Num && iscall(value(expr)) && operation(value(expr)) === Ztrans
        original_expr, original_var, transform_var = Num.(arguments(value(expr)))
        if isequal(var, transform_var)
            return substitute(original_expr, original_var => transvar)
        end
    end
    expr1 = tysym_to_sympy(expr)
    var1 = tysym_to_sympy(var)
    transvar1 = SymPy.sympy.Symbol(string(transvar); integer=true)
    iztrans_term = 0
    for term in _iztrans_apart(expr1, var1)
        term1 = SymPy.sympy.simplify(term * var1^(transvar1 - 1))
        numer, denom = term1.as_numer_denom()
        poles = SymPy.sympy.roots(denom, var1)
        if length(poles) > 0
            for (p, multiplicity) in poles
                multiplicity_int = Int(multiplicity)
                derivative_order = multiplicity_int - 1
                s = multiplicity_int
                res = (var1 - p)^s * term1
                for i in 1:derivative_order
                    res = SymPy.sympy.Derivative(res, var1)
                end
                factorial_div = SymPy.sympy.Rational(1, SymPy.sympy.factorial(s - 1))
                res = SymPy.sympy.Mul(factorial_div * res)
                res = res.doit()
                res = res.limit(var1, p)
                iztrans_term += sympy_to_tysym(SymPy.sympy.simplify(res))
            end
        else
            coeff, degree = term1.as_coeff_exponent(var1)
            coeff_ty = sympy_to_tysym(coeff)
            degree_ty = sympy_to_tysym(degree)
            if !iszero(degree) && degree != transvar1
                iztrans_term += coeff_ty * kroneckerDelta(degree_ty + 1, 0)
            elseif coeff == SymPy.sympy.I || coeff.is_Number
                iztrans_term +=
                    coeff_ty * iZtrans(sympy_to_tysym(term / coeff), var, transvar)
            else
                iztrans_term += iZtrans(sympy_to_tysym(term), var, transvar)
            end
        end
    end
    return iztrans_term
end

function _iztrans_apart(expr, var)
    expr = SymPy.sympy.nsimplify(expr)
    try
        return expr1 = expr.apart(var).as_ordered_terms()
    catch
        try
            return expr1 = expr.apart().as_ordered_terms()
        catch
            return expr1 = expr.as_ordered_terms()
        end
    end
end

function _iztrans_get_independent_variable(F)
    vars = _get_var(F)
    vars_symbol = Symbol.(vars)
    var_independent = symvar(F, 1)
    if :z in vars_symbol || isempty(vars)
        res_var = Symbolics.variable(:z)
        res_transvar = Symbolics.variable(:n)
    else
        res_var = var_independent
        res_transvar = if Symbol(var_independent) == :n
            Symbolics.variable(:x)
        else
            Symbolics.variable(:n)
        end
    end
    return res_var, res_transvar
end
