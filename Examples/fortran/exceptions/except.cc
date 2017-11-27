//---------------------------------*-C++-*-----------------------------------//
/*!
 * \file   exceptions/except.cc
 * \author Seth R Johnson
 * \date   Thu Mar 02 10:54:30 2017
 * \brief  except class definitions.
 * \note   Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

#include "except.hh"

#include <stdexcept>
#include <utility>

namespace
{
int g_stored = 0;
};

void alpha(int val)
{
    if (val < 0)
        throw std::logic_error("Value must be nonnegative");
    g_stored = val;
}

int bravo()
{
    if (g_stored == 0)
        throw std::logic_error("Value has not been assigned");

    return g_stored;
}

std::pair<int*, std::size_t> get_view()
{
    return std::make_pair(&g_stored, 1);
}

//---------------------------------------------------------------------------//
// end of exceptions/except.cc
//---------------------------------------------------------------------------//
