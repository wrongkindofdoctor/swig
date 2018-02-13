//---------------------------------*-C++-*-----------------------------------//
/*!
 * \file   bindc/bindc.cxx
 * \author Seth R Johnson
 * \date   Thu Feb 08 07:16:02 2018
 * \brief  bindc class definitions.
 * \note   Copyright (c) 2018 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

#include "bindc.h"

#include <iostream>
using std::cout;
using std::endl;

//---------------------------------------------------------------------------//
/*!
 * \brief Print a point.
 */
void wrapped_print_point(const Point* p)
{
    cout << "{" << p->x << ',' << p->y << ',' << p->z << "}" << endl;
}

//---------------------------------------------------------------------------//

extern "C" {
void make_point(Point* pt, const double xyz[3])
{
    pt->x = xyz[0];
    pt->y = xyz[1];
    pt->z = xyz[2];
}

void print_sphere(const Point* origin, const double* radius)
{
    cout << "Sphere: r=" << *radius << ", "
        "origin={" << origin->x << ',' << origin->y << ',' << origin->z << "}"
        << endl;
}
bool bound_negation(bool v)
{
    return !v;
}
}

//---------------------------------------------------------------------------//
// end of bindc/bindc.cxx
//---------------------------------------------------------------------------//
