#include "swigmod.h"
#include "cparse.h"
#include <ctype.h>

namespace
{

const char usage[] = "\
Fotran Options (available with -fortran)\n\
     -noproxy    - Expose the low-level functional interface instead\n\
                   of generatingproxy classes\n\
     -final      - Generate 'final' statement to call C++ destructors\n\
\n";

//! Return a const char* with leading whitespace stripped
const char* lstrip(const_String_or_char_ptr s)
{
    const char* trimmed = Char(s);
    while (trimmed && isspace(*trimmed))
    {
        ++trimmed;
    }
    return trimmed;
}

//! Maximum line length
const int g_max_line_length = 128;

//! Print a comma-joined line of items to the given output.
int print_wrapped_line(String* out, Iterator it, int line_length)
{
    const char* prepend_comma = "";
    for (; it.item; it = Next(it))
    {
        line_length += 2 + Len(it.item);
        if (line_length >= g_max_line_length)
        {
            Printv(out, prepend_comma, NULL);
            prepend_comma = "&\n    ";
            line_length = 4;
        }
        Printv(out, prepend_comma, it.item, NULL);
        prepend_comma = ", ";
    }
    return line_length;
}

}

class FORTRAN : public Language
{
  private:
    // >>> ATTRIBUTES AND OPTIONS

    String* d_module; //!< Module name
    String* d_outpath; //!< WRAP.cxx output

    bool d_use_proxy; //!< Whether to generate proxy classes
    bool d_use_final; //!< Whether to use the 'final' keyword for destructors

    // >>> OUTPUT FILES

    // Injected into .cxx file
    String* f_begin; //!< Very beginning of output file
    String* f_runtime; //!< SWIG runtime code
    String* f_header; //!< Declarations and inclusions from .i
    String* f_wrapper; //!< C++ Wrapper code
    String* f_init; //!< C++ initalization functions

    // Injected into module file
    String* f_imports;     //!< Fortran "use" directives generated from %import
    String* f_public;      //!< List of public interface functions and mapping
    String* f_types;       //!< Generated class types
    String* f_interfaces;  //!< Fortran interface declarations to SWIG functions
    String* f_proxy;    //!< Fortran subroutine wrapper functions

    // Temporary mappings
    Hash* d_overloads; //!< Overloaded subroutine -> overload names

    // Current class parameters
    Hash* d_method_overloads; //!< Overloaded subroutine -> overload names
    String* f_methods; //!< Method strings inside the current class
    SwigType* d_classtype; //!< Class type
    bool d_in_constructor; //!< Whether we're being called inside a constructor
    bool d_in_destructor; //!< Whether we're being called inside a constructor

    List* d_enumvalues; //!< List of enumerator values

  public:
    virtual void main(int argc, char *argv[]);
    virtual int top(Node *n);
    virtual int functionWrapper(Node *n);
    virtual int destructorHandler(Node *n);
    virtual int constructorHandler(Node *n);
    virtual int classHandler(Node *n);
    virtual int memberfunctionHandler(Node *n);
    virtual int importDirective(Node *n);
    virtual int insertDirective(Node *n);
    virtual int enumDeclaration(Node *n);
    virtual int enumvalueDeclaration(Node *n);
    virtual int staticmemberfunctionHandler(Node *n);
    virtual int staticmembervariableHandler(Node *n);


    virtual String *makeParameterName(Node *n, Parm *p, int arg_num,
                                      bool is_setter = false) const;
    virtual void replaceSpecialVariables(String *method, String *tm, Parm *parm);

    FORTRAN()
        : d_module(NULL)
        , d_outpath(NULL)
        , d_use_proxy(true)
        , d_use_final(false)
        , f_methods(NULL)
        , d_classtype(NULL)
        , d_in_constructor(false)
        , d_in_destructor(false)
        , d_enumvalues(NULL)
    {
        /* * */
    }

  private:
    void write_wrapper();
    void write_module_interface();
    void write_module();

    void write_proxy_code(Node* n, bool is_subroutine);

    // Helper functions
    String* get_attached_typemap(Node* n, const char* tmname, int warning);
    String* get_typemap(Node* n, const char* tmname, SwigType* type, int
                        warning);
    String* get_typemap_out(Node* n, const char* tmname, int warning);
    String* get_typemap(Node* n, const_String_or_char_ptr tmname,
                        SwigType* type, Node* attributes, int warning,
                        const char* suffix);

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
    allow_overloading();
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

    // Tweak substitution code
    Swig_name_register("wrapper", "swigc_%f");
    Swig_name_register("set", "set_%n%v");
    Swig_name_register("get", "get_%n%v");

    d_overloads = NewHash();

    /* Emit all other wrapper code */
    Language::top(n);

    /* Write fortran module files */
    write_wrapper();
    write_module();

    // Clean up files and other data
    Delete(d_overloads);
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
    Printv(out, "module ", d_module, "\n"
                " use, intrinsic :: ISO_C_BINDING\n",
                f_imports,
                " implicit none\n"
                "\n"
                " ! PUBLIC METHODS AND TYPES\n",
                f_public, NULL);

    // Write overloads
    for (Iterator kv = First(d_overloads); kv.key; kv = Next(kv))
    {
        const char* prepend_comma = "";
        Printv(out, " public :: ", kv.key, "\n"
                    " interface ", kv.key, "\n"
                    "  module procedure :: ", NULL);

        // Write overloaded procedure names
        for (Iterator it = First(kv.item); it.item; it = Next(it))
        {
            Printv(out, prepend_comma, it.item, NULL);
            prepend_comma = ", ";
        }
        Printv(out, "\n"
                    " end interface\n", NULL);
    }

    Printv(out, " ! TYPES\n",
                f_types,
                "\n"
                " ! WRAPPER DECLARATIONS\n"
                " private\n"
                " interface\n",
                f_interfaces,
                " end interface\n"
                "\n"
                "contains\n"
                "  ! FORTRAN PROXY CODE\n",
                f_proxy,
                "end module ", d_module, "\n",
                NULL);

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
    String* wname = Copy(Swig_name_wrapper(symname));
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
        if (is_overloaded)
        {
            Append(imfuncname, Getattr(n, "sym:overname"));
        }
    }
    Setattr(n, "wrap:name", wname);
    Setattr(n, "imfuncname", imfuncname);
    Delete(imfuncname);

    // Update parameter names for static variables
    // Otherwise, argument names will be like "BaseClass::i"
    String* staticName = Getattr(n, "staticmembervariableHandler:sym:name");
    if (staticName && ParmList_len(parmlist))
    {
        assert(ParmList_len(parmlist) == 1);
        Setattr(parmlist, "name", staticName);
    }

    // A new wrapper function object
    Wrapper* f = NewWrapper();

    // Attach the non-standard typemaps to the parameter list.
    Swig_typemap_attach_parms("ctype",  parmlist, f);
    Swig_typemap_attach_parms("imtype", parmlist, f);

    // Get C return type
    String* c_return_type = get_typemap_out(n, "ctype",
                                            WARN_FORTRAN_TYPEMAP_CTYPE_UNDEF);
    Printv(f->def, "SWIGEXPORT ", c_return_type, " ", wname, "(", NULL);

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

    // >>> BUILD WRAPPER FUNCTION AND INTERFACE CODE

    // Fortran interface parameters and wrapper code parameters
    String* params = NewString(
        "   use, intrinsic :: ISO_C_BINDING\n");

    // Set up return value types if it's a function (rather than subroutine)
    if (!is_subroutine)
    {
        // Get Fortran interface return type
        String* f_return_type
            = get_typemap_out(n, "imtype", WARN_FORTRAN_TYPEMAP_IMTYPE_UNDEF);
        Printf(params, "   %s :: fresult\n", f_return_type);
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
        String* arg = NewStringf("f%s", Getattr(p, "lname"));

        // Get the C type
        String* tm = get_attached_typemap(p, "ctype",
                                          WARN_FORTRAN_TYPEMAP_CTYPE_UNDEF);
        Printv(f->def, prepend_comma, tm, " ", arg, NULL);

        // Get typemap for this argument
        tm = get_attached_typemap(p, "in", WARN_TYPEMAP_IN_UNDEF);
        Replaceall(tm, "$input", arg);
        Setattr(p, "emit:input", arg);
        Printv(f->code, tm, "\n", NULL);

        // Add parameter name to declaration list
        Printv(args, prepend_comma, arg, NULL);

        // Add parameter type to the parameters list
        tm = get_attached_typemap(p, "imtype", WARN_FORTRAN_TYPEMAP_IMTYPE_UNDEF);
        Printv(params, "   ", tm, " :: ", arg, "\n", NULL);

        // Next iteration
        prepend_comma = ", ";
        p = nextSibling(p);
    }
    // Done with C function arguments
    Printf(f->def, ") {");

    // Insert constraint checking code
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

    // Insert cleanup code
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

    // Insert argument output code
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

    // Return value if necessary
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
    Delete(cleanup);
    DelWrapper(f);

    // >>> WRITE INTERFACE CODE

    const char* sub_or_func_str = (is_subroutine ? "subroutine" : "function");
    const char* result_str = (is_subroutine ? "\n"
                                            : " &\n     result(fresult)\n");

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
    SwigType* returntype = Getattr(n, "type");

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
        result_str = " &\n     result(fresult)\n";
    }

    // Get strings to append and prepend if needed
    String* prepend = NewString("");
    String* append = NewString("");
    Printv(prepend, fortranprepend(n), NULL);
    Chop(prepend);

    // Set up function call, parameter list, and input arguments
    String* params = NewString(
        "   use, intrinsic :: ISO_C_BINDING\n");
    String* callcmd = NewString("");
    String* args = NewString("");

    const char* arg_prepend_comma = "";
    const char* call_prepend_comma = "";
    if (d_in_constructor)
    {
        Printv(callcmd, wname, "(", NULL);
        Printv(args, "self", NULL);

        String* f_return_type
            = get_typemap(n, "ftype", returntype,
                          WARN_FORTRAN_TYPEMAP_FTYPE_UNDEF);
        substitute_classname(returntype, f_return_type);
        Printv(params, "   ", f_return_type, " :: self\n", NULL);

        arg_prepend_comma = ", ";
    }
    else if (is_subroutine)
    {
        Printv(callcmd, wname, "(", NULL);
    }
    else
    {
        Printv(callcmd, wname, "(", NULL);

        // Get Fortran proxy return type (for constructors, this is
        // repurposed as a dummy argument)
        String* f_return_type
            = get_typemap_out(n, "ftype", WARN_FORTRAN_TYPEMAP_FTYPE_UNDEF);
        substitute_classname(returntype, f_return_type);
        Printv(params, "   ", f_return_type, " :: fresult\n", NULL);
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
        SwigType* param_type = Getattr(p, "type");
        String* argname = this->makeParameterName(n, p, i++);

        // Add parameter name to argument list
        Printv(args, arg_prepend_comma, argname, NULL);

        // Add parameter to function call
        String* fin_tm = get_attached_typemap(
                p, "fin", WARN_FORTRAN_TYPEMAP_FIN_UNDEF);
        substitute_classname(param_type, fin_tm);
        Printv(callcmd, call_prepend_comma, fin_tm, NULL);

        // Add parameter type to the fortran interface parameters list
        String* ftype_tm = get_attached_typemap(
                p, "ftype", WARN_FORTRAN_TYPEMAP_FIN_UNDEF);
        substitute_classname(param_type, ftype_tm);
        Printv(params, "   ", ftype_tm, " :: ", argname, "\n", NULL);
        Delete(argname);

        // Check for insertion code
        if (String* tm = Getattr(p, "tmap:fin:pre"))
        {
            substitute_classname(param_type, tm);
            Chop(tm);
            if (Len(tm) > 0)
            {
                Printv(prepend, "   ", tm, "\n", NULL);
            }
        }
        if (String* tm = Getattr(p, "tmap:fin:post"))
        {
            substitute_classname(param_type, tm);
            Chop(tm);
            if (Len(tm) > 0)
            {
                Printv(append, "   ", tm, "\n", NULL);
            }
        }

        // Next parameter
        arg_prepend_comma = call_prepend_comma = ", ";
        p = Getattr(p, "tmap:fin:next");
    }
    Printv(callcmd, ")", NULL);

    // Get code to append
    Printv(append, fortranappend(n), NULL);
    Chop(append);

    String* body = NULL;
    if (d_in_constructor)
    {
        // Replace body with typemapped constructor
        body = get_typemap(n, "fcreate",
                           d_classtype,
                           WARN_FORTRAN_TYPEMAP_FCREATE_UNDEF);
    }
    else if (d_in_destructor)
    {
        // Replace body with typemapped destructor
        body = get_typemap(n, "frelease",
                           d_classtype,
                           WARN_FORTRAN_TYPEMAP_FRELEASE_UNDEF);
    }
    else
    {
        body = get_typemap(n, "fout",
                           returntype,
                           WARN_FORTRAN_TYPEMAP_FOUT_UNDEF);
    }
    Replaceall(body, "$result", (is_subroutine ? "" : "fresult"));
    Replaceall(body, "$imcall", callcmd);
    Replaceall(body, "$owner", (GetFlag(n, "feature:new")
                                ? ".true." : ".false."));
    Chop(body);

    // If there's any extra code, make sure it ends with a newline
    if (*Char(prepend)) Append(prepend, "\n");
    if (*Char(append))  Append(append, "\n");

    // Write
    Printv(f_proxy,
           "  ", sub_or_func_str, " ", imfuncname, "(", args, ")",
           result_str,
           params,
           prepend,
           "   ", lstrip(body), "\n",
           append,
           "  end ", sub_or_func_str, "\n",
           NULL);

    // >>> WRITE TYPE OR ALIASES

    const bool is_overloaded = Getattr(n, "sym:overloaded");
    if (is_overloaded && is_wrapping_class())
    {
        // Create overloaded aliased name
        String* alias = Getattr(n, "fortran:membername");
        String* overalias = Copy(alias);
        Append(overalias, Getattr(n, "sym:overname"));

        // Add name to method overload list
        List* overloads = Getattr(d_method_overloads, alias);
        if (!overloads)
        {
            overloads = NewList();
            Setattr(d_method_overloads, alias, overloads);
        }
        Append(overloads, overalias);

        // Print remapping
        Printv(f_methods,
               "  procedure, private :: ", overalias, " => ", imfuncname, "\n",
               NULL);
    }
    else if (is_wrapping_class())
    {
        // Get aliased member function name
        String* alias = Getattr(n, "fortran:membername");

        bool is_static = false;
        if (alias)
        {
            String* new_alias = NULL;
            if (Getattr(n, "staticmembervariableHandler:sym:name"))
            {
                // Member variable, rename the methods to set_ or get_
                is_static = true;

                if (Getattr(n, "varset"))
                {
                    new_alias = Swig_name_set(getNSpace(), alias);
                }
                else if (Getattr(n, "varget"))
                {
                    new_alias = Swig_name_get(getNSpace(), alias);
                }
                else
                {
                    Swig_print_node(n);
                }
            }
            else if (Getattr(n, "staticmemberfunctionHandler:sym:name"))
            {
                is_static = true;
            }
            else
            {
                String* varname = Getattr(n, "membervariableHandler:sym:name");

                if (varname && Getattr(n, "memberset"))
                {
                    new_alias = Swig_name_set(getNSpace(), varname);
                }
                else if (varname && Getattr(n, "memberget"))
                {
                    new_alias = Swig_name_get(getNSpace(), varname);
                }
                else
                {
                    // Standard function method
                }
            }

            if (new_alias)
            {
                alias = new_alias;
            }

            Printv(f_methods,
                   "  procedure", (is_static ? ", nopass" : ""),
                   " :: ", alias, " => ", imfuncname, "\n",
                   NULL);

            Delete(new_alias);
        }
    }
    else if (is_overloaded)
    {
        // Append this function name to the list of overloaded names for the
        // symbol
        String* symname = Getattr(n, "sym:name");
        List* overloads = Getattr(d_overloads, symname);
        if (!overloads)
        {
            overloads = NewList();
            Setattr(d_overloads, symname, overloads);
        }
        Append(overloads, Copy(imfuncname));
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
    Delete(body);
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
    String* symname = Getattr(n, "sym:name");
    String* basename = NULL;

    if (!addSymbol(symname, n))
        return SWIG_ERROR;

    // Process base classes
    List *baselist = Getattr(n, "bases");
    if (baselist && Len(baselist) > 0)
    {
        Swig_warning(WARN_LANG_NATIVE_UNIMPL, Getfile(n), Getline(n),
                "Inheritance (class '%s') support is under development and "
                "limited.\n",
                SwigType_namestr(symname));
        Node* base = Getitem(baselist, 0);
        basename = Getattr(base, "sym:name");
    }
    if (baselist && Len(baselist) > 1)
    {
        Swig_warning(WARN_LANG_NATIVE_UNIMPL, Getfile(n), Getline(n),
                "Multiple inheritance (class '%s') is not supported in Fortran",
                "\n",
                SwigType_namestr(symname));
    }


    // Initialize output strings that will be added by 'functionHandler'
    assert(!f_methods);
    f_methods = NewString("");
    d_method_overloads = NewHash();

    // Write Fortran class header
    d_classtype = Getattr(n, "classtypeobj");

    // Emit class members
    Language::classHandler(n);

    // Make the class publically accessible
    Printv(f_public, " public :: ", symname, "\n",
                    NULL);

    Printv(f_types, " type", NULL);
    if (basename)
    {
        Printv(f_types, ", extends(", basename, ")", NULL);
    }

    if(Abstract)
    {
        Printv(f_types, ", abstract", NULL);
    }

    Printv(f_types, " :: ", symname, "\n", NULL);

    // Insert the class data. Only do this if the class has no base classes
    if (!basename)
    {
           Printv(f_types, "  ", lstrip(get_typemap(n, "fdata", d_classtype,
                                    WARN_FORTRAN_TYPEMAP_FDATA_UNDEF)),
           NULL);
    }
    Printv(f_types, " contains\n",
           f_methods, NULL);

    // Write overloads
    for (Iterator kv = First(d_method_overloads); kv.key; kv = Next(kv))
    {
        Printv(f_types, "  generic :: ", kv.key, " => ", NULL);
        // Note: subtract 2 becaues this first line is an exception to
        // prepend_comma, added inside the iterator
        int line_length = 13 + Len(kv.key) + 4 - 2;

        // Write overloaded procedure names
        print_wrapped_line(f_types, First(kv.item), line_length);
        Printv(f_types, "\n", NULL);
    }

    // Close out the type
    Printv(f_types, " end type\n",
                    NULL);

    Delete(d_method_overloads);
    Delete(f_methods); f_methods = NULL;
    d_classtype = NULL;

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
        Printv(f_methods, "  final     :: ", imfuncname, "\n",
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
/*!
 * \brief Process an '%import' directive.
 *
 * Besides importing typedefs, this should add a "use MODULENAME" line inside
 * the "module" block of the proxy code (before the "contains" line).
 */
int FORTRAN::importDirective(Node *n)
{
    String* modname = Getattr(n, "module");
    if (modname)
    {
        // The actual module contents should be the first child
        // of the provided %import node 'n'.
        Node* mod = firstChild(n);
        // Swig_print_node(mod);
        assert(Strcmp(nodeType(mod), "module") == 0);

        // I don't know if the module name could ever be different from the
        // 'module' attribute of the import node, but just in case... ?
        modname = Getattr(mod, "name");
        Printv(f_imports, " use ", modname, "\n", NULL);
    }

    return Language::importDirective(n);
}

//---------------------------------------------------------------------------//
/*!
 * \brief Process an '%insert' directive.
 *
 * This allows us to do custom insetrions into parts of the fortran module.
 */
int FORTRAN::insertDirective(Node *n)
{
    String *code = Getattr(n, "code");
    String *section = Getattr(n, "section");

    if (!ImportMode && d_use_proxy && (Cmp(section, "fortran") == 0))
    {
        Printv(f_proxy, code, NULL);
    }
    else if (!ImportMode && (Cmp(section, "fortranspec") == 0))
    {
        Printv(f_public, code, NULL);
    }
    else
    {
        return Language::insertDirective(n);
    }
    return SWIG_OK;
}


//---------------------------------------------------------------------------//
/*!
 * \brief Wrap an enum declaration
 *
 */
int FORTRAN::enumDeclaration(Node *n)
{
    // Symname is not present if the enum is not being wrapped
    // (protected/private)
    // XXX: do we also need to check for 'ignore'?
    String* symname = Getattr(n, "sym:name");

    if (symname)
    {
        // Print the enumerator with a placeholder so we can use 'kind(ENUM)'
        Printv(f_types, " enum, bind(c)\n",
                        "  enumerator :: ", symname, " = -1\n", NULL);

        d_enumvalues = NewList();
        Append(d_enumvalues, symname);
    }

    // Emit enum items
    Language::enumDeclaration(n);

    if (symname)
    {
        // End enumeration
        Printv(f_types, " end enum\n", NULL);

        // Make the enum values public
        Printv(f_public, " public :: ", NULL);
        print_wrapped_line(f_public, First(d_enumvalues), 11);
        Printv(f_public, "\n", NULL);
        Delete(d_enumvalues);
        d_enumvalues = NULL;
    }

    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Wrap a value in an enum
 *
 * This is called inside enumDeclaration
 */
int FORTRAN::enumvalueDeclaration(Node *n)
{
    Language::enumvalueDeclaration(n);
    String* name = Getattr(n, "sym:name");
    String* value = Getattr(n, "enumvalue");

    if (!value)
    {
        // Implicit enum value (no value specified: PREVIOUS + 1)
        value = Getattr(n, "enumvalueex");
    }

    if (name && value)
    {
        Append(d_enumvalues, name);
        Printv(f_types, "  enumerator :: ", name, " = ", value, "\n", NULL);
    }
    else
    {
        Printv(stderr, "Enum is missing a name or value:", NULL);
        //Swig_print_node(n);
    }

    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Extra things for static member functions
 */
int FORTRAN::staticmemberfunctionHandler(Node *n)
{
    Setattr(n, "fortran:membername", Getattr(n, "sym:name"));
    Language::staticmemberfunctionHandler(n);
    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Extra things for static member variables
 */
int FORTRAN::staticmembervariableHandler(Node *n)
{
    Setattr(n, "fortran:membername", Getattr(n, "sym:name"));
    Language::staticmembervariableHandler(n);
    return SWIG_OK;
}

//---------------------------------------------------------------------------//
// HELPER FUNCTIONS
//---------------------------------------------------------------------------//
/*!
 * Get a typemap that should already be attached.
 *
 * This can be called if 'get_typemap' was applied to the given node already, or
 * e.g. if Swig_typemap_attach_parms was called.
 */
String* FORTRAN::get_attached_typemap(
        Node*        n,
        const char*  tmname,
        int          warning)
{
    return get_typemap(n, tmname, Getattr(n, "type"), NULL, warning, NULL);
}

//---------------------------------------------------------------------------//
/*!
 * Get a typemap from the current node.
 */
String* FORTRAN::get_typemap(
        Node*        n,
        const char*  tmname,
        SwigType*    type,
        int          warning)
{
    assert(n);
    assert(type);
    Hash* attributes = NewHash();
    String* result = get_typemap(n, tmname, type, attributes, warning, NULL);
    Delete(attributes);
    return result;
}

//---------------------------------------------------------------------------//
/*!
 * Get a typemap from a given type, overriding with 'out'.
 */
String* FORTRAN::get_typemap_out(
        Node*        n,
        const char*  tmname,
        int          warning)
{
    assert(n);
    return get_typemap(n, tmname, Getattr(n, "type"), n, warning, "out");
}

//---------------------------------------------------------------------------//
/*!
 * \brief Returns a new string for a typemap that accepts no arguments
 *
 * If 'attributes' is null, we assume the typemap has already been bound.
 * Otherwise we call Swig_typemap_lookup to bind to the given attributes.
 *
 * If 'warning' is WARN_NONE, then if the typemap is not found, the return
 * value will be NULL. Otherwise a mangled typename will be created and saved
 * to attributes (or if attributes is null, then the given node).
 *
 * If 'suffix' is non-null, then after binding, a search will be made for the
 * typemap with the given suffix. If that's present, it's used instead of the
 * default typemap. (This allows overriding of e.g. 'tmap:ctype' with
 * 'tmap:ctype:out'.)
 */
String* FORTRAN::get_typemap(
        Node*                     n,
        const_String_or_char_ptr  tmname,
        SwigType*                 type,
        Node*                     attributes,
        int                       warning,
        const char*               suffix)
{
    String* tm = NULL;
    String* key = NULL;
    if (attributes)
    {
        // Bind the typemap to this node
        Setattr(attributes, "type", type);
        Setfile(attributes, Getfile(n));
        Setline(attributes, Getline(n));
        tm = Swig_typemap_lookup(tmname, attributes, "", 0);
    }
    else
    {
        // Look up an already-attached typemap
        key = NewStringf("tmap:%s", tmname);
        tm = Getattr(n, key);
    }

    if (tm)
    {
        if (suffix)
        {
            // Check for optional override (i.e. tmap:ctype:out)
            if (!key)
            {
                key = NewStringf("tmap:%s:%s", tmname, suffix);
            }
            else
            {
                Printv(key, ":", suffix, NULL);
            }
            String* suffixed_tm = Getattr(n, key);
            if (suffixed_tm)
                tm = suffixed_tm;
        }
    }
    else if (warning != WARN_NONE)
    {
        SwigType *type = Getattr(n, "type");
        tm = NewStringf("SWIGTYPE%s", SwigType_manglestr(type));
        Swig_warning(warning,
                     Getfile(n), Getline(n),
                     "No '%s' typemap defined for %s\n", tmname,
                     SwigType_str(type, 0));
        // Save the mangled typemap
        if (!key)
        {
            key = NewStringf("tmap:%s", tmname);
        }
        Setattr((attributes ? attributes : n), key, tm);
    }
    return tm;
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
// Substitute the '$fclassname' variables with the Fortran proxy class
// wrapper names. Shamelessly stolen from the Java wrapper code.

bool FORTRAN::substitute_classname(SwigType *pt, String *tm)
{
    bool substitution_performed = false;
#if 0
    Printf(stdout, "calling substitute_classname(%s, %s)\n", pt, tm);
#endif

    SwigType *type = Copy(SwigType_typedef_resolve_all(pt));
    SwigType *strippedtype = SwigType_strip_qualifiers(type);

    if (Strstr(tm, "$fclassname"))
    {
        substitute_classname_impl(strippedtype, tm, "$fclassname");
        substitution_performed = true;
    }

#if 0
    Printf(stdout, "substitute_classname (%c): %s => %s\n",
           substitution_performed ? 'X' : ' ',
           pt, strippedtype);
#endif

    Delete(strippedtype);
    Delete(type);

    return substitution_performed;
}

void FORTRAN::substitute_classname_impl(SwigType *classnametype, String *tm,
                                        const char *classnamespecialvariable)
{
    String *replacementname = NULL;

    if (SwigType_isenum(classnametype))
    {
        Node *lookup = enumLookup(classnametype);
        if (lookup)
        {
            replacementname = Getattr(lookup, "sym:name");
        }
    }
    else
    {
        Node* lookup = classLookup(classnametype);
        if (lookup)
        {
            replacementname = Getattr(lookup, "sym:name");
        }
    }

    if (replacementname)
    {
        Replaceall(tm, classnamespecialvariable, replacementname);
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

        Replaceall(tm, classnamespecialvariable, replacementname);
        Delete(replacementname);
    }
}

//---------------------------------------------------------------------------//

void FORTRAN::replaceSpecialVariables(String* method, String* tm, Parm* parm)
{
    (void)method;
    SwigType *type = Getattr(parm, "type");
    this->substitute_classname(type, tm);
}

//---------------------------------------------------------------------------//
// Expose the code to the SWIG main function.
//---------------------------------------------------------------------------//
extern "C" Language *
swig_fortran(void)
{
    return new FORTRAN();
}
