#include "swigmod.h"
#include "cparse.h"

namespace
{
const char usage[] = "\
Fotran Options (available with -fortran)\n\
     -noproxy    - Expose the low-level functional interface instead\n\
                   of generatingproxy classes\n\
     -final      - Generate 'final' statement to call C++ destructors\n\
\n";
}

class FORTRAN : public Language
{
  private:
    // >>> ATTRIBUTES AND OPTIONS

    String *d_module; //!< Module name
    String *d_outpath; //!< WRAP.cxx output

    bool d_use_proxy; //!< Whether to generate proxy classes
    bool d_use_final; //!< Whether to use the 'final' keyword for destructors

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

    virtual String *makeParameterName(Node *n, Parm *p, int arg_num,
                                      bool is_setter = false) const;

    FORTRAN()
        : d_module(NULL)
        , d_outpath(NULL)
        , d_use_proxy(true)
        , d_use_final(false)
        , f_cur_methods(NULL)
        , d_in_constructor(false)
        , d_in_destructor(false)
    {
        /* * */
    }

  private:
    void write_wrapper();
    void write_module_interface();
    void write_module();

    void write_proxy_code(Node* n, bool is_subroutine);

    // Helper functions
    String* get_typemap(const char* tmname, Node* n);
    String* get_typemap_out(const char* tmname, Node* n);
    String* fortranprepend(Node* n);
    String* fortranappend(Node* n);
    bool substitute_classname(SwigType *pt, String *tm);
    void substitute_classname_impl(SwigType *classnametype, String *tm,
                                   const char *classnamespecialvariable);
};

//---------------------------------------------------------------------------//
/*!
 * \brief Main function for code generation.
 */
void FORTRAN::main(int argc, char *argv[])
{
    /* Set language-specific subdirectory in SWIG library */
    SWIG_library_directory("fortran");

    // Set command-line options
    for (int i = 1; i < argc; ++i)
    {
        if ((strcmp(argv[i], "-noproxy") == 0))
        {
            Swig_mark_arg(i);
            d_use_proxy = false;
        }
        else if ((strcmp(argv[i], "-final") == 0))
        {
            Swig_mark_arg(i);
            d_use_final = true;
        }
        else if ((strcmp(argv[i], "-help") == 0))
        {
            Printv(stdout, usage, NULL);
        }
    }

    /* Set language-specific preprocessing symbol */
    Preprocessor_define("SWIGFORTRAN 1", 0);

    /* Set typemap language (historical) */
    SWIG_typemap_lang("fortran");

    /* Set language-specific configuration file */
    SWIG_config_file("fortran.swg");

    /* TODO: Allow function overloads */
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
    Printf(out, "  ! FORTRAN PROXY CODE\n");
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
    // Basic attributes
    String* symname    = Getattr(n, "sym:name");
    ParmList* parmlist = Getattr(n, "parms");

    // >>> INITIALIZE

    // Create wrapper name, taking into account overloaded functions
    String* wname  = Copy(Swig_name_wrapper(symname));
    const bool is_overloaded = Getattr(n, "sym:overloaded");
    if (is_overloaded)
    {
        Append(wname, Getattr(n, "sym:overname"));
    }
    else
    {
        if (!addSymbol(symname, n))
            return SWIG_ERROR;
    }

    String* imfuncname = NULL;
    if (is_wrapping_class())
    {
        imfuncname = NewStringf("swigf_%s", symname);
        if (is_overloaded)
        {
            Append(imfuncname, Getattr(n, "sym:overname"));
        }
    }
    else
    {
        // Use actual symbolic function name
        imfuncname = Copy(symname);
    }
    Setattr(n, "wrap:name", wname);
    Setattr(n, "imfuncname", imfuncname);
    Delete(imfuncname);

    // A new wrapper function object
    Wrapper* f = NewWrapper();

    // Attach the non-standard typemaps to the parameter list.
    Swig_typemap_attach_parms("ctype",  parmlist, f);
    Swig_typemap_attach_parms("imtype", parmlist, f);

    // Get C return type
    String* c_return_type = get_typemap_out("ctype", n);
    Printv(f->def, "SWIGEXPORT ", c_return_type, " ", wname, "(", NULL);

#if 0
    for (Parm* p = parmlist; p; p = nextSibling(p))
    {
        Swig_print_node(p);
    }
#endif

    // Function attributes
    const bool is_subroutine = (Cmp(c_return_type, "void") == 0);

    // Add local variable for result
    if (!is_subroutine)
    {
        Wrapper_add_localv(f, "fresult", c_return_type, "fresult = 0", NULL);
    }

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

    // >>> BUILD WRAPPER FUNCTION AND INTERFACE CODE

    // Fortran interface parameters and wrapper code parameters
    String* params = NewString(
        "   use, intrinsic :: ISO_C_BINDING\n");

    // Set up return value types if it's a function (rather than subroutine)
    if (!is_subroutine)
    {
        // Get Fortran interface return type
        String* f_return_type = get_typemap_out("imtype", n);
        Printf(params, "   %s :: fresult\n", f_return_type);
        Delete(f_return_type);
    }

    String* args = NewString("");
    const char* prepend_comma = "";
    Parm* p = parmlist;
    while (p)
    {
        while (checkAttribute(p, "tmap:in:numinputs", "0"))
        {
            p = Getattr(p, "tmap:in:next");
        }

        // Construct conversion argument name
        String *arg = NewStringf("f%s", Getattr(p, "lname"));

        /* Get the C types of the parameter */
        String *c_param_type = get_typemap("ctype", p);
        Printv(f->def, prepend_comma, c_param_type, " ", arg, NULL);
        Delete(c_param_type); c_param_type = NULL;

        // Get typemap for this argument
        if (String* tm = Getattr(p, "tmap:in"))
        {
            Replaceall(tm, "$input", arg);
            Setattr(p, "emit:input", arg);
            Printv(f->code, tm, "\n", NULL);
        }
        else
        {
            SwigType *param_type = Getattr(p, "type");
            Swig_warning(WARN_TYPEMAP_IN_UNDEF, input_file, line_number,
                         "Unable to use type %s as a function argument.\n",
                         SwigType_str(param_type, 0));
        }

        // Add parameter name to declaration list
        Printv(args, prepend_comma, arg, NULL);

        // Add parameter type to the parameters list
        String* ftype = get_typemap("imtype", p);
        Printv(params, "   ", ftype, " :: ", arg, "\n", NULL);
        Delete(ftype);

        // Next iteration
        prepend_comma = ", ";
        p = nextSibling(p);
    }
    // Done with C function arguments
    Printf(f->def, ") {");

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
    String* actioncode = emit_action(n);

    /* Return value if necessary  */
    {
        SwigType* type = Getattr(n, "type");
        if (String* tm = Swig_typemap_lookup_out(
                        "out", n, Swig_cresult_name(), f, actioncode))
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

    if (!is_subroutine)
    {
        String* qualified_return = SwigType_rcaststr(c_return_type, "fresult");
        Printf(f->code, "    return %s;\n", qualified_return);
        Delete(qualified_return);
    }
    Printf(f->code, "}\n");

    /* Standard SWIG substitutions */
    Replaceall(f->code, "$cleanup", cleanup);
    Replaceall(f->code, "$symname", symname);
    Replaceall(f->code, "SWIG_contract_assert(", "SWIG_contract_assert($null, ");
    Replaceall(f->code, "$null", (is_subroutine ? "" : "0"));

    /* Write the C++ function into the wrapper code file */
    Wrapper_print(f, f_wrapper);
    Delete(outarg);
    Delete(c_return_type);
    Delete(cleanup);
    DelWrapper(f);

    // >>> WRITE INTERFACE CODE

    const char* sub_or_func_str = (is_subroutine ? "subroutine" : "function");
    const char* result_str = (is_subroutine ? "\n" : " &\n     result(fresult)\n");

    /* Write the Fortran interface to the C routine */
    Printv(f_interfaces,
           "  ", sub_or_func_str, " ", wname, "(", args, ")",
           " &\n     bind(C, name=\"", wname, "\")",
           result_str,
           params,
           "  end ", sub_or_func_str, "\n",
           NULL);
    Delete(args);
    Delete(params);
    Delete(wname);

    // >>> WRITE PROXY CODE

    write_proxy_code(n, is_subroutine);

    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Write the proxy subroutine/function code.
 *
 * \param[in] n Function node
 * \param[in] imfuncname Wrapped function name
 * \param[in] is_subroutine Whether the function has 'void' return type
 */
void FORTRAN::write_proxy_code(Node* n, bool is_subroutine)
{
    String* wname  = Getattr(n, "wrap:name");
    String* imfuncname = Getattr(n, "imfuncname");

    // Set up proxy subroutine label.
    const char* sub_or_func_str = NULL;
    const char* result_str = NULL;
    if (d_in_constructor)
    {
        // Constructors (which to SWIG is a function that returns a 'new'
        // variable) gets turned into a subroutine with the dummy 'this'
        // parameter that we bind to the result of the 'new' function
        sub_or_func_str = "subroutine";
        result_str = "\n";
        is_subroutine = true;
    }
    else if (is_subroutine)
    {
        // Subroutine that's not a constructor
        sub_or_func_str = "subroutine";
        result_str = "\n";
    }
    else
    {
        sub_or_func_str = "function";
        result_str = " &\n     result(output)\n";
    }

    // Get strings to append and prepend if needed
    String* prepend = NewString("");
    String* append = NewString("");
    Printv(prepend, fortranprepend(n), NULL);

    // Set up function call, parameter list, and input arguments
    String* params = NewString(
        "   use, intrinsic :: ISO_C_BINDING\n");
    String* callcmd = NewString("   ");
    String* args = NewString("");

    const char* arg_prepend_comma = "";
    const char* call_prepend_comma = "";
    if (d_in_constructor)
    {
        Printv(callcmd, "self%ptr = ", wname, "(", NULL);
        Printv(args, "self", NULL);

        String* f_return_type = get_typemap_out("ftype", n);
        Printv(params, "   ", f_return_type, " :: self\n", NULL);
        Delete(f_return_type);

        arg_prepend_comma = ", ";
    }
    else if (is_subroutine)
    {
        Printv(callcmd, "call ", wname, "(", NULL);
    }
    else
    {
        Printv(callcmd, "output = ", wname, "(", NULL);

        // Get Fortran proxy return type (for constructors, this is
        // repurposed as a dummy argument)
        String* f_return_type = get_typemap_out("ftype", n);
        Printv(params, "   ", f_return_type, " :: output\n", NULL);
        Delete(f_return_type);
    }

    // Get parameters and bind our wrapper typemaps
    ParmList* p = Getattr(n, "parms");
    Swig_typemap_attach_parms("ftype", p, NULL);
    Swig_typemap_attach_parms("fin", p, NULL);

    int i = 0;
    while (p)
    {
        while (checkAttribute(p, "tmap:fin:numinputs", "0"))
        {
            p = Getattr(p, "tmap:fin:next");
            ++i;
        }
        assert(p);
        String* argname = this->makeParameterName(n, p, i++);

        // Add parameter name to argument list
        Printv(args, arg_prepend_comma, argname, NULL);

        // Add parameter to function call
        String *fin_tm = get_typemap("fin", p);
        Printv(callcmd, call_prepend_comma, fin_tm, NULL);
        Delete(fin_tm);

        // Add parameter type to the fortran interface parameters list
        String* ftype = get_typemap("ftype", p);
        Printv(params, "   ", ftype, " :: ", argname, "\n", NULL);
        Delete(ftype);
        Delete(argname);

        // Check for insertion code
        if (String *tm = Getattr(p, "tmap:fin:pre"))
        {
            tm = Copy(tm);
            substitute_classname(Getattr(p, "type"), tm);
            if (Len(tm) > 0)
            {
                Printv(prepend, "   ", tm, "\n", NULL);
            }
        }
        if (String *tm = Getattr(p, "tmap:fin:post"))
        {
            tm = Copy(tm);
            substitute_classname(Getattr(p, "type"), tm);
            if (Len(tm) > 0)
            {
                Printv(append, "   ", tm, "\n", NULL);
            }
        }

        // Next parameter
        arg_prepend_comma = call_prepend_comma = ", ";
        p = Getattr(p, "tmap:fin:next");
    }
    Printv(callcmd, ")\n", NULL);

    // Get code to append
    Printv(append, fortranappend(n), NULL);

    if (d_in_constructor)
    {
        // Deallocate if we're already allocated
        Printv(prepend, "   if (c_associated(self%ptr)) call self%release()\n",
               NULL);

    }
    if (d_in_destructor)
    {
        // Zero the pointer for safety
        Printv(append, "   self%ptr = C_NULL_PTR\n", NULL);
    }

    // Write
    Printv(f_proxy,
           "  ", sub_or_func_str, " ", imfuncname, "(", args, ")",
           result_str,
           params,
           prepend,
           callcmd,
           append,
           "  end ", sub_or_func_str, "\n",
           NULL);

    /* Write type or public aliases */
    if (is_wrapping_class())
    {
        // Get aliased name
        String* alias = Getattr(n, "fortran:membername");
        assert(alias);

        // Print remapping
        assert(f_cur_methods);
        Printv(f_cur_methods,
               "  procedure :: ", alias, " => ", imfuncname, "\n",
               NULL);
    }
    else
    {
        // Not a class: make the function public (and alias the name)
        String* symname = Getattr(n, "sym:name");
        Printv(f_public,
               " public :: ", symname, "\n",
               NULL);
    }

    Delete(args);
    Delete(callcmd);
    Delete(params);
}

//---------------------------------------------------------------------------//
/*!
 * \brief Create a friendly parameter name
 */
String* FORTRAN::makeParameterName(Node *n, Parm *p,
                                   int arg_num, bool setter) const
{
    String *name = Getattr(p, "name");
    if (name)
        return Swig_name_make(p, 0, name, 0, 0);

    // The general function which replaces arguments whose
    // names clash with keywords with (less useful) "argN".
    return Language::makeParameterName(n, p, arg_num, setter);
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

    // Process base classes
    List *baselist = Getattr(n, "bases");
    if (baselist && Len(baselist))
    {
        Swig_warning(WARN_LANG_NATIVE_UNIMPL, Getfile(n), Getline(n),
                "Inheritance (class '%s') currently unimplemented.\n",
                SwigType_namestr(symname));
    }

    // Initialize output strings that will be added by 'functionHandler'
    assert(!f_cur_methods);
    f_cur_methods = NewString("");

    // Emit class members
    Language::classHandler(n);

    // Process smart pointers
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

    // Make the class publically accessible
    Printv(f_public, " public :: ", symname, "\n",
                    NULL);

    // Write Fortran class header
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
    Node *classn = getCurrentClass();
    assert(classn);

    // Possibly renamed constructor (default: name of the class)
    String* symname = Getattr(n, "sym:name");
    String* classname = Getattr(classn, "sym:name");

    const_String_or_char_ptr alias = "create";
    if (Cmp(symname, classname))
    {
        // User provided a custom name (it differs from the class name)
        // Printf(stderr, "User aliased constructor name %s => %s\n",
        //        Getattr(classn, "sym:name"), symname);
        alias = symname;

        // To avoid conflicts with templated functions, modify the
        // constructor's symname
        String* mrename = NewStringf("%s_%s", classname, symname);
        Setattr(n, "sym:name", mrename);
        Delete(mrename);
    }
    Setattr(n, "fortran:membername", alias);

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
    Setattr(n, "fortran:membername", "release");
    d_in_destructor = true;
    Language::destructorHandler(n);
    d_in_destructor = false;

    if (d_use_final)
    {
        // Create 'final' name wrapper
        String* imfuncname = NewStringf("swigf_final_%s",
                                        Getattr(n, "sym:name"));
        String* classname = Getattr(getCurrentClass(), "sym:name");

        // Add the 'final' subroutine to the methods
        Printv(f_cur_methods, "  final     :: ", imfuncname, "\n",
               NULL);

        // Add the 'final' implementation
        Printv(f_proxy, 
           "  subroutine ", imfuncname, "(self)\n"
           "   use, intrinsic :: ISO_C_BINDING\n"
           "   type(", classname, ") :: self\n"
           "   call ", Getattr(n, "wrap:name"), "(self%ptr)\n"
           "   self%ptr = C_NULL_PTR\n"
           "  end subroutine\n",
           NULL);

        // Add implementation
        Delete(imfuncname);
    }
    
    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Process member functions.
 */
int FORTRAN::memberfunctionHandler(Node *n)
{
    Setattr(n, "fortran:membername", Getattr(n, "sym:name"));
    Language::memberfunctionHandler(n);
    return SWIG_OK;
}

//---------------------------------------------------------------------------//
// Returns a new string for a typemap that accepts no arguments, with special
// substitutions performed on the result
String* FORTRAN::get_typemap(const char* tmname, Node* n)
{
    //String* tm = Swig_typemap_lookup(tmname, n, var, NULL);
    String* tmkey = NewStringf("tmap:%s", tmname);
    String* tm = Getattr(n, tmkey);
    Delete(tmkey);
    String* result = NULL;
    if (tm)
    {
        result = Copy(tm);
        bool applied = substitute_classname(Getattr(n, "type"), result);
#if 0
        Printf(stderr, "%c Substitutetypemap %8s: node %8s type %8s: %8s => %8s\n",
               (applied ? '*' : ' '), tmname, Getattr(n, "name"),
               Getattr(n, "type"), tm, result);
#else
        (void)sizeof(applied);
#endif
    }
    else
    {
        SwigType *type = Getattr(n, "type");
        result = NewStringf("SWIGTYPE%s", SwigType_manglestr(type));
        Swig_warning(WARN_FORTRAN_TYPEMAP_FTYPE_UNDEF,
                     input_file, line_number,
                     "No %s typemap defined for %s\n", tmname,
                     SwigType_str(type, 0));
    }
    return result;
}


//---------------------------------------------------------------------------//
// Returns a new string for a typemap that accepts no arguments, with special
// substitutions performed on the result
String* FORTRAN::get_typemap_out(const char* tmname, Node* n)
{
    String* tm = Swig_typemap_lookup(tmname, n, "", NULL);
    String* result = NULL;
    if (tm)
    {
        {
            // Check for output override typemap
            String* outkey = NewStringf("tmap:%s:out", tmname);
            String* alt_tm = Getattr(n, outkey);
            if (alt_tm)
                tm = alt_tm;
            Delete(outkey);
        }
        result = Copy(tm);
        bool applied = substitute_classname(Getattr(n, "type"), result);
#if 0
        Printf(stderr, "%c Substitute typemap %8s: node %8s type %8s: %8s => %8s\n",
               (applied ? '*' : ' '), tmname, Getattr(n, "name"),
               Getattr(n, "type"), tm, result);
#else
        (void)sizeof(applied);
#endif
    }
    else
    {
        SwigType *type = Getattr(n, "type");
        result = NewStringf("SWIGTYPE%s", SwigType_manglestr(type));
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
// Substitute the '$fortranclassname' variables with the Fortran proxy class
// wrapper names. Shamelessly stolen from the Java wrapper code.

bool FORTRAN::substitute_classname(SwigType *pt, String *tm)
{
    bool substitution_performed = false;
    SwigType *type = Copy(SwigType_typedef_resolve_all(pt));
    SwigType *strippedtype = SwigType_strip_qualifiers(type);

    if (Strstr(tm, "$fortranclassname"))
    {
        substitute_classname_impl(strippedtype, tm, "$fortranclassname");
        substitution_performed = true;
    }

    Delete(strippedtype);
    Delete(type);

    return substitution_performed;
}

void FORTRAN::substitute_classname_impl(SwigType *classnametype, String *tm,
                                        const char *classnamespecialvariable)
{
    String *replacementname;

    if (SwigType_isenum(classnametype))
    {
        replacementname = NewStringf("SWIGENUMTYPE%s",
                                     SwigType_manglestr(classnametype));
        Replace(replacementname, "enum ", "", DOH_REPLACE_ANY);
#if 0
        String *enumname = getEnumName(classnametype);
        if (enumname)
        {
            replacementname = Copy(enumname);
        }
        else
        {
            bool anonymous_enum = (Cmp(classnametype, "enum ") == 0);
            if (anonymous_enum)
            {
                replacementname = NewString("int");
            }
            else
            {
                // An unknown enum - one that has not been parsed (neither a C enum forward reference nor a definition) or an ignored enum
                replacementname = NewStringf("SWIGTYPE%s", SwigType_manglestr(classnametype));
                Replace(replacementname, "enum ", "", DOH_REPLACE_ANY);
            }
        }
#endif
    }
    else
    {
        Node *n = classLookup(classnametype);
        String *classname = NULL;
        if (n)
        {
            classname = Getattr(n, "sym:name");
        }

        if (classname)
        {
            replacementname = Copy(classname);
        }
        else
        {
            // use $descriptor if SWIG does not know anything about this type.
            // Note that any typedefs are resolved.
            Swig_warning(WARN_FORTRAN_TYPEMAP_FTYPE_UNDEF,
                         input_file, line_number,
                         "No class type found for %s\n",
                         SwigType_str(classnametype, 0));

            replacementname = NewStringf("SWIGTYPE%s",
                                         SwigType_manglestr(classnametype));
        }
    }
    Replaceall(tm, classnamespecialvariable, replacementname);
    Delete(replacementname);
}

//---------------------------------------------------------------------------//
// Expose the code to the SWIG main function.
//---------------------------------------------------------------------------//
extern "C" Language *
swig_fortran(void)
{
    return new FORTRAN();
}
