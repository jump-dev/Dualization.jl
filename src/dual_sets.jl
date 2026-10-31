# Copyright (c) 2017: Guilherme Bodin, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

# We define `_dual_set` instead as adding methods for `MOI.dual_set` on MOI sets
# is type piracy.
_dual_set(set::MOI.AbstractSet) = MOI.dual_set(set)

function _dual_set_type(::Type{S}) where {S}
    return try
        # The fallback formats S before throwing. Avoid this expensive error
        # construction for unsupported sets queried during bridge selection.
        if which(MOI.dual_set_type, Tuple{Type{S}}) ===
           which(MOI.dual_set_type, Tuple{Type{MOI.AbstractSet}})
            return nothing
        end
        MOI.dual_set_type(S)
    catch
        return nothing # Explicit `dual_set_type` methods may also throw.
    end
end

_dual_set(::MOI.GreaterThan{T}) where {T} = MOI.GreaterThan(zero(T))
_dual_set_type(::Type{MOI.GreaterThan{T}}) where {T} = MOI.GreaterThan{T}

_dual_set(::MOI.LessThan{T}) where {T} = MOI.LessThan(zero(T))
_dual_set_type(::Type{MOI.LessThan{T}}) where {T} = MOI.GreaterThan{T}

# Maybe return Reals in the future
_dual_set(::MOI.EqualTo) = nothing
_dual_set_type(::Type{<:MOI.EqualTo}) = MOI.Reals
