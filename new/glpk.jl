using GLPK

type instance
    weight   :: Array{Int}
    profit   :: Array{Int}
    size     :: Int
    capacity :: Int

    x        :: Array{Float64}

    obj      :: Float64
end

@everywhere function isInt(n)
    return abs(n) == trunc(abs(n))
end

@everywhere function newKnapSack(size)
    return instance(rand(1:size, size), rand(1:size, size), size, size, [],  -1.0)
end

@everywhere function doKnapSack(instance)
    weight   = instance.weight
    profit   = instance.profit
    capacity = instance.capacity 

    lp = GLPK.Prob()

    GLPK.set_prob_name(lp, "knapsack")
    GLPK.set_obj_dir(lp, GLPK.MAX)

    GLPK.add_rows(lp, 1)
    GLPK.set_row_name(lp, 1, "p")
    GLPK.set_row_bnds(lp, 1, GLPK.UP, 0.0, instance.capacity)

    GLPK.add_cols(lp, instance.size)

    for i in 1:instance.size
        GLPK.set_obj_coef(lp, i, instance.profit[i])
        
        GLPK.set_col_bnds(lp, i, GLPK.DB, 0.0, 1.0)
    end

    A = [ instance.weight[i] for i in 1:instance.size ]

    GLPK.load_matrix(lp, sparse(transpose(A)))

    simplex(lp)

    instance.obj = GLPK.get_obj_val(lp)

    #=println("\n\n")=#
    #=println("Capacity: $capacity")=#
    #=println("Profit:   $profit")=#
    #=println("Weight:   $weight")=#
    #=println("Obj F:    ", GLPK.get_obj_val(lp))=#

    #=print  ("x[i]:     ")=#

    #=for i in 1:size=#
        #=print(GLPK.get_col_prim(lp, i), " ")=#
    #=end=#

    instance.x = [ GLPK.get_col_prim(lp, i) for i in 1:instance.size]

    return instance
end

function main()

    knapSack = newKnapSack(10000)

    lp = doKnapSack(knapSack) 

    simplex(lp)

end

