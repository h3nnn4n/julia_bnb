using GLPK

function main()

    ia = Array(Int64, 4)
    ja = Array(Int64, 4)
    ar = Array(Int64, 4)

    lp = GLPK.Prob()

    GLPK.set_prob_name(lp, "short")
    GLPK.set_obj_dir(lp, GLPK.MAX)

    GLPK.add_rows(lp, 2)

    GLPK.add_cols(lp, 2)
    GLPK.set_col_bnds(lp, 1, GLPK.LO, 0.0, 0.0)
    GLPK.set_col_bnds(lp, 2, GLPK.LO, 0.0, 0.0)
    GLPK.set_col_name(lp, 1, "x1")
    GLPK.set_col_name(lp, 2, "x2")
    GLPK.set_obj_coef(lp, 1, 0.6)
    GLPK.set_obj_coef(lp, 2, 0.5)
    GLPK.set_row_bnds(lp, 1, GLPK.UP, 0.0, 1.0)
    GLPK.set_row_bnds(lp, 2, GLPK.UP, 0.0, 2.0)
    GLPK.set_row_name(lp, 1, "p")
    GLPK.set_row_name(lp, 2, "q")

    A = [ 1.0 2.0;
          3.0 1.0]

    As = sparse(A)  

    #|ia[1] = 1|#
    #|ja[1] = 1|#
    #|ar[1] = 1.0|#
    #|ia[2] = 1|#
    #|ja[2] = 2|#
    #|ar[2] = 2.0|#
    #|ia[3] = 2|#
    #|ja[3] = 1|#
    #|ar[3] = 3.0|#
    #|ia[4] = 2|#
    #|ja[4] = 2|#
    #|ar[4] = 1.0|#

    #|GLPK.load_matrix(lp, 4, ia, ja, ar)|#
    GLPK.load_matrix(lp, As)

    simplex(lp)

    z  = GLPK.get_obj_val(lp)
    x1 = GLPK.get_col_prim(lp, 1)
    x2 = GLPK.get_col_prim(lp, 2)

    println("$z $x1 $x2")

end

