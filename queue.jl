using JuMP
using DataStructures

type instance
    m        :: Model
    weight   :: Array{Int}
    profit   :: Array{Int}
    size     :: Int
    capacity :: Int
end

Base.isless  (x :: instance, y :: instance) = getObjectiveValue(x.m) <  getObjectiveValue(y.m)
Base.isequal (x :: instance, y :: instance) = getObjectiveValue(x.m) == getObjectiveValue(y.m)
Base.copy    (w :: instance)                = instance(copy(w.m), copy(w.weight), copy(w.profit), copy(w.size), copy(w.capacity))

debug = false
#=debug = true=#

function problem_gen()
    w = instance(Model(), [], [], 2, [])

    @defVar(w.m, x[1:2])

    @setObjective(w.m, Max, 3x[1] + 2x[2])

    @addConstraint(w.m,  2x[1] + 4x[2] >= 11)
    @addConstraint(w.m,  3x[1] + 7x[2] <= 54)
    @addConstraint(w.m, 11x[1] -  x[2] >=  1)
    @addConstraint(w.m,  5x[1] + 7x[2] <= 65)

    return w
end

function problem2()
    w = instance(Model(), [], [], 2, [])

    @defVar(w.m, x[1:2], Bin)

    @setObjective(w.m, Max, 3x[1] + 2x[2])

    @addConstraint(w.m,  2x[1] + 4x[2] >= 11)
    @addConstraint(w.m,  3x[1] + 7x[2] <= 54)
    @addConstraint(w.m, 11x[1] -  x[2] >=  1)
    @addConstraint(w.m,  5x[1] + 7x[2] <= 65)

    return w
end

function branch_down(problem :: instance, varIndex :: Int)
    var = getVar(problem.m, :x)[varIndex]
    @addConstraint(problem.m, var <= getVar(var))

    status = solve(problem.m)

    return status, problem
end

function branch_up(problem :: instance, varIndex :: Int)
    var = getVar(problem.m, :x)[varIndex]
    @addConstraint(problem.m, var >= getVar(var))

    status = solve(problem.m)

    return status, problem
end

function updateKnapSack_down(problem :: instance, varIndex :: Int)
    var = getVar(problem.m, :x)[varIndex]
    @addConstraint(problem.m, var <= 0.0)

    status = solve(problem.m)

    return status, problem
end

function updateKnapSack_up(problem :: instance, varIndex :: Int)
    var = getVar(problem.m, :x)[varIndex]
    @addConstraint(problem.m, var >= 1.0)

    status = solve(problem.m)

    return status, problem
end

function optimalKnapSack(p)
    problem = instance(Model(), p.weight, p.profit, p.size, p.capacity)

    @defVar(problem.m, x[1:problem.size], Bin)

    @setObjective(problem.m, Max, dot(problem.profit, x))

    @addConstraint(problem.m, dot(problem.weight, x) <= problem.capacity)

    status = solve(problem.m)

    return problem
end

function randKnapSackRelax(size)
    problem = instance(Model(), rand(1:size,size), rand(1:size,size), size, rand(1:size * 2))
    #=problem = instance(Model(), [3, 2, 1, 3, 7, 1, 2, 3, 9, 9],=#
                                #=[3, 1, 2, 2, 9, 2, 3, 1, 3, 6], size, 15)=#

    @defVar(problem.m, x[1:size])

    @setObjective(problem.m, Max, dot(problem.profit, x))

    @addConstraint(problem.m, dot(problem.weight, x) <= problem.capacity)

    for i in 1:size
        @addConstraint(problem.m, 0.0 <= x[i] <= 1.0)
    end

    status = solve(problem.m)

    return problem
end

function isSolved(w)
    for i in 1:w.size
        if !isInt(getValue(getVar(w.m, :x)[i]))
            return false
        end
    end

    return true
end

function getSol(w)
    println("Objective is: ", getObjectiveValue(w.m))
    println("Solution is:")

    for i = 1:w.size
        print(abs(getValue(getVar(w.m, :x)[i]))," ")
    end

    println()

    for i in w.m.linconstr 
        println(i)
    end
end

function isInt(n)
    return abs(n) == trunc(abs(n))
end

function bnb(w)

end

function main(size)
    #=size = 10=#
    #=problem = randKnapSackRelax(size)=#
    #=optimal = optimalKnapSack(problem)=#

    problem = 

    best = 0.0
    bestSol = problem

    #=println(problem)=#

    h = binary_maxheap(instance)
    push!(h, problem)

    iters = 0

    println("\n---------------------------\n")
    println("Initial relaxation")

    getSol(problem)

    while length(h) > 0
        iters += 1

        #=println("\n", [getValue(getVar(top(h).m, :x)[i]) for i in 1:top(h).size] ,"\n")=#


        #=println("\n  <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=>")=#
        #=println(h)=#
        #=println("\n  <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=>")=#

        w = pop!(h)

        #=println(h)=#

        #=println("\n  <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=> <=> - <=>")=#

        if isSolved(w)
            if getObjectiveValue(w.m) > best
                best = getObjectiveValue(w.m)
                #=bestSol = instance(copy(w.m), w.weight, w.profit, w.size, w.capacity)=#

                println("\n============================")
                println(  "= FEASIBLE SOLUTION FOUND! =\n")
                println(  "Iters = ", iters)
                getSol(w)
                println("\n============================\n")
            end
        elseif getObjectiveValue(w.m) > best
            for i in 1:size

                if debug
                    #=println("testing $i for ", getValue(getVar(w.m, :x)[i]), "   ", isInt(getValue(getVar(w.m, :x)[i])))=#
                end

                if !isInt(getValue(getVar(w.m, :x)[i]))

                    if debug
                        println("---------------------------")
                        println("")
                        println("heap size = ", length(h))


                        for j = 1:w.size
                            print(abs(getValue(getVar(w.m, :x)[j]))," ")
                        end

                        println()

                        println("#$iters ",  " braching at ", i, " x[$i] = ", getValue(getVar(w.m, :x)[i]))
                    end

                    # Branching

                    s1, down = updateKnapSack_down(instance(copy(w.m), w.weight, w.profit, w.size, w.capacity), i)
                    s2, up   = updateKnapSack_up  (instance(copy(w.m), w.weight, w.profit, w.size, w.capacity), i)

                    if debug
                        println(s1, " ", s2)
                    end

                    if s1 == :Optimal
                        if getObjectiveValue(up.m) > best
                            if debug
                                print("stacking up   ", getObjectiveValue(up.m), "    ")

                                for j = 1:w.size
                                    print(abs(getValue(getVar(up.m, :x)[j]))," ")
                                end
                                println()
                            end

                            push!(h, down)

                            if isSolved(up)
                                best = getObjectiveValue(up.m)

                                println("\n============================")
                                println(  "= FEASIBLE SOLUTION FOUND! =\n")
                                println(  "Iters = ", iters)
                                getSol(up)
                                println("\n============================\n")
                            end
                        end
                    end

                    if s2 == :Optimal
                        if getObjectiveValue(down.m) > best
                            if debug
                                print("stacking down ", getObjectiveValue(down.m), "    ")

                                for j = 1:w.size
                                    print(abs(getValue(getVar(down.m, :x)[j]))," ")
                                end
                                println()
                            end

                            push!(h, down)

                            if isSolved(down)
                                best = getObjectiveValue(down.m)

                                println("\n============================")
                                println(  "= FEASIBLE SOLUTION FOUND! =\n")
                                println(  "Iters = ", iters)
                                getSol(down)
                                println("\n============================\n")
                            end
                        end
                    end

                    #=break=#
                end
            end
        end
    end

    println("\n---------------------------\n")

    println("Iters = ", iters)
    println()
    println("Optimal solution")
    getSol(optimal)
end
