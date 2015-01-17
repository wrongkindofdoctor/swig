#include "swigmod.h"

class FORTRAN : public Language
{
  public:
    virtual void main(int argc, char *argv[]);
    virtual int top(Node *n);
};

//---------------------------------------------------------------------------//
/*!
 * \brief Main function for code generation.
 */
void FORTRAN::main(int argc, char *argv[])
{
    /* Set language-specific subdirectory in SWIG library */
    SWIG_library_directory("fortran");

    /* Set language-specific preprocessing symbol */
    Preprocessor_define("SWIGFORTRAN 1", 0);

    /* Set language-specific configuration file */
    SWIG_config_file("fortran.swg");

    /* Set typemap language (historical) */
    SWIG_typemap_lang("fortran");
}

//---------------------------------------------------------------------------//
/*!
 * \brief Top-level code generation function.
 */
int FORTRAN::top(Node *n)
{
    printf("Generating code.\n");

    return SWIG_OK;
}

//---------------------------------------------------------------------------//
// Expose the code to the SWIG main function.
//---------------------------------------------------------------------------//
extern "C" Language *
swig_fortran(void) {
  return new FORTRAN();
}
