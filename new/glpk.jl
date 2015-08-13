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

Base.copy          (x :: Instance)           = Instance(copy(weight), copy(profit), copy(size), copy(capacity), copy(x), copy(restrictions), copy(obj))
Base.copy          (x :: Restriction)        = Restriction(copy(boundPos), copy(boundType))

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

@everywhere function newKnapSack(size :: Int)
    return Instance(rand(1:size, size), rand(1:size, size), size, size, [], [],  -1.0)
end

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

    for i in 1:w.size
        GLPK.set_obj_coef(lp, i, w.profit[i])

        GLPK.set_col_bnds(lp, i, GLPK.DB, 0.0, 1.0)
    end

    A = [ w.weight[i] for i in 1:w.size ]

    GLPK.load_matrix(lp, sparse(transpose(A)))

    for i in 1:size(w.restrictions)[1]
        if w.restrictions.boundType == 1
            GLPK.set_col_bnds(lp, w.restrictions.boundPos, GLPK.UP, ceil(w.x[i]))
        elseif w.restrictions.boundType == -1
            GLPK.set_col_bnds(lp, w.restrictions.boundPos, GLPK.LO, floor(w.x[i]))
        end
    end

    simplex(lp)

    w.obj = GLPK.get_obj_val(lp)

    w.x = [ GLPK.get_col_prim(lp, i) for i in 1:w.size]

    return w
end

@everywhere function branchDown(w :: Instance, pos :: Int, typ :: Int)
    push!(w.restrictions, Restriction(pos, typ))

    q = doKnapSack(w)

    return q
end

@everywhere function branchUp(w :: Instance)

end

function main()
    
    lp = doKnapSack(newKnapSack(10)) 

    heap = binary_maxheap(Instance)

    push!(heap, lp)

    best = 0.0
    bestSol = (lp)

    while length(heap) > 0
        w = pop!(heap)
        println(w)

        if isSolved(w)
           if w.obj > best
               best    = w.obj
               bestSol = w
           end
        else
            for i in 1:w.size
                if !isInt(w.x[i])
                    println("here")
                    down = branchDown( (w), i, -1 )
                    up   = branchUp  ( (w), i, +1 )

                    if up > best
                        best    = up.obj
                        bestSol = up
                    end

                    if down > best
                        best    = down.obj
                        bestSol = down
                    end
                    break
                end
            end
        end
    end
end

