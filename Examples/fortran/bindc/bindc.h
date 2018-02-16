//---------------------------------*-C++-*-----------------------------------//
/*!
 * \file   bindc/bindc.h
 * \author Seth R Johnson
 * \date   Thu Feb 08 07:16:02 2018
 * \brief  bindc class declaration.
 * \note   Copyright (c) 2018 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

#ifndef bindc_bindc_hh
#define bindc_bindc_hh

// C-bound struct
struct Point {
  float x, y, z;
};

// Wrapped functions
void wrapped_print_point(const Point *p);
inline bool wrapped_negation(bool v) {
  return !v;
}

// String access
const char* get_existing_string(int i);
char* concat(const char* a, const char* b);

extern "C" {
//---------------------------------------------------------------------------//

// These functions are simply bound, not wrapped.
void make_point(Point *pt, const double xyz[3]);
void print_sphere(const Point *origin, const double *radius);
bool bound_negation(bool v);

//---------------------------------------------------------------------------//
}                                 // end extern

//---------------------------------------------------------------------------//
#endif                                 // bindc_bindc_hh

//---------------------------------------------------------------------------//
// end of bindc/bindc.h
//---------------------------------------------------------------------------//
