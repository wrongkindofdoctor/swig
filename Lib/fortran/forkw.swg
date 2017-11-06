//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/fortrankw.swg
 * \author Seth R Johnson
 * \date   Sun Dec 04 14:12:01 2016
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

// By default SWIG gives these underscore prefix/suffix
%rename(deref) *::operator->;
%rename(ref)   *::operator*();
%rename(ref)   *::operator*() const;
// Prevent identifiers from having a leading underscore
// %rename("%(regex:/^_(.*)/\\1_/)s") "";

%keywordwarn("'create' is reserved for SWIG constructors",
             rename="create_") "*::create";
%keywordwarn("'release' is reserved for SWIG destructors",
             rename="release_") "*::release";

#define FORTRANKW(x) %keywordwarn("'" `x` "' is a Fortran keyword")  `x`

// FORTRAN 77
FORTRANKW(assign);
FORTRANKW(backspace);
FORTRANKW(block data);
FORTRANKW(call);
FORTRANKW(close);
FORTRANKW(common);
FORTRANKW(continue);
FORTRANKW(data);
FORTRANKW(dimension);
FORTRANKW(do);
FORTRANKW(else);
FORTRANKW(else if);
FORTRANKW(end);
FORTRANKW(endfile);
FORTRANKW(endif);
FORTRANKW(entry);
FORTRANKW(equivalence);
FORTRANKW(external);
FORTRANKW(format);
FORTRANKW(function);
FORTRANKW(goto);
FORTRANKW(if);
FORTRANKW(implicit);
FORTRANKW(inquire);
FORTRANKW(intrinsic);
FORTRANKW(open);
FORTRANKW(parameter);
FORTRANKW(pause);
FORTRANKW(print);
FORTRANKW(program);
FORTRANKW(read);
FORTRANKW(return);
FORTRANKW(rewind);
FORTRANKW(rewrite);
FORTRANKW(save);
FORTRANKW(stop);
FORTRANKW(subroutine);
FORTRANKW(then);
FORTRANKW(write);

// Fortran 90
// FORTRANKW(allocatable);
// FORTRANKW(allocate);
// FORTRANKW(case);
// FORTRANKW(contains);
// FORTRANKW(cycle);
// FORTRANKW(deallocate);
// FORTRANKW(elsewhere);
// FORTRANKW(exit);
// FORTRANKW(include);
// FORTRANKW(interface);
// FORTRANKW(intent);
// FORTRANKW(module);
// FORTRANKW(namelist);
// FORTRANKW(nullify);
// FORTRANKW(only);
// FORTRANKW(operator);
// FORTRANKW(optional);
// FORTRANKW(pointer);
// FORTRANKW(private);
// FORTRANKW(procedure);
// FORTRANKW(public);
// FORTRANKW(recursive);
// FORTRANKW(result);
// FORTRANKW(select);
// FORTRANKW(sequence);
// FORTRANKW(target);
// FORTRANKW(use);
// FORTRANKW(while);
// FORTRANKW(where);

// Fortran 95
// FORTRANKW(elemental);
// FORTRANKW(forall);
// FORTRANKW(pure);

// Fortran 2003
// FORTRANKW(abstract);
// FORTRANKW(associate);
// FORTRANKW(asynchronous);
// FORTRANKW(bind);
// FORTRANKW(class);
// FORTRANKW(deferred);
// FORTRANKW(enum);
// FORTRANKW(enumerator);
// FORTRANKW(extends);
// FORTRANKW(final);
// FORTRANKW(flush);
// FORTRANKW(generic);
// FORTRANKW(import);
// FORTRANKW(non_overridable);
// FORTRANKW(nopass);
// FORTRANKW(pass);
// FORTRANKW(protected);
// FORTRANKW(value);
// FORTRANKW(volatile);
// FORTRANKW(wait);

#undef FORTRANKW

//---------------------------------------------------------------------------//
// end of fortran/fortrankw.swg
//---------------------------------------------------------------------------//
