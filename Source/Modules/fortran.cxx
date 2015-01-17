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
    String *f_wrappers; //!< Wrapper code
    String *f_init; //!< C++ initalization functions

    // Injected into _I file
    String *f_interfaces; //!< interface code inside the _I file
    // Injected into _M file
    String *f_imports;    //!< Fortran "use" directives generated from %import
    String *f_types;      //!< Fortran _M path

  public:
    virtual void main(int argc, char *argv[]);
    virtual int top(Node *n);
    virtual int functionWrapper(Node *n);

  private:
    void write_wrapper();
    void write_module_interface();
    void write_module_code();
};

bool is_wrapping_class() { return false; }
bool is_wrapping_enum() { return false; }
bool is_wrapping_member() { return false; }

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
    f_wrappers = NewString("");
    Swig_register_filebyname("wrapper", f_wrappers);

    // initialization code (end of .cxx file)
    f_init = NewString("");
    Swig_register_filebyname("init", f_init);

    // Fortran interfaces (injected into _I.f90)
    f_interfaces = NewString("");
    Swig_register_filebyname("finterfaces", f_interfaces);

    // Other imported fortran modules
    f_imports = NewString("");
    Swig_register_filebyname("fimports", f_imports);

    // Fortran classes
    f_types = NewString("");
    Swig_register_filebyname("ftypes", f_types);

    /* Emit all other wrapper code */
    Language::top(n);

    /* Write fortran module files */
    write_wrapper();
    write_module_interface();
    write_module_code();

    /* Cleanup files */
    Delete(f_runtime);
    Delete(f_header);
    Delete(f_wrappers);
    Delete(f_init);
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
    Dump(f_wrappers, out);
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
 * \brief Write Fortran interface module
 */
void FORTRAN::write_module_interface()
{
    // Open file
    String* path = NewStringf(
            "%s%s_I.f90", SWIG_output_directory(), Char(d_module));
    File* out = NewFile(path, "w", SWIG_output_files());
    if (!out)
    {
        FileErrorDisplay(path);
        SWIG_exit(EXIT_FAILURE);
    }
    Delete(path);

    // Write SWIG auto-generation banner
    Swig_banner_target_lang(out, "!");

    // Write fortran header
    Printf(out, "module %s_I\n", d_module);
    Printf(out, " use, intrinsic :: ISO_C_BINDING\n");
    Printf(out, " interface\n");

    Dump(out, f_interfaces);

    Printf(out, " end interface\n");
    Printf(out, "end module %s_I\n", d_module);

    // Close file
    Delete(out);
}

//---------------------------------------------------------------------------//
/*!
 * \brief Write Fortran implementation module
 */
void FORTRAN::write_module_code()
{
    // Open file
    String* path = NewStringf(
            "%s%s_M.f90", SWIG_output_directory(), Char(d_module));
    File* out = NewFile(path, "w", SWIG_output_files());
    if (!out)
    {
        FileErrorDisplay(path);
        SWIG_exit(EXIT_FAILURE);
    }
    Delete(path);

    // Write SWIG auto-generation banner
    Swig_banner_target_lang(out, "!");

    // Write fortran header
    Printf(out, "module %s_M\n", d_module);
    Printf(out, " use, intrinsic :: ISO_C_BINDING\n");
    Printf(out, " use %s_I\n", d_module);
    Dump(out, f_imports);
    Dump(out, f_types);

    Printf(out, "end module %s_M\n", d_module);

    // Close file
    Delete(out);
}

//---------------------------------------------------------------------------//
/*!
 * \brief Wrap basic functions.
 */
int FORTRAN::functionWrapper(Node *n)
{
    //bool is_destructor = (Cmp(Getattr(n, "nodeType"), "destructor") == 0);

    // Basic attributes
    String *symname = Getattr(n, "sym:name");
    SwigType *type = Getattr(n, "type");
    ParmList *parmlist = Getattr(n, "parms");

    // Overloaded name
    String *overloaded_name = 0;
    if (Getattr(n, "sym:overloaded"))
    {
        overloaded_name = Getattr(n, "sym:overloaded_name");
    }
    else if (!addSymbol(symname, n))
    {
        return SWIG_ERROR;
    }
    else
    {
        overloaded_name = Copy(symname);
    }

    // A new wrapper function object
    Wrapper *f = NewWrapper();

    // Make a wrapper name for this function
    String *wname = Swig_name_wrapper(overloaded_name);

    /* Attach the non-standard typemaps to the parameter list. */
    Swig_typemap_attach_parms("fctype", parmlist, f);
    Swig_typemap_attach_parms("fftype", parmlist, f);

    /* Get return types */
    String *tm = Swig_typemap_lookup("fctype", n, "", 0);
    String *c_return_type = NewString("");
    if (tm)
    {
        Printf(c_return_type, "%s", tm);
    }
    else
    {
        Swig_warning(WARN_JAVA_TYPEMAP_JNI_UNDEF,
                input_file, line_number, "No fctype typemap defined for %s\n", SwigType_str(type, 0));
    }

    tm = Swig_typemap_lookup("fftype", n, "", 0);
    String *f_return_type = NewString("");
    if (tm)
    {
        Printf(f_return_type, "%s", tm);
    }
    else
    {
        Swig_warning(WARN_JAVA_TYPEMAP_JTYPE_UNDEF,
                input_file, line_number, "No fftype typemap defined for %s\n", SwigType_str(type, 0));
    }

    bool is_void_return = (Cmp(c_return_type, "void") == 0);
    if (!is_void_return)
        Wrapper_add_localv(f, "fresult", c_return_type, "fresult = 0", NULL);

    Printv(f->def, "SWIGEXPORT ", c_return_type, " ", wname, "(", NULL);

    // SWIG: Emit all of the local variables for holding arguments.
    emit_parameter_variables(parmlist, f);
    emit_attach_parmmaps(parmlist, f);

    // Parameter overloading
    Setattr(n, "wrap:parms", parmlist);
    Setattr(n, "wrap:name", wname);

    // Wrappers not wanted for some methods where the parameters cannot be overloaded in Fortran
    if (Getattr(n, "sym:overloaded"))
    {
        // Emit warnings for the few cases that can'type be overloaded in Fortran and give up on generating wrapper
        Swig_overload_check(n);
        if (Getattr(n, "overload:ignore"))
        {
            DelWrapper(f);
            return SWIG_OK;
        }
    }

    Printf(f_interfaces, " %s function %s &\n", f_return_type, overloaded_name);

    // Now walk the function parameter list and generate code to get arguments
    int gencomma = 0;
    Parm* p = parmlist;
    String* nondir_args = NewString("");
    int num_arguments = emit_num_arguments(parmlist);
    for (int i = 0; i < num_arguments; ++i)
    {
        while (checkAttribute(p, "tmap:in:numinputs", "0"))
        {
            p = Getattr(p, "tmap:in:next");
        }

        SwigType *pt = Getattr(p, "type");
        String *ln = Getattr(p, "lname");
        String *im_param_type = NewString("");
        String *c_param_type = NewString("");
        String *arg = NewString("");

        Printf(arg, "f%s", ln);

        /* Get the fctype C types of the parameter */
        if ((tm = Getattr(p, "tmap:fctype")))
        {
            Printv(c_param_type, tm, NULL);
        }
        else
        {
            Swig_warning(WARN_JAVA_TYPEMAP_JNI_UNDEF, input_file, line_number,
                    "No fctype typemap defined for %s\n", SwigType_str(pt, 0));
        }

        /* Get the intermediary class parameter types of the parameter */
        if ((tm = Getattr(p, "tmap:fftype")))
        {
            Printv(im_param_type, tm, NULL);
        }
        else
        {
            Swig_warning(WARN_JAVA_TYPEMAP_JTYPE_UNDEF, input_file, line_number,
                    "No fftype typemap defined for %s\n", SwigType_str(pt, 0));
        }

        /* Add parameter to intermediary class method */
        // if (gencomma)
        //     Printf(imclass_class_code, ", ");
        // Printf(imclass_class_code, "%s %s", im_param_type, arg);

        // Add parameter to C function
        Printv(f->def, ", ", c_param_type, " ", arg, NULL);

        ++gencomma;

        // Get typemap for this argument
        if ((tm = Getattr(p, "tmap:in")))
        {
            Replaceall(tm, "$input", arg);
            Setattr(p, "emit:input", arg);

            Printf(nondir_args, "%s\n", tm);

            p = Getattr(p, "tmap:in:next");
        }
        else
        {
            Swig_warning(WARN_TYPEMAP_IN_UNDEF, input_file, line_number,
                         "Unable to use type %s as a function argument.\n", SwigType_str(pt, 0));
            p = nextSibling(p);
        }

        Delete(im_param_type);
        Delete(c_param_type);
        Delete(arg);
    }

    Printv(f->code, nondir_args, NULL);
    Delete(nondir_args);

    /* Insert constraint checking code */
    p = parmlist;
    while (p)
    {
        if ((tm = Getattr(p, "tmap:check")))
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
        if ((tm = Getattr(p, "tmap:freearg")))
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
        if ((tm = Getattr(p, "tmap:argout"))) {
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
    {
        Swig_director_emit_dynamic_cast(n, f);
        String *actioncode = emit_action(n);

        /* Return value if necessary  */
        if ((tm = Swig_typemap_lookup_out("out", n, Swig_cresult_name(), f, actioncode)))
        {
            Replaceall(tm, "$result", "fresult");

            if (GetFlag(n, "feature:new"))
                Replaceall(tm, "$owner", "1");
            else
                Replaceall(tm, "$owner", "0");

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
    // Printf(imclass_class_code, ")");
    // Printf(imclass_class_code, ";\n");

    Printf(f->def, ") {");

    if (!is_void_return)
        Printv(f->code, "    return fresult;\n", NULL);
    Printf(f->code, "}\n");

    /* Substitute the cleanup code */
    Replaceall(f->code, "$cleanup", cleanup);

    /* Substitute the function name */
    Replaceall(f->code, "$symname", symname);

    /* Contract macro modification */
    Replaceall(f->code, "SWIG_contract_assert(", "SWIG_contract_assert($null, ");

    if (!is_void_return)
        Replaceall(f->code, "$null", "0");
    else
        Replaceall(f->code, "$null", "");

    /* Dump the function out */
    Wrapper_print(f, f_wrappers);

    if (!(true && is_wrapping_class()) && !is_wrapping_enum())
    {
        // moduleClassFunctionHandler(n);
    }

#if 0
    /*
     * Generate the proxy class getters/setters for public member variables.
     * Not for enums and constants.
     */
    if (true && is_wrapping_member() && !is_wrapping_enum())
    {
        // Capitalize the first letter in the variable to create a JavaBean type getter/setter function name
        bool getter_flag = (Cmp(symname,
                                Swig_name_set(getNSpace(),
                                              Swig_name_member(0,
                                                               getClassPrefix(),
                                                               variable_name)))
                            != 0);

        String *getter_setter_name = NewString("");
        if (!getter_flag)
            Printf(getter_setter_name, "set");
        else
            Printf(getter_setter_name, "get");
        Putc(toupper((int) *Char(variable_name)), getter_setter_name);
        Printf(getter_setter_name, "%s", Char(variable_name) + 1);

        Setattr(n, "proxyfuncname", getter_setter_name);
        Setattr(n, "imfuncname", symname);

        proxyClassFunctionHandler(n);
        Delete(getter_setter_name);
    }
#endif

    Delete(c_return_type);
    Delete(f_return_type);
    Delete(cleanup);
    Delete(outarg);
    Delete(overloaded_name);
    DelWrapper(f);
    return SWIG_OK;
}

//---------------------------------------------------------------------------//
// Expose the code to the SWIG main function.
//---------------------------------------------------------------------------//
extern "C" Language *
swig_fortran(void)
{
    return new FORTRAN();
}
