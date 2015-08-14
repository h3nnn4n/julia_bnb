using GLPK
using DataStructures

type Restriction
    boundPos     :: Int
    boundType    :: Int  # -1 is lessThan and +1 is greaterThan, 0 is nothing
end

type Instance
    weight       :: Array{Int}
    profit       :: Array{Int}
    size         :: Int
    capacity     :: Int

    x            :: Array{Float64}

    restrictions :: Array{Restriction}

    obj          :: Float64
end

Base.isless   (x :: Instance, y :: Instance) = (x.obj) < (y.obj)
Base.isless   (x :: Instance, y)             = (x.obj) < (y)
Base.isless   (x            , y :: Instance) = (x)     < (y.obj)

Base.copy          (x :: Instance)           = Instance(copy(x.weight), copy(x.profit), copy(x.size), copy(x.capacity), copy(x.x), copy(x.restrictions), copy(x.obj))
Base.copy          (x :: Restriction)        = Restriction(copy(x.boundPos), copy(x.boundType))

debug  = false
debug2 = false

debug  = true
#=debug2 = true=#

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
        return Instance([3, 5, 1, 2, 3, 6, 7, 2, 8, 1],
                        [1, 3, 2, 4, 2, 3, 6, 2, 3, 3],
                        10,
                        10,
                        [],
                        [],
                        -1.0
                        )
    end
end

param = GLPK.SimplexParam()
param.msg_lev = GLPK.MSG_ERR
param.presolve = GLPK.ON

@everywhere function doKnapSack(w :: Instance)
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

        #=if empty[i]=#
        GLPK.set_col_bnds(lp, i, GLPK.DB, 0.0, 1.0)
        #=end=#
    end

    for i in 1:size(w.restrictions)[1]
        if     w.restrictions[i].boundType == +1
            if debug2 println("restriction #$i ",
                              w.restrictions[i].boundPos, " UP   ",
                              w.x[w.restrictions[i].boundPos], " ",
                              ceil(w.x[w.restrictions[i].boundPos])) end


            GLPK.set_col_bnds(lp, w.restrictions[i].boundPos, GLPK.LO, ceil(w.x[w.restrictions[i].boundPos]), 0.0)
            #=empty[w.restrictions[i].boundPos] = false=#

        elseif w.restrictions[i].boundType == -1
            if debug2 println("restriction #$i ",
                               w.restrictions[i].boundPos, " DOWN ",
                               w.x[w.restrictions[i].boundPos], " ",
                               floor(w.x[w.restrictions[i].boundPos])) end

            GLPK.set_col_bnds(lp, w.restrictions[i].boundPos, GLPK.UP, 0.0, floor(w.x[w.restrictions[i].boundPos]))
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

function main()

    lp = doKnapSack(newKnapSack(10, false)) 

    heap = binary_maxheap(Instance)

    push!(heap, lp)

    best = 0.0
    bestSol = (lp)

    stopper = 100

    while length(heap) > 0
        stopper -= 1
        if stopper == 0 break end

        w = pop!(heap)

        if w.obj <= best
            if debug println("Skipping...") end
            continue
        else
            if debug println("\n----------\n", w, "\nHeap size = ", length(heap), "") end

            if isSolved(w)
                if w.obj > best
                    best    = w.obj
                    bestSol = w
                end

                if debug println("\nFeasible solution found!\n") end
            else
                for i in 1:w.size
                    if !isInt(w.x[i])

                        if debug println("\nBranching at $i") end

                        down = branchDown( copy(w), i, -1 )
                        up   = branchUp  ( copy(w), i, +1 )

                        if debug println(up.obj, " ", down.obj, " $best") end

                        if up > best
                            if isSolved(up)
                                if debug println("\nFeasible solution found!\n", up, "\n") end

                                best    = up.obj
                                bestSol = up
                            end

                            push!(heap, up)
                        end

                        if down > best
                            if isSolved(down)
                                if debug println("\nFeasible solution found!\n", down, "\n") end

                                best    = down.obj
                                bestSol = down
                            end

                            push!(heap, down)
                        end
                        break

                    end
                end
            end
        end
    end
end

