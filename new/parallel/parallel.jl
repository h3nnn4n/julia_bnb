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

@everywhere branchingFactor = 1000

@everywhere param          = GLPK.SimplexParam()
@everywhere param.msg_lev  = GLPK.MSG_ERR
@everywhere param.presolve = GLPK.ON

################################### 

@everywhere function isInt(n)
    return abs(n) == trunc(abs(n))
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

@everywhere function branch(new :: Instance, times :: Int)
    #=println("typeof: ", typeof(new))=#

    iterations = 0
    feasible = Instance[]

    heap = binary_maxheap(Instance)

    lp = doKnapSack(new)

    if typeof(lp) != Instance
        return heap, []
    end

    push!(heap, lp)
    heapSize = length(heap)

    best = 0.0
    bestSol = copy(lp)

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
        return heap, [bestSol]
    end
end

function main(size, random, bFactor = 500)
    if output println("Starting...") end

    lp = doKnapSack(newKnapSack(size, random)) 

    heap, feasible = branch(lp, 20) ## Populates the tree with something to do
    heapSize = length(heap)

    np = nworkers()

    queue  = cell(np)
    answer = cell(np) 

    bestRel = lp.obj
    best    = 0.0
    bestSol = lp

    for i in 1:np
        answer[i] = RemoteRef()
    end

    ## Spawns the best candidates distribuitivelly, one per worker

    #=println(queue)=#

    i = 1

    resetidx() = (i=1; i)

    nextidx() = (idx=i; i+=1; idx)

    for wpid in workers()
        idx = nextidx()
        #=println(idx)=#
        queue[idx] = pop!(heap)
    end

    resetidx()

    @sync begin
        for wpid in workers()
            idx = nextidx()
            answer[idx] = remotecall(wpid, branch, queue[idx], bFactor)
            #=answer[idx] = remotecall(wpid, branch, queue[idx], branchingFactor)=#
        end
    end

    @sync begin
        pids    = workers() 

        while length(heap) > 0
            for i in 1:np
                #=println(length(heap), " ",  i)=#
                if isready(answer[i])
                    h, f  = fetch(answer[i])

                    while length(h) > 0
                        q = pop!(h)

                        if q.obj > best
                            if isSolved(q) 
                                best    = copy(q.obj)
                                bestSol = copy(q)
                                if debug println("Feasible solution found: ", q.obj, "\t ratio: ", q.obj / bestRel) end
                            end

                            push!(heap, q)
                        end
                    end

                    while length(f) > 0
                        q = pop!(f)

                        if q > best
                            best    = copy(q.obj)
                            bestSol = copy(q)
                            if debug println("Feasible solution found: ", q.obj, "\t ratio: ", q.obj / bestRel) end
                        end

                        if aculAns 
                            push!(feasible, q)
                        end
                    end

                    
                    @sync begin
                        while length(heap) > 0
                            w = (pop!(heap))

                            if w.obj > best
                                answer[i] = RemoteRef()
                                answer[i] = remotecall(pids[i], branch, w, branchingFactor)

                                break
                            end
                        end

                        #=if length(heap) > 0=#

                        #=else=#
                            #=continue=#
                        #=end=#
                    end
                end
            end
        end
    end # Begin

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

    return heapSize
end

function tester()
    main(100, true, 100) ## Pre heating =D

    np = nworkers()

    println(STDERR, "Starting...")
    for size in 500:250:1000
        out = open("new_data$(np)_$(size)_.log", "w")
        println(STDERR, "-----------------------------------------")

        for bFactor in 10:10:250
            iters = 10
            timePassed = 0.0

            for i in 1:iters 
                tic()
                x = main(size, true, bFactor)
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

tester()
