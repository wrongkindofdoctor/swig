#include "swigmod.h"
#include "cparse.h"

class FORTRAN : public Language
{
  private:
    // >>> ATTRIBUTES

    String *d_module; //!< Module name
    String *d_outpath; //!< WRAP.cxx output

    // >>> OUTPUT FILES

    // Injected into .cxx file
    String *f_begin; //!< Very beginning of output file
    String *f_runtime; //!< SWIG runtime code
    String *f_header; //!< Declarations and inclusions from .i
    String *f_wrapper; //!< C++ Wrapper code
    String *f_init; //!< C++ initalization functions

    // Injected into module file
    String *f_imports;     //!< Fortran "use" directives generated from %import
    String *f_public;      //!< List of public interface functions and mapping
    String *f_types;       //!< Generated class types
    String *f_interfaces;  //!< Fortran interface declarations to SWIG functions
    String *f_proxy;    //!< Fortran subroutine wrapper functions

    // Current class parameters
    String *f_cur_methods; //!< Method strings inside the current class
    bool d_in_constructor; //!< Whether we're being called inside a constructor
    bool d_in_destructor; //!< Whether we're being called inside a constructor

  public:
    virtual void main(int argc, char *argv[]);
    virtual int top(Node *n);
    virtual int functionWrapper(Node *n);
    virtual int destructorHandler(Node *n);
    virtual int constructorHandler(Node *n);
    virtual int classHandler(Node *n);
    virtual int memberfunctionHandler(Node *n);

    FORTRAN()
        : f_cur_methods(NULL)
        , d_in_constructor(false)
        , d_in_destructor(false)
    {
        /* * */
    }

  private:
    void write_wrapper();
    void write_module_interface();
    void write_module();

    // Helper functions
    String* get_simple_typemap(const char* tmname, Node* n,
                               const_String_or_char_ptr var = "");
    String* fortranprepend(Node* n);
    String* fortranappend(Node* n);
};

//---------------------------------------------------------------------------//
/*!
 * \brief Main function for code generation.
 */
void FORTRAN::main(int argc, char *argv[])
{
    (void)argc; (void)argv;

    /* Set language-specific subdirectory in SWIG library */
    SWIG_library_directory("fortran");

    /* Set language-specific preprocessing symbol */
    Preprocessor_define("SWIGFORTRAN 1", 0);

    /* Set typemap language (historical) */
    SWIG_typemap_lang("fortran");

    /* Set language-specific configuration file */
    SWIG_config_file("fortran.swg");

    /* TODO: Allow operator overloads */
    //allow_overloading();
}

//---------------------------------------------------------------------------//
/*!
 * \brief Top-level code generation function.
 */
int FORTRAN::top(Node *n)
{
    // Module name (from the SWIG %module command)
    d_module = Getattr(n, "name");
    // Output file name
    d_outpath = Getattr(n, "outfile");

    /* Initialize temporary file-like output strings */

    // run time code (beginning of .cxx file)
    f_begin = NewString("");
    Swig_register_filebyname("begin", f_begin);

    // run time code (beginning of .cxx file)
    f_runtime = NewString("");
    Swig_register_filebyname("runtime", f_runtime);

    // header code (after run time)
    f_header = NewString("");
    Swig_register_filebyname("header", f_header);

    // C++ wrapper code (middle of .cxx file)
    f_wrapper = NewString("");
    Swig_register_filebyname("wrapper", f_wrapper);

    // initialization code (end of .cxx file)
    f_init = NewString("");
    Swig_register_filebyname("init", f_init);

    // Other imported fortran modules
    f_imports = NewString("");
    Swig_register_filebyname("fimports", f_imports);

    // Public interface functions
    f_public = NewString("");
    Swig_register_filebyname("fpublic", f_public);

    // Fortran classes
    f_types = NewString("");
    Swig_register_filebyname("ftypes", f_types);

    // Fortran class constructors
    f_interfaces = NewString("");
    Swig_register_filebyname("finterfaces", f_interfaces);

    // Fortran subroutines (proxy code)
    f_proxy = NewString("");
    Swig_register_filebyname("fproxy", f_proxy);

    // Substitution code
    String *wrapper_name = NewString("swigc_%f");
    Swig_name_register("wrapper", wrapper_name);
    Delete(wrapper_name);

    /* Emit all other wrapper code */
    Language::top(n);

    /* Write fortran module files */
    write_wrapper();
    write_module();

    /* Cleanup files */
    Delete(f_proxy);
    Delete(f_interfaces);
    Delete(f_types);
    Delete(f_public);
    Delete(f_imports);
    Delete(f_init);
    Delete(f_wrapper);
    Delete(f_header);
    Delete(f_runtime);
    Delete(f_begin);

    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Write C++ wrapper code
 */
void FORTRAN::write_wrapper()
{
    // Open file
    File* out = NewFile(d_outpath, "w", SWIG_output_files());
    if (!out)
    {
        FileErrorDisplay(d_outpath);
        SWIG_exit(EXIT_FAILURE);
    }

    // Write SWIG auto-generation banner
    Swig_banner(out);

    // Write three different levels of output
    Dump(f_begin,    out);
    Dump(f_runtime,  out);
    Dump(f_header,   out);

    // Write wrapper code
    Printf(out, "#ifdef __cplusplus\n");
    Printf(out, "extern \"C\" {\n");
    Printf(out, "#endif\n");
    Dump(f_wrapper, out);
    Printf(out, "#ifdef __cplusplus\n");
    Printf(out, "}\n");
    Printf(out, "#endif\n");

    // Write initialization code
    Wrapper_pretty_print(f_init, out);

    // Close file
    Delete(out);
}

//---------------------------------------------------------------------------//
/*!
 * \brief Write Fortran implementation module
 */
void FORTRAN::write_module()
{
    // Open file
    String* path = NewStringf(
            "%s%s.f90", SWIG_output_directory(), Char(d_module));
    File* out = NewFile(path, "w", SWIG_output_files());
    if (!out)
    {
        FileErrorDisplay(path);
        SWIG_exit(EXIT_FAILURE);
    }
    Delete(path);

    // Write SWIG auto-generation banner
    Swig_banner_target_lang(out, "!");

    // Write module
    Printf(out, "module %s\n", d_module);
    Printf(out, " use, intrinsic :: ISO_C_BINDING\n");
    Printv(out, f_imports, NULL);
    Printf(out, " implicit none\n");
    Printf(out, " ! PUBLIC METHODS AND TYPES\n");
    Printv(out, f_public, NULL);
    Printf(out, " ! TYPES\n");
    Printv(out, f_types, NULL);
    Printf(out, " ! INTERFACES\n");
    Printf(out, " private\n");
    Printf(out, " interface\n");
    Printv(out, f_interfaces, NULL);
    Printf(out, " end interface\n");
    Printf(out, "contains\n");
    Printf(out, " ! FORTRAN PROXY CODE\n");
    Printv(out, f_proxy, NULL);
    Printf(out, "end module %s\n", d_module);

    // Close file
    Delete(out);
}

//---------------------------------------------------------------------------//
/*!
 * \brief Wrap basic functions.
 *
 * This is also passed class methods.
 */
int FORTRAN::functionWrapper(Node *n)
{
    // Basic attributes (references)
    String* symname = Getattr(n, "sym:name");
    SwigType* type = Getattr(n, "type");
    ParmList* parmlist = Getattr(n, "parms");

    // Create wrapper name, taking into account overloaded functions
    String* wname = Copy(Swig_name_wrapper(symname));
    if (Getattr(n, "sym:overloaded"))
    {
        String* overname = Getattr(n, "sym:overname");
        Append(wname, overname);
    }
    else
    {
        if (!addSymbol(symname, n))
            return SWIG_ERROR;
    }
    Setattr(n, "wrap:name", wname);

    // Add fortran proxy name
    String* fwname;
    if (is_wrapping_class())
    {
        fwname = Copy(wname);
        Replace(fwname, "swigc", "swigf", DOH_REPLACE_FIRST);
    }
    else
    {
        // Replace with actual function name
        fwname = Copy(symname);
    }
    Setattr(n, "fortran:name", fwname);

    // A new wrapper function object
    Wrapper* f = NewWrapper();

    // Make a wrapper name for this function

    /* Attach the non-standard typemaps to the parameter list. */
    Swig_typemap_attach_parms("fcptype", parmlist, f);
    Swig_typemap_attach_parms("fcrtype", parmlist, f);
    Swig_typemap_attach_parms("fitype", parmlist, f);
    Swig_typemap_attach_parms("fxtype", parmlist, f);
    Swig_typemap_attach_parms("fxget", parmlist, f);

    /* Get return types */

    // Get C type
    String *c_return_type = get_simple_typemap("fcrtype", n);
    Printv(f->def, "SWIGEXPORT ", c_return_type, " ", wname, "(", NULL);

    // Function attributes
    bool is_subroutine = (Cmp(c_return_type, "void") == 0);

    // Add local variable for result
    if (!is_subroutine)
    {
        Wrapper_add_localv(f, "fresult", c_return_type, "fresult = 0", NULL);
    }
    Delete(c_return_type); c_return_type = NULL;

    // SWIG: Emit all of the local variables for holding arguments.
    emit_parameter_variables(parmlist, f);
    emit_attach_parmmaps(parmlist, f);
    Setattr(n, "wrap:parms", parmlist);

#if 0
    // Wrappers not wanted for some methods where the parameters cannot be overloaded in Fortran
    if (Getattr(n, "sym:overloaded"))
    {
        // Emit warnings for the few cases that can't be overloaded in Fortran and give up on generating wrapper
        Swig_overload_check(n);
        if (Getattr(n, "overload:ignore"))
        {
            DelWrapper(f);
            return SWIG_OK;
        }
    }
#endif

    // Now walk the function parameter list and generate code to get arguments
    String* nondir_args = NewString("");

    // Fortran interface parameters
    String* fiparams = NewString(
        "   use, intrinsic :: ISO_C_BINDING\n"
        "   implicit none\n");
    String* fxparams = NewString(
        "  use, intrinsic :: ISO_C_BINDING\n"
        "  implicit none\n");

    // Set up return value types if it's a function (rather than subroutine)
    if (!is_subroutine)
    {
        // Get Fortran interface return type
        String* f_return_type = get_simple_typemap("fitype", n);
        Printf(fiparams, "   %s :: fresult\n", f_return_type);
        Delete(f_return_type);

        // Get Fortran proxy return type (for constructors, this is
        // repurposed as a dummy argument)
        f_return_type = get_simple_typemap("fxtype", n);
        Printf(fxparams, "  %s :: fresult\n", f_return_type);
        Delete(f_return_type);
    }

    // Fortran proxy parameters
    String* fargs      = NewString("");
    String* fxcallargs = NewString("");

    const char* prepend_comma = "";

    Parm* p = parmlist;
    while (p)
    {
        while (checkAttribute(p, "tmap:in:numinputs", "0"))
        {
            p = Getattr(p, "tmap:in:next");
        }
        if (!p)
        {
            Swig_error(Getfile(n), Getline(n), "while iterating through typemap inputs"
                     " for function %s.\n", symname);
            return SWIG_ERROR;
        }

        // Construct conversion argument name
        String *arg = NewString("");
        String *lname = Getattr(p, "lname");
        Printf(arg, "f%s", lname);

        /* Get the C types of the parameter */
        String *c_param_type = get_simple_typemap("fcptype", p);
        Printv(f->def, prepend_comma, c_param_type, " ", arg, NULL);
        Delete(c_param_type); c_param_type = NULL;

        /* Add parameter to C function */

        // Get typemap for this argument
        String* tm = Getattr(p, "tmap:in");
        if (tm)
        {
            Replaceall(tm, "$input", arg);
            Setattr(p, "emit:input", arg);
            Printf(nondir_args, "%s\n", tm);
        }
        else
        {
            SwigType *param_type = Getattr(p, "type");
            Swig_warning(WARN_TYPEMAP_IN_UNDEF, input_file, line_number,
                         "Unable to use type %s as a function argument.\n", SwigType_str(param_type, 0));
        }

        /* Add parameter to fortran interface declarations */
        
        // Add parameter name to declaration list
        Printv(fargs, prepend_comma, arg, NULL);

        // Add parameter type to the parameters list
        String *fi_param_type = get_simple_typemap("fitype", p);
        Printv(fiparams, "   ", fi_param_type, " :: ", arg, "\n", NULL);
        Delete(fi_param_type);

        /* Get main subroutine "call" argument */

        /* Add parameter to fortran wrapper declarations */
        
        // Add parameter type to the parameters list
        String *fxparam_type = get_simple_typemap("fxtype", p);
        Printv(fxparams, "   ", fxparam_type, " :: ", arg, "\n", NULL);
        Delete(fxparam_type);

        // Add parameter type to the parameters list
        String *fxcall_arg = get_simple_typemap("fxget", p, arg);
        Printv(fxcallargs, prepend_comma, fxcall_arg, NULL);
        Delete(fxcall_arg);

        Delete(arg);

        prepend_comma = ", ";
        p = nextSibling(p);
    }

    Printv(f->code, nondir_args, NULL);
    Delete(nondir_args);

    /* Insert constraint checking code */
    p = parmlist;
    while (p)
    {
        if (String* tm = Getattr(p, "tmap:check"))
        {
            Replaceall(tm, "$input", Getattr(p, "emit:input"));
            Printv(f->code, tm, "\n", NULL);
            p = Getattr(p, "tmap:check:next");
        }
        else
        {
            p = nextSibling(p);
        }
    }

    /* Insert cleanup code */
    String *cleanup = NewString("");
    p = parmlist;
    while (p)
    {
        if (String* tm = Getattr(p, "tmap:freearg"))
        {
            Replaceall(tm, "$input", Getattr(p, "emit:input"));
            Printv(cleanup, tm, "\n", NULL);
            p = Getattr(p, "tmap:freearg:next");
        }
        else
        {
            p = nextSibling(p);
        }
    }

    /* Insert argument output code */
    String *outarg = NewString("");
    p = parmlist;
    while (p)
    {
        if (String* tm = Getattr(p, "tmap:argout"))
        {
            Replaceall(tm, "$result", "fresult");
            Replaceall(tm, "$input", Getattr(p, "emit:input"));
            Printv(outarg, tm, "\n", NULL);
            p = Getattr(p, "tmap:argout:next");
        }
        else
        {
            p = nextSibling(p);
        }
    }

    // Now write code to make the function call
    Swig_director_emit_dynamic_cast(n, f);
    String *actioncode = emit_action(n);

    /* Return value if necessary  */
    {
        if (String* tm = Swig_typemap_lookup_out("out", n, Swig_cresult_name(), f, actioncode))
        {
            Replaceall(tm, "$result", "fresult");
            Replaceall(tm, "$owner", (GetFlag(n, "feature:new") ? "1" : "0"));

            Printf(f->code, "%s", tm);
            if (Len(tm))
                Printf(f->code, "\n");
        }
        else
        {
            Swig_warning(WARN_TYPEMAP_OUT_UNDEF, input_file, line_number,
                         "Unable to use return type %s in function %s.\n",
                         SwigType_str(type, 0), Getattr(n, "name"));
        }
        emit_return_variable(n, type, f);
    }

    /* Output argument output code */
    Printv(f->code, outarg, NULL);

    /* Output cleanup code */
    Printv(f->code, cleanup, NULL);

    /* Finish C function and intermediary class function definitions */
    Printf(f->def, ") {");

    if (!is_subroutine)
        Printv(f->code, "    return fresult;\n", NULL);
    Printf(f->code, "}\n");

    /* Standard SWIG substitutions */
    Replaceall(f->code, "$cleanup", cleanup);
    Replaceall(f->code, "$symname", symname);
    Replaceall(f->code, "SWIG_contract_assert(", "SWIG_contract_assert($null, ");
    Replaceall(f->code, "$null", (is_subroutine ? "" : "0"));

    /* Write the C++ function into the wrapper code file */
    Wrapper_print(f, f_wrapper);

    const char* sub_or_func_str = (is_subroutine ? "subroutine" : "function");
    const char* result_str = (is_subroutine ? "\n" : " &\n     result(fresult)\n");

    /* Write the Fortran interface to the C routine */
    Printv(f_interfaces,
           "   ", sub_or_func_str, " ", wname, "(", fargs, ")",
           " &\n     bind(C, name=\"", wname, "\")",
           result_str,
           fiparams,
           "   end ", sub_or_func_str, "\n",
           NULL);

    // Get strings to append and prepend if needed
    const_String_or_char_ptr prepend = fortranprepend(n);
    if (!prepend) prepend = "";
    const_String_or_char_ptr append = fortranappend(n);
    if (!append) append = "";

    /* Write the subroutine proxy code */
    if (d_in_constructor)
    {
        // Constructors get returned into subroutines, and have a dummy 'this'
        // parameter
        Printv(f_proxy,
               " subroutine ", fwname, "(fresult", prepend_comma, fargs, ")\n",
               fxparams,
               prepend,
               "  fresult%ptr = ", wname, "(", fxcallargs, ")\n",
               append,
               " end subroutine\n",
               NULL);
    }
    else
    {
        Printv(f_proxy,
               " ", sub_or_func_str, " ", fwname, "(", fargs, ")",
               result_str,
               fxparams,
               prepend,
               "  ", (is_subroutine ? "call " : "fresult = "), wname, "(", fxcallargs, ")\n",
               append,
               " end ", sub_or_func_str, "\n",
               NULL);
    }
        
    /* Write type or public aliases */
    if (is_wrapping_class())
    {
        // Write class interface
        assert(f_cur_methods);

        // Given function name (renamed to ctor/dtor if needed)
        String *name = Getattr(n, "name");

        // Print remapping
        Printv(f_cur_methods,
               "  procedure :: ", name, " => ", fwname, "\n",
               NULL);
    }
    else
    {
        // Not a class: make the function public (and alias the name)
        Printv(f_public,
               " public :: ", symname, "\n",
               NULL);
    }

    // TODO: cleanup code needs to be written to C wrapper
    Delete(outarg);
    Delete(cleanup);
    Delete(fargs);
    Delete(fiparams);
    Delete(fxparams);
    Delete(fxcallargs);
    DelWrapper(f);
    Delete(wname);
    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Process classes.
 */
int FORTRAN::classHandler(Node *n)
{
    // Basic attributes
    String *symname = Getattr(n, "sym:name");
    String *real_classname = Getattr(n, "name");

    if (!addSymbol(symname, n))
        return SWIG_ERROR;

    /* No base classes are currently supported */
    List *baselist = Getattr(n, "bases");
    if (baselist && Len(baselist))
    {
        Swig_warning(WARN_LANG_NATIVE_UNIMPL, Getfile(n), Getline(n),
                "Inheritance (class '%s') currently unimplemented.\n",
                SwigType_namestr(Char(symname)));
    }

    /* Initialize strings that will be populated by class members */
    assert(!f_cur_methods);
    f_cur_methods = NewString("");

    /* Emit class members */
    Language::classHandler(n);

    /* Add types */
    String *smartptr = Getattr(n, "feature:smartptr");
    SwigType *smart = 0;
    if (smartptr)
    {
        SwigType *cpt = Swig_cparse_type(smartptr);
        if (cpt)
        {
            smart = SwigType_typedef_resolve_all(cpt);
            Delete(cpt);
        }
        else
        {
            // TODO: report line number of where the feature comes from
            Swig_error(Getfile(n), Getline(n), "Invalid type (%s) in 'smartptr' "
                     " feature for class %s.\n", smartptr, real_classname);
        }
    }
    SwigType *ct = Copy(smart ? smart : real_classname);
    SwigType_add_pointer(ct);
    SwigType *realct = Copy(real_classname);
    SwigType_add_pointer(realct);
    Delete(smart);
    Delete(ct);
    Delete(realct);

    /* Write public accessibility */
    Printv(f_public, " public :: ", symname, "\n",
                    NULL);

    /* Write fortran class header */
    Printv(f_types, " type ", symname, "\n"
                    "  type(C_PTR), private :: ptr = C_NULL_PTR\n"
                    " contains\n",
                    f_cur_methods,
                    " end type\n",
                    NULL);

    Delete(f_cur_methods); f_cur_methods = NULL;

    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Extra stuff for constructors.
 */
int FORTRAN::constructorHandler(Node* n)
{
    String* newname = NewString("ctor");
    Setattr(n, "name", newname);
    d_in_constructor = true;
    Language::constructorHandler(n);
    d_in_constructor = false;
    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Handle extra destructor stuff.
 */
int FORTRAN::destructorHandler(Node* n)
{
    String* newname = NewString("dtor");
    Setattr(n, "name", newname);
    d_in_destructor = true;
    Language::destructorHandler(n);
    d_in_destructor = false;
    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Process member functions.
 */
int FORTRAN::memberfunctionHandler(Node *n)
{
    Language::memberfunctionHandler(n);
    return SWIG_OK;
}

//---------------------------------------------------------------------------//
// Returns a new string for a typemap that accepts no arguments
String* FORTRAN::get_simple_typemap(const char* tmname, Node* n,
                                    const_String_or_char_ptr var)
{
    String* tm = Swig_typemap_lookup(tmname, n, var, NULL);
    String* result = NULL;
    if (tm)
    {
        result = Copy(tm);
    }
    else
    {
        SwigType *type = Getattr(n, "type");
        result = NewString("");
        Printv(result, "UNKNOWN_", type, NULL);
        Swig_warning(WARN_FORTRAN_TYPEMAP_FTYPE_UNDEF,
                     input_file, line_number,
                     "No %s typemap defined for %s\n", tmname,
                     SwigType_str(type, 0));
    }
    return result;
}

//---------------------------------------------------------------------------//
// Return fortran code to be inserted at the beginning of a proxy function
String* FORTRAN::fortranprepend(Node* n)
{
    String *str = Getattr(n, "feature:fortranprepend");
    if (!str)
        return NULL;

    char *t = Char(str);
    if (*t == '{')
    {
        Delitem(str, 0);
        Delitem(str, DOH_END);
    }
    return str;
}

//---------------------------------------------------------------------------//
// Return fortran code to be inserted at the end of a proxy function
String* FORTRAN::fortranappend(Node* n)
{
    String *str = Getattr(n, "feature:fortranappend");
    if (!str)
        return NULL;

    char *t = Char(str);
    if (*t == '{')
    {
        Delitem(str, 0);
        Delitem(str, DOH_END);
    }
    return str;
}

//---------------------------------------------------------------------------//
// Expose the code to the SWIG main function.
//---------------------------------------------------------------------------//
extern "C" Language *
swig_fortran(void)
{
    return new FORTRAN();
}
