using JuMP

function randKnapSack(size)
    m = Model()

    @defVar(m, x[1:size], Bin)

    profit = rand(1:size,size)
    weight = rand(1:size,size)
    capacity = rand(1:size*5)

    # Objective: maximize profit
    @setObjective(m, Max, dot(profit, x))

    # Constraint: can carry all
    @addConstraint(m, dot(weight, x) <= capacity)

    # Solve problem using MIP solver
    status = solve(m)

    #=println("Objective is: ", getObjectiveValue(m))=#
    #=println("Solution is:")=#
    #=for i = 1:5=#
        #=print("x[$i] = ", getValue(x[i]))=#
        #=println(", p[$i]/w[$i] = ", profit[i]/weight[i])=#
    #=end=#

    return m
end

function timed(i)
    tic()
    randKnapSack(i)
    time = toq()

    return time
end

function para(start, step, stop, num)
    randKnapSack(100)

    @everywhere require("knapsack.jl")
    @everywhere using JuMP

    xaxis = Int64[]
    yaxis = Float64[]

    time = 0.0

    x = [ @spawn timed(100) for j in 1:4 ]
    @sync time += (fetch(x[1]) + fetch(x[2]) + fetch(x[3]) + fetch(x[4]))

    println("Starting")

    for i in start:step:stop

        time = 0.0

        x = [ @spawn timed(i) for j in 1:num ]
        @sync for j in 1:num
            time += fetch(x[j])
        end

        time /= num

        @printf "%f %d\n" time i

        push!(xaxis, i)
        push!(yaxis, time)
    end

    println("Finished")

    return yaxis
end

function test(xaxis, yaxis)
    using Gadfly

    p = plot(x = xaxis, y = yaxis, Geom.point, Geom.smooth, Theme(panel_fill=color("white")))
    draw(PNG("dataplot.png", 36cm, 24cm), p)
end

