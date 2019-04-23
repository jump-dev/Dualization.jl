# Table of duals

This table summarizes the supported dual transformations for constraints

| Primal Function      | Primal Set               | Dual Function        | Dual Set                 |
| -------------------- | ------------------------ | -------------------- | ------------------------ |
| MOI.ScalarAffineFunction | MOI.GreaterThan | MOI.ScalarAffineFunction | MOI.LessThan    |
| MOI.ScalarAffineFunction | MOI.LessThan    | MOI.ScalarAffineFunction | MOI.GreaterThan |