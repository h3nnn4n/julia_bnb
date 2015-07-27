using JuMP

## Simple LP model
m = Model()

@defVar(m, 0 <= x <= 2 )
@defVar(m, 0 <= y <= 30 )

@setObjective(m, Max, 5x + 3*y )
@addConstraint(m, 1x + 5y <= 3.0 )

## The model is copied
n = copy(m)

## New constraint using the same variables is added to the copy
@addConstraint(n, getVar(n, :x) + getVar(n, :y) <= 3.0 )

solve(m)

## Error Here
solve(n)

print(n)

#  h3nnn4n@clusterfuck ~/julia_bnb (git)-[master] % julia bug.jl
#  ERROR: Variable not owned by model present in constraints
#   in prepConstrMatrix at /home/h3nnn4n/.julia/v0.3/JuMP/src/solvers.jl:163
#   in solveLP at /home/h3nnn4n/.julia/v0.3/JuMP/src/solvers.jl:221
#   in solve at /home/h3nnn4n/.julia/v0.3/JuMP/src/solvers.jl:39
#   in include at ./boot.jl:245
#   in include_from_node1 at loading.jl:128
#   in process_options at ./client.jl:285
#   in _start at ./client.jl:354
#  while loading /home/h3nnn4n/julia_bnb/bug.jl, in expression starting on line 21
