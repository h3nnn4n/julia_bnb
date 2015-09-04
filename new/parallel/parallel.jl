@everywhere using GLPK
@everywhere using DataStructures

@everywhere type Restriction
    boundPos     :: Int
    boundType    :: Int  # -1 is lessThan and +1 is greaterThan, 0 is nothing
end

@everywhere type Instance
    weight       :: Array{Int}
    profit       :: Array{Int}
    size         :: Int
    capacity     :: Int

    x            :: Array{Float64}

    restrictions :: Array{Restriction}

    obj          :: Float64
end

@everywhere ( Base.isless   (x :: Instance, y :: Instance) = (x.obj) < (y.obj) ) 
@everywhere ( Base.isless   (x :: Instance, y            ) = (x.obj) < (y)     ) 
@everywhere ( Base.isless   (x            , y :: Instance) = (x)     < (y.obj) ) 

@everywhere ( Base.copy     (x :: Instance               ) = Instance(copy(x.weight), copy(x.profit), copy(x.size), copy(x.capacity), copy(x.x), copy(x.restrictions), copy(x.obj)) ) 
@everywhere ( Base.copy     (x :: Restriction            ) = Restriction(copy(x.boundPos), copy(x.boundType)) ) 

@everywhere ( Base.print    (x :: Instance               ) = println(x)        )

####################################
# OUTPUT AND DEBUG RELATED OPTIONS #
####################################

@everywhere aculAns = false
@everywhere output  = false

@everywhere debug   = false
@everywhere debug2  = false
@everywhere status  = false

@everywhere branchingFactor = 1000

@everywhere param          = GLPK.SimplexParam()
@everywhere param.msg_lev  = GLPK.MSG_ERR
@everywhere param.presolve = GLPK.ON

################################### 

@everywhere function KnapSack_file(name)
    q = open(name,"r")
    x = readline(q)
    w = eval(parse(x))

    return w
end

@everywhere function isInt(n)
    return int(n) == n
end

@everywhere function isSolved(w :: Instance)
    for i in 1:w.size
        if !isInt(w.x[i])
            return false
        end
    end

    return true
end

@everywhere function newKnapSack(size :: Int, random = true)
    if random
        return Instance(rand(1:size, size),
                        rand(1:size, size), 
                        size, 
                        size,
                        [],
                        [],
                        -1.0
                        )
    else
        return Instance([9,9,1,1,6,7,8,8,7,8], #[3, 5, 1, 2, 3, 6, 7, 2, 8, 1],
                        [6,7,3,6,2,9,6,4,4,6], #[1, 3, 2, 4, 2, 3, 6, 2, 3, 3],
                        10,
                        10,
                        [],
                        [],
                        -1.0
                        )
    end
end

@everywhere function doKnapSack(w :: Instance)

    for i in 1:length(w.x)[1]
        if w.x[i] < 0.0 || w.x[i] > 1.0
            return None
        end
    end

    weight   = w.weight
    profit   = w.profit
    capacity = w.capacity 

    lp       = GLPK.Prob()

    GLPK.set_prob_name(lp, "knapsack")
    GLPK.set_obj_dir(lp, GLPK.MAX)

    GLPK.add_rows(lp, 1)
    GLPK.set_row_name(lp, 1, "p")
    GLPK.set_row_bnds(lp, 1, GLPK.UP, 0.0, w.capacity)

    GLPK.add_cols(lp, w.size)

    #=empty = [ true for i in 1:w.size ]=#

    for i in 1:w.size
        GLPK.set_obj_coef(lp, i, w.profit[i])

        GLPK.set_col_bnds(lp, i, GLPK.DB, 0.0, 1.0)
    end

    for i in 1:size(w.restrictions)[1]
        if     w.restrictions[i].boundType == +1
            if debug2 println("restriction #$i ",
                              w.restrictions[i].boundPos, " UP   ",
                              w.x[w.restrictions[i].boundPos], " ",
                              ceil(w.x[w.restrictions[i].boundPos])) end


            GLPK.set_col_bnds(lp, 
                              w.restrictions[i].boundPos, 
                              GLPK.FX, 
                              ceil(w.x[w.restrictions[i].boundPos]),
                              1.0
                              )

            #=empty[w.restrictions[i].boundPos] = false=#

        elseif w.restrictions[i].boundType == -1
            if debug2 println("restriction #$i ",
                               w.restrictions[i].boundPos, " DOWN ",
                               w.x[w.restrictions[i].boundPos], " ",
                               floor(w.x[w.restrictions[i].boundPos])) end

            GLPK.set_col_bnds(lp, 
                              w.restrictions[i].boundPos,
                              GLPK.FX,
                              0.0,
                              floor(w.x[w.restrictions[i].boundPos]))
            #=empty[w.restrictions[i].boundPos] = false=#

        end
    end

    A = [ w.weight[i] for i in 1:w.size ]

    GLPK.load_matrix(lp, sparse(transpose(A)))

    simplex(lp, param)

    w.obj = GLPK.get_obj_val(lp)

    w.x = [ GLPK.get_col_prim(lp, i) for i in 1:w.size]

    return w
end

@everywhere function branchDown(w :: Instance, pos :: Int, typ :: Int)
    push!(w.restrictions, Restriction(pos, typ))

    q = doKnapSack(w)

    return q
end

@everywhere function branchUp(w :: Instance, pos :: Int, typ :: Int)
    push!(w.restrictions, Restriction(pos, typ))

    q = doKnapSack(w)

    return q
end

@everywhere function branch(new :: Instance, times :: Int, best :: Float64, bestSol :: Instance)
    iterations = 0
    feasible = Instance[]

    heap = binary_maxheap(Instance)

    lp = doKnapSack(new)

    if typeof(lp) != Instance
        return heap, []
    end

    push!(heap, lp)
    heapSize = length(heap)

    #=best = 0.0=#
    #=bestSol = copy(lp)=#

    while length(heap) > 0 && iterations < times
        iterations += 1

        w = pop!(heap)

        if w.obj <= best
            if debug println("Skipping...") end
            continue
        else
            if debug println("\n----------\n", w, "\nHeap size = ", length(heap), "") end

            if isSolved(w)
                if w.obj > best

                    best, bestSol = w.obj, w

                    if aculAns 
                        push!(feasible, w)
                    end
                end

                if debug println("\nFeasible solution found!\n") end
            else
                for i in 1:w.size
                    if !isInt(w.x[i])

                        if debug println("\nBranching at $i") end

                        down = branchDown( copy(w), i, -1 )
                        up   = branchUp  ( copy(w), i, +1 )

                        heapSize += 2

                        if debug println(up.obj, " ", down.obj, " $best") end

                        if up != None && up > best
                            if isSolved(up)
                                if debug println("\nFeasible solution found!\n", up, "\n") end

                                best, bestSol = up.obj, copy(up)

                                if aculAns 
                                    push!(feasible, up)
                                end
                            else
                                push!(heap, up)
                            end
                        end

                        if down != None && down > best
                            if isSolved(down)
                                if debug println("\nFeasible solution found!\n", down, "\n") end

                                best, bestSol = down.obj, copy(down)

                                if aculAns 
                                    push!(feasible, down)
                                end
                            else
                                push!(heap, down)
                            end
                        end

                        break

                    end
                end
            end
        end
    end

    if length(heap) == 0
        #=println("Empty heap, returning best feasible solution found")=#
    else
        #=println("Max number of iterations reached, stoping... #", length(heap), " nodes left")=#
    end

    if aculAns
        return heap, feasible
    else
        if isSolved(bestSol)
            return heap, [bestSol]
        else
            return heap, []
        end
    end
end

function main(size, random, bFactor = 50)
    if output println("Starting...") end

    lp = doKnapSack(newKnapSack(size, random))
    #=lp = doKnapSack(KnapSack_file("instance.dat"))=#

    heap, feasible = branch(lp, 20, 0.0, copy(lp)) ## Populates the tree with something to do
    heapSize = length(heap)

    np = nworkers()

    control = falses(np)

    queue  = cell(np)
    answer = cell(np) 

    bestRel = lp.obj
    best    = 0.0
    bestSol = lp

    for i in 1:np
        answer[i] = RemoteRef()
    end

    ## Spawns the best candidates distribuitivelly, one per worker

    i = 1

    resetidx() = (i=1; i)

    nextidx() = (idx=i; i+=1; idx)

    for wpid in workers()
        idx = nextidx()
        if length(heap) > 0 
            queue[idx] = pop!(heap)
        else
            return false
        end
    end

    resetidx()

    @sync begin
        @async begin
            for wpid in workers()
                idx = nextidx()
                answer[idx] = remotecall(wpid, branch, queue[idx], bFactor, best, copy(bestSol))
            end
        end
    end

    pids    = workers() 

    ok = false

    while !ok
        for i in 1:np
            if isready(answer[i])
                control[i] = true

                h, f  = fetch(answer[i])

                while length(h) > 0
                    q = pop!(h)

                    if q.obj > best
                        if isSolved(q) 
                            best    = copy(q.obj)
                            bestSol = copy(q)

                            if status println("2 Feasible solution found: ", q.obj, "\t ratio: ", q.obj / bestRel) end
                        else
                            push!(heap, q)
                        end
                    end
                end

                while length(f) > 0
                    q = pop!(f)

                    if q > best
                        best    = copy(q.obj)
                        bestSol = copy(q)
                        if status println("  Feasible solution found: ", q.obj, "\t ratio: ", q.obj / bestRel) end
                    end

                    if aculAns 
                        push!(feasible, q)
                    end
                end
                
                while length(heap) > 0
                    w = (pop!(heap))

                    if w.obj > best
                        control[i] = false
                        answer[i] = RemoteRef()
                        answer[i] = remotecall(pids[i], branch, w, branchingFactor, best, copy(bestSol))
                        break
                    end
                end

            end # if isready
        end # For workers

        ok = true
        for i in length(control)
           ok &= control[i] 
        end
    end # While

#####################################################################################

    if output
        println("\n======================================================")

        if aculAns
            for ans in feasible
                println(ans.obj, "")
            end
            println(best)
        else
            println(best)
            println(bestSol.x)
        end
        println(  "======================================================")
    end

    return true
end

function tester()
    main(500, true, 4) ## Pre heating =D

    np = nworkers()

    iters = 5
    size = 666


    println(STDERR, "Comencing number crushing...")

    for size in 500:250:1000
        println(STDERR, "-----------------------------------------")
        out = open("new_data_$(np)_$(size)_.log", "w")

        for bFactor in 25:25:250
            timePassed = 0.0

            for i in 1:iters 
                ret = false
                while !ret
                    tic()
                    ret = main(size, true, bFactor)
                end
                
                timePassed += toq()
            end

            println(     "$size ", timePassed/iters, " $bFactor")
            println(out, "$size ", timePassed/iters, " $bFactor")
        end
        close(out)
    end

    println(STDERR, "-----------------------------------------")
    println(STDERR, "Finished")
end

#=@time main(1000, false, 5)=#

@time tester()
