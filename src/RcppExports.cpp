// Generated by using Rcpp::compileAttributes() -> do not edit by hand
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include "../inst/include/ATACtion.h"
#include <RcppArmadillo.h>
#include <Rcpp.h>

using namespace Rcpp;

// reduceChromatinAccessibility
List reduceChromatinAccessibility(sp_mat expression, int reduced_dim, int method, int iters);
RcppExport SEXP _ATACtion_reduceChromatinAccessibility(SEXP expressionSEXP, SEXP reduced_dimSEXP, SEXP methodSEXP, SEXP itersSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< sp_mat >::type expression(expressionSEXP);
    Rcpp::traits::input_parameter< int >::type reduced_dim(reduced_dimSEXP);
    Rcpp::traits::input_parameter< int >::type method(methodSEXP);
    Rcpp::traits::input_parameter< int >::type iters(itersSEXP);
    rcpp_result_gen = Rcpp::wrap(reduceChromatinAccessibility(expression, reduced_dim, method, iters));
    return rcpp_result_gen;
END_RCPP
}
// tabulate2dCpp
Rcpp::IntegerMatrix tabulate2dCpp(Rcpp::IntegerVector x1, int xmin, int xmax, Rcpp::IntegerVector y1, int ymin, int ymax);
RcppExport SEXP _ATACtion_tabulate2dCpp(SEXP x1SEXP, SEXP xminSEXP, SEXP xmaxSEXP, SEXP y1SEXP, SEXP yminSEXP, SEXP ymaxSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< Rcpp::IntegerVector >::type x1(x1SEXP);
    Rcpp::traits::input_parameter< int >::type xmin(xminSEXP);
    Rcpp::traits::input_parameter< int >::type xmax(xmaxSEXP);
    Rcpp::traits::input_parameter< Rcpp::IntegerVector >::type y1(y1SEXP);
    Rcpp::traits::input_parameter< int >::type ymin(yminSEXP);
    Rcpp::traits::input_parameter< int >::type ymax(ymaxSEXP);
    rcpp_result_gen = Rcpp::wrap(tabulate2dCpp(x1, xmin, xmax, y1, ymin, ymax));
    return rcpp_result_gen;
END_RCPP
}

static const R_CallMethodDef CallEntries[] = {
    {"_ATACtion_reduceChromatinAccessibility", (DL_FUNC) &_ATACtion_reduceChromatinAccessibility, 4},
    {"_ATACtion_tabulate2dCpp", (DL_FUNC) &_ATACtion_tabulate2dCpp, 6},
    {NULL, NULL, 0}
};

RcppExport void R_init_ATACtion(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
