import Base.isless

using JuMP
using DataStructures

type instance
    m :: Model
    weight :: Array{Int}
    profit :: Array{Int}
    size :: Int
    capacity :: Int
    #=x :: Array{Float64}=#
    x
end

isless (x :: instance, y :: instance) = getObjectiveValue(x.m) < getObjectiveValue(y.m)

function updateKnapSack_down(problem :: instance, varIndex :: Int)
    #=@addConstraint(problem.m, problem.x[varIndex] <= floor((problem.x[varIndex])))=#

    @addConstraint(problem.m, problem.x[varIndex] <= 0.0)

    status = solve(problem.m)

    println(problem.m)

    return status, problem
end

function updateKnapSack_up(problem :: instance, varIndex :: Int)
    #=@addConstraint(problem.m, problem.x[varIndex] >=  ceil((problem.x[varIndex])))=#
    @addConstraint(problem.m, problem.x[varIndex] >=  1.0)

    status = solve(problem.m)

    println(problem.m)

    return status, problem
end

function randKnapSack(size)
    problem = instance(Model(), rand(1:size,size), rand(1:size,size), size, rand(1:size * 2), [])

    @defVar(problem.m, problem.x[1:size])

    @setObjective(problem.m, Max, dot(problem.profit, problem.x))

    @addConstraint(problem.m, dot(problem.weight, problem.x) <= problem.capacity)

    for i in 1:size
        @addConstraint(problem.m, 0.0 <= problem.x[i] <= 1.0)
    end

    status = solve(problem.m)

    return problem
end

function timed(i)
    tic()
    randKnapSack(i)
    time = toq()

    return time
end

function getSol(w)
    m = w[1]

    println("Objective is: ", getObjectiveValue(m))
    println("Solution is:")
    for i = 2:size(w)[1]
        println("x[", i - 1, "] = ", w[i])

        #=println("x[$i] = ", getValue(x[i]))=#
        #=println(", p[$i]/w[$i] = ", profit[i]/weight[i])=#
    end
end

function isInt(n)
    return n == trunc(n)
end

function bnb(w)

end

function main()
    size = 10
    problem = randKnapSack(size)

    println(problem)

    h = binary_minheap(instance)
    push!(h, problem)

    solved = false

    c = 0

    while solved == false
        solved = true

        if length(h) == 0
            println("\n\n")

            println("Solution:")
            println(top(h).m)
            println(top(h).x)

            break
        end
        println("\n", [getValue(top(h).x[i]) for i in 1:top(h).size] ,"\n")

        w = pop!(h)

        for i in 1:size
            if isInt(getValue(w.x[i])) == false
                println("")
                println("heap size = ", length(h))
                println("#$c braching at ", i, " x[$i] = ", getValue(w.x[i]))
                s1, down = updateKnapSack_down(instance(copy(w.m), w.weight, w.profit, w.size, w.capacity, (w.x)), i)
                #=s2, up   = updateKnapSack_up  (deepcopy(w), i)=#

                if s1 == :Optimal
                    push!(h, down)
                end

                #=if s2 == :Optimal=#
                    #=push!(h, up)=#
                #=end=#

                #=println(" ==> ", getObjectiveValue(down.m), " && ", getObjectiveValue(up.m))=#

                if length(h) == 0
                    break
                end

                println(" ==> top = ", getObjectiveValue(top(h).m))

                solved = false
                break
            end
        end

        if c == 10
            break
        else
            c += 1
        end

    end


end
