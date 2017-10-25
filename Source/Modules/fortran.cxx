#include "swigmod.h"
#include "cparse.h"
#include <ctype.h>

namespace
{
//---------------------------------------------------------------------------//
// GLOBAL DATA
//---------------------------------------------------------------------------//

const char usage[] = "\
Fotran Options (available with -fortran)\n\
     -noproxy    - Expose the low-level functional interface instead\n\
                   of generatingproxy classes\n\
     -final      - Generate 'final' statement to call C++ destructors\n\
     -cppcast    - Enable C++ casting operators (default) \n\
     -nocppcast - Disable C++ casting operators\n\
\n";

//! Maximum line length
const int g_max_line_length = 128;

const char fortran_end_statement[] = "\n";

//---------------------------------------------------------------------------//
// UTILITY FUNCTIONS
//---------------------------------------------------------------------------//

/*!
 * \brief Whether a node is a constructor.
 *
 * Node should be a function
 */
bool node_is_constructor(Node* n)
{
    return (Cmp(Getattr(n, "nodeType"), "constructor") == 0
            || Getattr(n, "handled_as_constructor"));
}

//---------------------------------------------------------------------------//
/*!
 * \brief Whether a node is a constructor.
 *
 * Node should be a function
 */
bool node_is_destructor(Node* n)
{
    return Cmp(Getattr(n, "nodeType"), "destructor") == 0;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Print a comma-joined line of items to the given output.
 */
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

//---------------------------------------------------------------------------//
/*!
 * \brief Return a function wrapper for Fortran code.
 */
Wrapper* NewFortranWrapper()
{
    Wrapper* w = NewWrapper();
    w->end_statement = fortran_end_statement;
    return w;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Get/attach and return a typemap to the given node.
 *
 * If 'ext' is non-null, then after binding/searchinbg, a search will be made
 * for the typemap with the given extension. If that's present, it's used
 * instead of the default typemap. (This allows overriding of e.g. 'tmap:ctype'
 * with 'tmap:ctype:out'.)
 *
 * If 'warning' is WARN_NONE, then if the typemap is not found, the return
 * value will be NULL. Otherwise a mangled typename will be created and saved
 * to attributes (or if attributes is null, then the given node).
 */
String* get_typemap(
        const_String_or_char_ptr  tmname,
        const_String_or_char_ptr  ext,
        Node*                     n,
        int                       warning,
        bool                      attach)
{
    String* result = NULL;

    if (attach)
    {
        // Attach the typemap, or NULL if it's not there
        String* lname = Getattr(n, "lname");
        if (!lname)
            lname = Getattr(n, "name");
        assert(lname);
        result = Swig_typemap_lookup(tmname, n, lname, NULL);
    }
    else
    {
        // Look up a typemap that should already be attached
        String* key = NewStringf("tmap:%s", tmname);
        result = Getattr(n, key);
        Delete(key);
    }

    if (!result && warning != WARN_NONE)
    {
        // Typemap was not found: emit a warning
        SwigType* type = Getattr(n, "type");
        if (!type)
        {
            type = Getattr(n, "name");
        }
        if (!type)
        {
            Swig_print_node(n);
            type = NewString("????");
        }
        Swig_warning(warning,
                     Getfile(n), Getline(n),
                     "No '%s' typemap defined for %s\n", tmname,
                     SwigType_str(type, 0));

        if (attach)
        {
            // Attach a mangled typemap
            String* key = NewStringf("tmap:%s", tmname);
            result = NewStringf("SWIGTYPE%s", SwigType_manglestr(type));
            Setattr(n, key, result);
            Delete(key);
            Delete(result); // Since we're returning a "reference"
        }
    }

    if (ext)
    {
        String* key = NewStringf("tmap:%s:%s", tmname, ext);
        String* suffixed_tm = Getattr(n, key);
        if (suffixed_tm)
        {
            result = suffixed_tm;
        }
        Delete(key);
    }
    return result;
}

//---------------------------------------------------------------------------//
//! Attach and return a typemap to the given node.
String* attach_typemap(const_String_or_char_ptr tmname, Node* n, int warning)
{ return get_typemap(tmname, NULL, n, warning, true); }

//! Attach and return a typemap (with extension) to the given node.
String* attach_typemap(const_String_or_char_ptr tmname,
                       const_String_or_char_ptr ext, Node* n, int warning)
{ return get_typemap(tmname, ext, n, warning, true); }

//! Get and return a typemap to the given node.
String* get_typemap(const_String_or_char_ptr tmname, Node* n, int warning)
{ return get_typemap(tmname, NULL, n, warning, false); }

//! Get and return a typemap (with extension) to the given node.
String* get_typemap(const_String_or_char_ptr tmname,
                       const_String_or_char_ptr ext, Node* n, int warning)
{ return get_typemap(tmname, ext, n, warning, false); }

//---------------------------------------------------------------------------//
} // end anonymous namespace


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
    String* f_params;       //!< Generated enumeration/param types
    String* f_types;       //!< Generated class types
    String* f_interfaces;  //!< Fortran interface declarations to SWIG functions
    String* f_proxy;    //!< Fortran subroutine wrapper functions

    // Temporary mappings
    Hash* d_overloads; //!< Overloaded subroutine -> overload names

    // Current class parameters
    Hash* d_method_overloads; //!< Overloaded subroutine -> overload names

    List* d_enumvalues; //!< List of enumerator values

  public:
    virtual void main(int argc, char *argv[]);
    virtual int top(Node *n);
    virtual int functionWrapper(Node *n);
    virtual int destructorHandler(Node *n);
    virtual int constructorHandler(Node *n);
    virtual int classHandler(Node *n);
    virtual int memberfunctionHandler(Node *n);
    virtual int membervariableHandler(Node *n);
    virtual int staticmemberfunctionHandler(Node *n);
    virtual int staticmembervariableHandler(Node *n);
    virtual int globalvariableHandler(Node *n);
    virtual int importDirective(Node *n);
    virtual int enumDeclaration(Node *n);
    virtual int enumvalueDeclaration(Node *n);

    virtual String *makeParameterName(Node *n, Parm *p, int arg_num,
                                      bool is_setter = false) const;
    virtual void replaceSpecialVariables(String *method, String *tm, Parm *parm);

    FORTRAN()
        : d_module(NULL)
        , d_outpath(NULL)
        , d_use_proxy(true)
        , d_use_final(false)
        , d_enumvalues(NULL)
    {
        /* * */
    }

  private:
    int write_function_interface(Node* n);

    void write_wrapper();
    void write_module();

    bool replace_fclassname(SwigType* type, String* tm);
    void replace_fspecial_impl(SwigType* classnametype, String* tm,
                                   const char* classnamespecialvariable);

    List* emit_proxy_parm(Node* n, ParmList *l, Wrapper *f);
};

//---------------------------------------------------------------------------//
/*!
 * \brief Main function for code generation.
 */
void FORTRAN::main(int argc, char *argv[])
{
    int cppcast = 1;

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
        else if (strcmp(argv[i], "-cppcast") == 0)
        {
            cppcast = 1;
            Swig_mark_arg(i);
        }
        else if (strcmp(argv[i], "-nocppcast") == 0)
        {
            cppcast = 0;
            Swig_mark_arg(i);
        }
        else if ((strcmp(argv[i], "-help") == 0))
        {
            Printv(stdout, usage, NULL);
        }
    }

    /* Enable C++ casting */
    if (cppcast)
    {
        Preprocessor_define("SWIG_CPLUSPLUS_CAST", 0);
    }
    
    /* Set language-specific preprocessing symbol */
    Preprocessor_define("SWIGFORTRAN 1", 0);

    /* Set typemap language (historical) */
    SWIG_typemap_lang("fortran");

    /* Set language-specific configuration file */
    SWIG_config_file("fortran.swg");

    allow_overloading();
    Swig_interface_feature_enable();
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

    // Enums and parameters
    f_params = NewString("");
    Swig_register_filebyname("fparams", f_params);

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

    Printv(out, " ! PARAMETERS\n",
                f_params,
                "\n"
                " ! TYPES\n",
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
 * This is also passed class methods via memberfunctionHandler.
 */
int FORTRAN::functionWrapper(Node *n)
{
    // >>> INITIALIZE

    // Create wrapper name, taking into account overloaded functions
    String* symname  = Getattr(n, "sym:name");
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

    // Create name of Fortran proxy subroutine/function
    String* fname = NULL;
    bool in_constructor = false;
    bool in_destructor = false;
    if (is_wrapping_class())
    {
        if (node_is_constructor(n))
        {
            in_constructor = true;
        }
        else if (node_is_destructor(n))
        {
            in_destructor = true;
        }

        fname = NewStringf("swigf_%s", symname);
        if (is_overloaded)
        {
            Append(fname, Getattr(n, "sym:overname"));
        }
    }
    else
    {
        // Use actual symbolic function name
        fname = Copy(symname);
        if (is_overloaded)
        {
            Append(fname, Getattr(n, "sym:overname"));
        }
    }
    Setattr(n, "wrap:name",  wname);
    Setattr(n, "wrap:fname", fname);

    // A new wrapper function object for the C code, the interface code
    // (Fortran declaration of C function interface), and the Fortran code
    Wrapper* cfunc = NewWrapper();
    Wrapper* imfunc = NewFortranWrapper();
    Wrapper* ffunc = NewFortranWrapper();

    // Separate intermediate block for dummy arguments
    String* imargs = NewString("");
    String* fargs  = NewString("");
    // String for calling the wrapper on the fortran side (the "action")
    String* fcall  = NewString("");

    // Hash of import statements needed for the interface code
    Hash* imimport_hash = NewHash();

    // >>> RETURN TYPE

    // Actual return type of the C++ function
    String* cpp_returntype = Getattr(n, "type");

    // Constructors (which to SWIG is a function that returns a 'new'
    // variable) gets turned into a subroutine with the dummy 'this'
    // parameter that we bind to the result of the 'new' function
    String* c_return_type = attach_typemap("ctype", "out", n, 
                                           WARN_FORTRAN_TYPEMAP_CTYPE_UNDEF);
    String* im_return_type = attach_typemap("imtype", "out", n, 
                                            WARN_FORTRAN_TYPEMAP_IMTYPE_UNDEF);
    String* f_return_type = attach_typemap("ftype", "out", n, 
                                           WARN_FORTRAN_TYPEMAP_FTYPE_UNDEF);

    if (in_constructor)
    {
        // Replace output with void
        Delete(f_return_type);
        f_return_type = NewString("");
    }
    else
    {
        replace_fclassname(cpp_returntype, f_return_type);
    }

    // Check whether the C routine returns a variable
    const bool is_csubroutine = (Cmp(c_return_type, "void") == 0);
    // Check whether the Fortran routine returns a variable
    const bool is_fsubroutine = (Len(f_return_type) == 0);

    const char* im_func_type = (is_csubroutine ? "subroutine" : "function");
    const char* f_func_type  = (is_fsubroutine ? "subroutine" : "function");

    Printv(cfunc->def, "SWIGEXPORT ", c_return_type, " ", wname, "(", NULL);
    Printv(imfunc->def, im_func_type, " ", wname, "(", NULL);
    Printv(ffunc->def,  f_func_type,  " ", fname, "(", NULL);

    if (!is_csubroutine)
    {
        // Add local variables for result
        Wrapper_add_localv(cfunc, "fresult",
                           c_return_type, "fresult", NULL);
        Wrapper_add_localv(ffunc,  "fresult",
                           im_return_type, ":: fresult", NULL);

        // Add dummy variable for intermediate return value
        Printv(imargs, im_return_type, " :: fresult\n", NULL);

        // Call function and set intermediate result
        Printv(fcall, "fresult = ", wname, "(", NULL);
    }
    else
    {
        Printv(fcall, "call ", wname, "(", NULL);
    }

    if (!is_fsubroutine)
    {
        // Add dummy variable for Fortran proxy return
        Printv(fargs, f_return_type, " :: swigf_result\n", NULL);
    }

    // If return type is a fortran class, add import statement
    String* imimport = Swig_typemap_lookup("imimport", n, im_return_type, NULL);
    if (imimport)
    {
        Setattr(imimport_hash, imimport, "1");
    }

    // >>> FUNCTION PARAMETERS/ARGUMENTS

    ParmList* parmlist = Getattr(n, "parms");

    // Emit all of the local variables for holding arguments.
    emit_parameter_variables(parmlist, cfunc);
    Swig_typemap_attach_parms("ctype",  parmlist, cfunc);
    emit_attach_parmmaps(parmlist, cfunc);
    Setattr(n, "wrap:parms", parmlist);

    // Emit local variables in fortran code
    List* proxparmlist = emit_proxy_parm(n, parmlist, ffunc);
    
    if (in_constructor)
    {
        // Prepend "self" to the parameter list (with trailing comma if
        // necessary)
        Printv(ffunc->def, "self", (Len(proxparmlist) > 0 ? ", " : ""), NULL);

        // Add dummy argument to wrapper body
        String* ftype = get_typemap("ftype", n,
                                     WARN_FORTRAN_TYPEMAP_FTYPE_UNDEF);
        this->replace_fclassname(cpp_returntype, ftype);
        Printv(fargs, "   ", ftype, " :: self\n", NULL);
    }

    String* prepend = Getattr(n, "feature:fortranprepend");
    if (prepend)
    {
        Printv(ffunc->code, prepend, NULL);
    }

    // >>> BUILD WRAPPER FUNCTION AND INTERFACE CODE
    const char* prepend_comma = "";
    for (Iterator it = First(proxparmlist); it.item; it = Next(it))
    {
        Parm* p = it.item;

        // >>> C ARGUMENTS

        // Name of the argument in the function call (e.g. farg1)
        String* imname = Getattr(p, "imname");

        // Get the user-provided C type string, and convert it to a SWIG
        // internal representation using Swig_cparse_type . Then convert the
        // type and argument name to a valid C expression using SwigType_str.
        String* tm = get_typemap("ctype", p,
                                 WARN_FORTRAN_TYPEMAP_CTYPE_UNDEF);
        SwigType* parsed = Swig_cparse_type(tm);
        String* carg = SwigType_str(parsed, imname);
        Printv(cfunc->def, prepend_comma, carg, NULL);
        Delete(carg);
        Delete(parsed);

        // >>> C ARGUMENT CONVERSION

        String* tm_in = get_typemap("in", p, WARN_TYPEMAP_IN_UNDEF);
        Replaceall(tm_in, "$input", imname);
        Setattr(p, "emit:input", imname);
        Printv(cfunc->code, tm_in, "\n", NULL);

        // >>> F WRAPPER ARGUMENTS

        // Add parameter name to declaration list
        Printv(imfunc->def, prepend_comma, imname, NULL);

        // Add dummy argument to wrapper body
        String* imtype = get_typemap("imtype", "in", p,
                                     WARN_FORTRAN_TYPEMAP_IMTYPE_UNDEF);
        Printv(imargs, "   ", imtype, " :: ", imname, "\n", NULL);
        Printv(fcall, prepend_comma, imname, NULL);

        // Include import statements if present; needed for actual structs
        // passed into interface code
        String* imimport = Getattr(p, "tmap:imimport");
        if (imimport)
        {
            Setattr(imimport_hash, imimport, "1");
        }
        
        // >>> F PROXY ARGUMENTS

        String* cpptype = Getattr(p, "type");

        // Add parameter name to declaration list
        String* farg = Getattr(p, "fname");
        Printv(ffunc->def, prepend_comma, farg, NULL);

        // Add dummy argument to wrapper body
        String* ftype = get_typemap("ftype", "in", p,
                                    WARN_FORTRAN_TYPEMAP_FTYPE_UNDEF);
        this->replace_fclassname(cpptype, ftype);
        Printv(fargs, "   ", ftype, " :: ", farg, "\n", NULL);

        // >>> F PROXY CONVERSION

        tm_in = get_typemap("fin", p, WARN_TYPEMAP_IN_UNDEF);
        this->replace_fclassname(cpptype, tm_in);
        Replaceall(tm_in, "$input", farg);
        Printv(ffunc->code, tm_in, "\n", NULL);

        // Next iteration
        prepend_comma = ", ";
        p = nextSibling(p);
    }

    // END FUNCTION DEFINITION
    Printv(cfunc->def,  ") {", NULL);
    Printv(imfunc->def, ") &\n"
           "    bind(C, name=\"", wname, "\")", NULL);
    Printv(ffunc->def,  ")", NULL);
    Printv(fcall, ")", NULL);

    // Save fortran function call action
    Setattr(n, "wrap:faction", fcall);

    if (!is_csubroutine)
    {
        Printv(imfunc->def, " &\n     result(fresult)\n", NULL);
    }
    else
    {
        Printv(imfunc->def, "\n", NULL);
    }
    if (!is_fsubroutine)
    {
        Setattr(n, "fname", "swigf_result");
        Printv(ffunc->def, " &\n     result(swigf_result)\n", NULL);
    }
    else
    {
        Printv(ffunc->def, "\n", NULL);
    }

    // Append "using" statements and dummy variables to the interface
    // "definition" (before the code and local variable declarations)
    Printv(imfunc->def, "   use, intrinsic :: ISO_C_BINDING\n", NULL);
    for (Iterator kv = First(imimport_hash); kv.key; kv = Next(kv))
    {
        Printv(imfunc->def, "   import :: ", kv.key, "\n", NULL);
    }
    Chop(imargs);
    Printv(imfunc->def, imargs, NULL);

    // Append dummy variables to the proxy function definition
    Chop(fargs);
    Printv(ffunc->def,
           "   use, intrinsic :: ISO_C_BINDING\n",
           fargs, NULL);

    // >>> ADDITIONAL WRAPPER CODE

    // Insert constraint checking code on C++ code
    Parm* p = parmlist;
    while (p)
    {
        if (String* tm = Getattr(p, "tmap:check"))
        {
            Replaceall(tm, "$input", Getattr(p, "emit:input"));
            Printv(cfunc->code, tm, "\n", NULL);
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

    // Generate code to make the C++ function call
    Swig_director_emit_dynamic_cast(n, cfunc);
    String* actioncode = emit_action(n);

    if (String* code = Swig_typemap_lookup_out(
                    "out", n, Swig_cresult_name(), cfunc, actioncode))
    {
        // Output typemap is defined; emit the function call and result
        // conversion code
        Replaceall(code, "$result", "fresult");
        Replaceall(code, "$owner", (GetFlag(n, "feature:new") ? "1" : "0"));
        Printv(cfunc->code, code, "\n", NULL);
    }
    else
    {
        Swig_warning(WARN_TYPEMAP_OUT_UNDEF, input_file, line_number,
                     "Unable to use return type %s in function %s.\n",
                     SwigType_str(cpp_returntype, 0), Getattr(n, "name"));
    }
    emit_return_variable(n, cpp_returntype, cfunc);

    if (in_constructor)
    {
        Printv(ffunc->code,
               fcall, "\n"
               "if (c_associated(self%swigptr)) call self%release()\n"
               "self%swigptr = fresult\n", //i.e. $result%swigptr = $1
               NULL);
    }
    else if (in_destructor)
    {
        Printv(ffunc->code,
               "if (.not. c_associated(self%swigptr)) return\n",
               fcall, "\n"
               "self%swigptr = C_NULL_PTR\n", //i.e. $result%swigptr = $1
               NULL);
    }
    else
    {
        // Emit code to make the Fortran function call in the proxy code
        Printv(ffunc->code, fcall, "\n", NULL);
        
        // Get the typemap for output argument conversion
        Parm* temp = NewParm(cpp_returntype, Getattr(n, "name"), n);
        Setattr(temp, "lname", "fresult"); // Replaces $1
        String* fbody = attach_typemap("fout", temp, WARN_FORTRAN_TYPEMAP_FOUT_UNDEF);
        Delete(temp);
        
        // Output typemap is defined; emit the function call and result
        // conversion code
        Replaceall(fbody, "$result", "swigf_result");
        Replaceall(fbody, "$owner",
                   (GetFlag(n, "feature:new") ? "1" : "0"));
        replace_fclassname(cpp_returntype, fbody);
        Printv(ffunc->code, fbody, "\n", NULL);

        Delete(fbody);
        Delete(temp);
    }

    // Optional "append" proxy code
    String* append = Getattr(n, "feature:fortranappend");
    if (append)
    {
        Printv(ffunc->code, append, NULL);
    }

    // Output argument output and cleanup code
    Printv(cfunc->code, outarg, NULL);
    Printv(cfunc->code, cleanup, NULL);

    if (!is_csubroutine)
    {
        String* qualified_return = SwigType_rcaststr(c_return_type, "fresult");
        Printf(cfunc->code, "    return %s;\n", qualified_return);
        Delete(qualified_return);
    }

    Printf(cfunc->code, "}\n");
    Printv(imfunc->code, "  end ", im_func_type, NULL);
    Printv(ffunc->code,  "  end ", f_func_type, NULL);

    // Apply Standard SWIG substitutions
    Replaceall(cfunc->code, "$cleanup", cleanup);
    Replaceall(cfunc->code, "$symname", symname);
    Replaceall(cfunc->code, "SWIG_contract_assert(",
               "SWIG_contract_assert($null, ");
    Replaceall(cfunc->code, "$null", (is_csubroutine ? "" : "0"));

    // Apply Standard SWIG substitutions
    Replaceall(ffunc->code, "$symname", symname);

    // Write the C++ function into the wrapper code file
    Wrapper_print(cfunc,  f_wrapper);
    Wrapper_print(imfunc, f_interfaces);
    Wrapper_print(ffunc,  f_proxy);
    DelWrapper(cfunc);
    DelWrapper(imfunc);
    DelWrapper(ffunc);

    Delete(outarg);
    Delete(cleanup);
    Delete(fcall);
    Delete(fargs);
    Delete(imargs);
    Delete(proxparmlist);
    Delete(fname);
    Delete(wname);

    return write_function_interface(n);
}

//---------------------------------------------------------------------------//
/*!
 * \brief Write the interface/alias code for a wrapped function.
 *
 * The functionHandler code should write the actual implementation of the
 * functions. This stuff just goes in the "fpublic" and "ftypes" sections.
 */
int FORTRAN::write_function_interface(Node* n)
{
    String* fname = Getattr(n, "wrap:fname");
    assert(fname);

    // >>> DETERMINED WRAPPER NAME

    // Get modified Fortran member name, defaulting to sym:name
    if (String* varname = Getattr(n, "fortran:variable"))
    {
        String* new_alias;
        if (Getattr(n, "varset") || Getattr(n, "memberset"))
        {
            new_alias = Swig_name_set(getNSpace(), varname);
        }
        else if(Getattr(n, "varget") || Getattr(n, "memberget"))
        {
            new_alias = Swig_name_get(getNSpace(), varname);
        }
        else
        {
            Swig_print_node(n);
            assert(0);
        }
        Setattr(n, "fortran:alias", new_alias);
        Delete(new_alias);
    }

    String* alias = Getattr(n, "fortran:alias");
    if (!alias)
    {
        alias = Getattr(n, "fortran:alias");
    }
    if (!alias)
    {
        alias = Getattr(n, "sym:name");
    }

    // >>> WRITE FUNCTION WRAPPER

    const bool is_overloaded = Getattr(n, "sym:overloaded");
    if (is_wrapping_class())
    {
        String* qualifiers = NewString("");

        if (is_overloaded)
        {
            // Create overloaded aliased name
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

            // Make the procedure private
            Append(qualifiers, ", private");

            // The name we write is the overloaded alias
            alias = overalias;
        }
        if (String* extra_quals = Getattr(n, "fortran:procedure"))
        {
            // Add qualifiers like "static" for static functions
            Printv(qualifiers, ", ", extra_quals, NULL);
        }

        Printv(f_types,
               "  procedure", qualifiers, " :: ", alias, " => ", fname, "\n",
               NULL);
        Delete(qualifiers);
    }
    else 
    {
        // Not a class: make the function public (and alias the name)
        if (is_overloaded)
        {
            // Append this function name to the list of overloaded names for the
            // symbol. 'public' access specification gets added later.
            List* overloads = Getattr(d_overloads, alias);
            if (!overloads)
            {
                overloads = NewList();
                Setattr(d_overloads, alias, overloads);
            }
            Append(overloads, Copy(fname));
        }
        else
        {
            Printv(f_public,
                   " public :: ", alias, "\n",
                   NULL);
        }
    }
    return SWIG_OK;
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
    {
        if (Strstr(name, "::"))
        {
            // Name has qualifiers (probably a static variable setter)
            // so replace it with something simple
            name = NewStringf("value%d", arg_num);
        }
        else
        {
            name = Swig_name_make(p, 0, name, 0, 0);
        }
    }
    else
    {
        // The general function which replaces arguments whose
        // names clash with keywords with (less useful) "argN".
        name = Language::makeParameterName(n, p, arg_num, setter);
    }
    return name;
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

    // Make the class publicly accessible
    Printv(f_public, " public :: ", symname, "\n",
                    NULL);

    // Declare class
    Printv(f_types, " type", NULL);
    if (basename)
    {
        Printv(f_types, ", extends(", basename, ")", NULL);
    }
    if (Abstract)
    {
        // The 'Abstract' global variable is set to 1 if this class is abstract
        Printv(f_types, ", abstract", NULL);
    }
    Printv(f_types, " :: ", symname, "\n", NULL);
    
    // Insert the class data. Only do this if the class has no base classes
    if (!basename)
    {
        Printv(f_types,
               "  ! These should be treated as PROTECTED data\n"
               "  type(C_PTR), public :: swigptr = C_NULL_PTR\n",
               NULL);
    }
    Printv(f_types, " contains\n", NULL);
    
    // Initialize output strings that will be added by 'functionHandler'
    d_method_overloads = NewHash();

    // Emit class members
    Language::classHandler(n);

    // Add assignment operator for smart pointers
    String* spclass = Getattr(n, "feature:smartptr");
    if (spclass)
    {
        // Create overloaded aliased name
        String* alias = NewString("assignment(=)");
        String* fname = NewStringf("swigf_assign_%s",
                                        Getattr(n, "sym:name"));
        String* wrapname = NewStringf("swigc_spcopy_%s",
                                      Getattr(n, "sym:name"));

        // Add self-assignment to method overload list
        assert(!Getattr(d_method_overloads, alias));
        List* overloads = NewList();
        Setattr(d_method_overloads, alias, overloads);
        Append(overloads, fname);

        // Define the method
        Printv(f_types,
               "  procedure, private :: ", fname, "\n",
               NULL);
        
        // Add the proxy code implementation of assignment
        Printv(f_proxy,
           "  subroutine ", fname, "(self, other)\n"
           "   use, intrinsic :: ISO_C_BINDING\n"
           "   class(", symname, "), intent(inout) :: self\n"
           "   type(", symname, "), intent(in) :: other\n"
           "   call self%release()\n"
           "   self%swigptr = ", wrapname, "(other%swigptr)\n"
           "  end subroutine\n",
           NULL);

        // Add interface code
        Printv(f_interfaces,
               "  function ", wrapname, "(farg1) &\n"
               "     bind(C, name=\"", wrapname, "\") &\n"
               "     result(fresult)\n"
               "   use, intrinsic :: ISO_C_BINDING\n"
               "   type(C_PTR) :: fresult\n"
               "   type(C_PTR), value :: farg1\n"
               "  end function\n",
               NULL);

        // Add C code
        Wrapper* cfunc = NewWrapper();
        Printv(cfunc->def, "SWIGEXPORT void* ", wrapname, "(void* farg1) {\n",
               NULL);
        Printv(cfunc->code, spclass, "* arg1 = (", spclass, " *)farg1;\n"
                       ""
                       "    return new ", spclass, "(*arg1);\n"
                       "}\n",
                       NULL);
        Wrapper_print(cfunc, f_wrapper);

        Delete(alias);
        Delete(fname);
        Delete(wrapname);
        DelWrapper(cfunc);
    }

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
    Printv(f_types, " end type\n", NULL);

    Delete(d_method_overloads); d_method_overloads = NULL;

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
    Setattr(n, "fortran:alias", alias);
    
    // NOTE: type not yet assigned at this point
    Language::constructorHandler(n);

    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Handle extra destructor stuff.
 */
int FORTRAN::destructorHandler(Node* n)
{
    Setattr(n, "fortran:alias", "release");
    
    Language::destructorHandler(n);

    // XXX turn final into a feature and change to typemaps
    if (d_use_final)
    {
        // Create 'final' name wrapper
        String* fname = NewStringf("swigf_final_%s", Getattr(n, "sym:name"));
        String* classname = Getattr(getCurrentClass(), "sym:name");

        // Add the 'final' subroutine to the methods
        Printv(f_types, "  final     :: ", fname, "\n",
               NULL);

        // Add the 'final' implementation
        Printv(f_proxy,
           "  subroutine ", fname, "(self)\n"
           "   use, intrinsic :: ISO_C_BINDING\n"
           "   class(", classname, ") :: self\n"
           "   call ", Getattr(n, "wrap:name"), "(self%swigptr)\n"
           "   self%swigptr = C_NULL_PTR\n"
           "  end subroutine\n",
           NULL);

        // Add implementation
        Delete(fname);
    }

    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Process member functions.
 */
int FORTRAN::memberfunctionHandler(Node *n)
{
    // Preserve original member name
    Setattr(n, "fortran:alias", Getattr(n, "sym:name"));
    
    Language::memberfunctionHandler(n);
    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Process member variables.
 */
int FORTRAN::membervariableHandler(Node *n)
{
    // Preserve variable name
    Setattr(n, "fortran:variable", Getattr(n, "sym:name"));

    Language::membervariableHandler(n);
    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Process static member functions.
 */
int FORTRAN::globalvariableHandler(Node *n)
{
    Language::globalvariableHandler(n);
    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Process static member functions.
 */
int FORTRAN::staticmemberfunctionHandler(Node *n)
{
    // Preserve original function name
    Setattr(n, "fortran:alias", Getattr(n, "sym:name"));
    
    // Add 'nopass' procedure qualifier
    Setattr(n, "fortran:procedure", "nopass");
    
    Language::staticmemberfunctionHandler(n);
    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Process static member variables.
 */
int FORTRAN::staticmembervariableHandler(Node *n)
{
#if 0
    // Preserve variable name as Class_n
    String* symname = Getattr(n, "sym:name");
    String* varname = NewStringf("%s_%s", getClassPrefix(), symname);
    Setattr(n, "fortran:variable", varname);
    Delete(varname);
#endif

    // Preserve variable name
    Setattr(n, "fortran:variable", Getattr(n, "sym:name"));

    // Add 'nopass' procedure qualifier for getters and setters
    Setattr(n, "fortran:procedure", "nopass");
    Language::staticmembervariableHandler(n);
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
 * \brief Wrap an enum declaration
 *
 */
int FORTRAN::enumDeclaration(Node *n)
{
    if (ImportMode)
        return SWIG_OK;

    // Symname is not present if the enum is not being wrapped
    // (protected/private)
    // XXX: do we also need to check for 'ignore'?
    String* symname = Getattr(n, "sym:name");

    if (symname)
    {
        // Scope the enum if it's in a class
        String* enum_name = NULL;
        if (Node* classnode = getCurrentClass())
        {
            enum_name = NewStringf("%s_%s", Getattr(classnode, "sym:name"),
                                   symname);
        }
        else
        {
            enum_name = Copy(symname);
        }

        // Print the enumerator with a placeholder so we can use 'kind(ENUM)'
        Printv(f_params, " enum, bind(c)\n",
                        "  enumerator :: ", enum_name, " = -1\n", NULL);

        d_enumvalues = NewList();
        Append(d_enumvalues, enum_name);
        Delete(enum_name);
    }

    // Emit enum items
    Language::enumDeclaration(n);

    if (symname)
    {
        // End enumeration
        Printv(f_params, " end enum\n", NULL);

        // Make the enum class *and* its values public
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
        // Implicit enum value (if no value specified, it's PREVIOUS + 1)
        value = Getattr(n, "enumvalueex");
    }
    assert(name);
    assert(value);

    if (d_enumvalues)
    {
        // Add to the list of enums being built
        Append(d_enumvalues, name);
        // Print the enum to the list
        Printv(f_params, "  enumerator :: ", name, " = ", value, "\n", NULL);
    }
    else
    {
        // Convert anonymous enum to an integer parameter
        Printv(f_params, "  integer(C_INT), parameter :: ", name,
                   " = ", value, "\n", NULL);
    }

    return SWIG_OK;
}

//---------------------------------------------------------------------------//
// HELPER FUNCTIONS
//---------------------------------------------------------------------------//
/*!
 * \brief Substitute special '$fXXXXX' in typemaps.
 *
 * This is currently only used for '$fclassname'
 */
bool FORTRAN::replace_fclassname(SwigType* intype, String *tm)
{
    bool substitution_performed = false;
    SwigType* type = Copy(SwigType_typedef_resolve_all(intype));
    SwigType* strippedtype = SwigType_strip_qualifiers(type);

    if (Strstr(tm, "$fclassname"))
    {
        replace_fspecial_impl(strippedtype, tm, "$fclassname");
        substitution_performed = true;
    }

#if 0
    Printf(stdout, "replace_fclassname (%c): %s => '%s'\n",
           substitution_performed ? 'X' : ' ',
           strippedtype, tm);
#endif

    Delete(strippedtype);
    Delete(type);

    return substitution_performed;
}

//---------------------------------------------------------------------------//

void FORTRAN::replace_fspecial_impl(SwigType *classnametype, String *tm,
                                    const char *classnamespecialvariable)
{
    const_String_or_char_ptr replacementname = NULL;

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

    if (!replacementname)
    {
        // Use raw C pointer if SWIG does not know anything about this type.
        Swig_warning(WARN_FORTRAN_TYPEMAP_FTYPE_UNDEF,
                     input_file, line_number,
                     "No '$fclassname' replacement (wrapped type) "
                     "found for %s\n",
                     SwigType_str(classnametype, 0));

        replacementname = "SwigfUnknownClass";
        String* fragment_name = NewString(replacementname);
        //Setfile(fname, Getfile(n));
        //Setline(fname, Getline(n));
        Swig_fragment_emit(fragment_name);
        Delete(fragment_name);
    }
    Replaceall(tm, classnamespecialvariable, replacementname);
}

//---------------------------------------------------------------------------//

List* FORTRAN::emit_proxy_parm(Node* n, ParmList *parmlist, Wrapper *f)
{
    // Bind wrapper types to parameter arguments
    Swig_typemap_attach_parms("imtype", parmlist, f);
    Swig_typemap_attach_parms("imimport", parmlist, f);
    Swig_typemap_attach_parms("ftype",  parmlist, f);
    
    // Assign parameter names
    Parm* p = parmlist;
    List* proxparmlist = NewList();
    int i = 0;
    while (p)
    {
        while (p && checkAttribute(p, "tmap:in:numinputs", "0"))
        {
            p = Getattr(p, "tmap:in:next");
            ++i;
        }
        if (!p)
        {
            // It's possible that the last argument is ignored
            break;
        }

        // Set fortran intermediate name
        String* lname = Getattr(p, "lname");
        String* imname = NewStringf("f%s", lname);
        Setattr(p, "imname", imname);

        String* farg = this->makeParameterName(n, p, i);
        Setattr(p, "fname", farg);

        // Temporarily set lname to imname so that "fin" typemap will
        // substitute farg1 instead of arg1
        Setattr(p, "lname:saved", lname);
        Setattr(p, "lname", imname);

        Delete(farg);
        Delete(imname);

        // Add to list
        Append(proxparmlist, p);

        // Next iteration
        p = nextSibling(p);
        ++i;
    }

    // Attach proxy input typemap (proxy arg -> farg1 in fortran function)
    Swig_typemap_attach_parms("fin", parmlist, f);

    for (Iterator it = First(proxparmlist); it.item; it = Next(it))
    {
        Parm* p = it.item;

        String* imname = Getattr(p, "lname");
        String* lname  = Getattr(p, "lname:saved");

        // Emit local intermediate parameter in the proxy function
        String* imtype = get_typemap("imtype", p,
                                     WARN_FORTRAN_TYPEMAP_IMTYPE_UNDEF);
        Wrapper_add_localv(f, imname, imtype, "::", imname, NULL);

        // Restore local variable name 
        Setattr(p, "lname", lname);
        Delattr(p, "lname:saved");
    }

    // Return newly allocated list of just proxy parameters
    return proxparmlist;
}

//---------------------------------------------------------------------------//

void FORTRAN::replaceSpecialVariables(String* method, String* tm, Parm* parm)
{
    (void)method;
    SwigType *type = Getattr(parm, "type");
    this->replace_fclassname(type, tm);
}

//---------------------------------------------------------------------------//
// Expose the code to the SWIG main function.
//---------------------------------------------------------------------------//

extern "C" Language *
swig_fortran(void)
{
    return new FORTRAN();
}

