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
     -cppcast    - Enable C++ casting operators (default) \n\
     -nocppcast  - Disable C++ casting operators\n\
     -fext       - Change file extension of generated Fortran files to <ext>\n\
                   (default is f90)\n\
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
 * \brief Print a comma-joined line of items to the given output.
 */
int print_wrapped_list(String* out, Iterator it, int line_length)
{
    const char* prefix = "";
    for (; it.item; it = Next(it))
    {
        line_length += 2 + Len(it.item);
        if (line_length >= g_max_line_length)
        {
            Printv(out, prefix, NULL);
            prefix = "&\n    ";
            line_length = 4 + Len(it.item);
        }
        Printv(out, prefix, it.item, NULL);
        prefix = ", ";
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
 * \brief Whether an expression is a standard base-10 integer compatible with
 * fortran
 *
 * Note that if it has a suffix e.g. `l` or `u`, or a prefix `0` (octal), it's
 * not compatible.
 */
bool is_fortran_integer(String* s)
{
    const char* p = Char(s);

    // Empty string is not an integer
    if (*p == 0)
        return false;

    // If it's a multi-digit number that starts with 0, it's octal, and thus
    // not a simple integer
    if (*p == '0' && *(p+1) != 0)
        return false;

    // See if all numbers are digits
    while (*p != 0)
    {
        if (!isdigit(*p))
            return false;
        ++p;
    }
    return true;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Determine whether to wrap an enum as a value.
 */
bool is_native_enum(Node *n)
{
    String* enum_feature = Getattr(n, "feature:enumerator");
    if (!enum_feature)
    {
        // Determine from enum values
        for (Node* c = firstChild(n); c; c = nextSibling(c))
        {
            if (Getattr(c, "error") || GetFlag(c, "feature:ignore"))
                continue;

            String* enum_value = Getattr(c, "enumvalue");
            if (enum_value && !is_fortran_integer(enum_value))
            {
                return false;
            }
        }
        // No bad values
        return true;
    }
    else if (Strcmp(enum_feature, "0") == 0)
    {
        // User forced it not to be a native enum
        return false;
    }
    else
    {
        // "feature:enumerator" was set as a flag
        return true;
    }
}

//---------------------------------------------------------------------------//
/*!
 * \brief Determine whether to wrap an enum as a value.
 */
bool is_native_parameter(Node *n)
{
    String* param_feature = Getattr(n, "feature:parameter");
    if (!param_feature)
    {
        // No user override given
        String* value = Getattr(n, "value");
        return is_fortran_integer(value);
    }
    else if (Strcmp(param_feature, "0") == 0)
    {
        // Not a native param
        return false;
    }
    else
    {
        // Value specified and isn't "0"
        return true;
    }
}

//---------------------------------------------------------------------------//
/*!
 * \brief Whether an SWIG type can be rendered as TYPE VAR.
 *
 * Some declarations (arrays, function pointers, member function pointers)
 * require the variable to be embedded in the middle of the array and thus
 * require special treatment.
 */
bool needs_typedef(String* s)
{
    String* strprefix = SwigType_prefix(s);
    bool result = (Strstr(strprefix, "p.a(")
                   || Strstr(strprefix, "p.f(")
                   || Strstr(strprefix, "p.m("));
    Delete(strprefix);
    return result;
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
    String* key = NewStringf("tmap:%s", tmname);

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
        result = Getattr(n, key);
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
            type = NewString("UNKNOWN");
        }
        Swig_warning(warning,
                     Getfile(n), Getline(n),
                     "No '%s' typemap defined for %s\n", tmname,
                     SwigType_str(type, 0));

        String* tmap_match_key = NewStringf("tmap:%s:match_type", tmname);
        Setattr(n, tmap_match_key, "SWIGTYPE");
        Delete(tmap_match_key);
    }

    if (ext)
    {
        String* tempkey = NewStringf("tmap:%s:%s", tmname, ext);
        String* suffixed_tm = Getattr(n, tempkey);
        if (suffixed_tm)
        {
            // Replace the output value with the specialization
            result = suffixed_tm;
            // Replace the key with the specialized key
            Delete(key);
            key = tempkey;
            tempkey = NULL;
        }
        Delete(tempkey);
    }

    Delete(key);
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
/*!
 * \brief Get a plain-text type like "int *", convert it to "p.int"
 *
 * This also sets the attribute in the node.
 *
 * This function is (exclusively?) used for the "tmap:ctype" attribute, which
 * the user inputs as a plain-text C declaration but doesn't automatically get
 * converted by the SWIG type system like the "type" attribute does.
 *
 * Caller is responsible for calling Delete on the return value. Will return
 * NULL if the typemap isn't defined.
 */
SwigType* parse_typemap(const_String_or_char_ptr tmname,
                        const_String_or_char_ptr ext, Node* n, int warning)
{
    // Get the typemap, which has the *unparsed and unsimplified* type
    String* raw_tm = get_typemap(tmname, ext, n, warning, true);
    // Convert the plain-text string to a SWIG type
    SwigType* parsed_type = Swig_cparse_type(raw_tm);
    assert(parsed_type);
    // Resolve typedefs in the parsed type
    SwigType* resolved_type = SwigType_typedef_resolve_all(parsed_type);

    // Replace the contents of the original typemap string with the parsed
    // result -- this is a sort of hack for avoiding the 'Setattr(tmname,
    // resolved_type)' where we'd have to recalculate the tmname key again
    Clear(raw_tm);
    Printv(raw_tm, resolved_type, NULL);
    Delete(parsed_type);
    Delete(resolved_type);
    return raw_tm;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Print as a python dict
 */
void print_pydict(Node* n)
{
    assert(n);

    // Print name
    const_String_or_char_ptr name = Getattr(n, "name");
    if (!name)
        name = Getattr(n, "sym:name");
    if (!name)
        name = "UNKNOWN";
    Printf(stdout, "'%s': {\n", name);

    // Print values
    for (Iterator ki = First(n); ki.key != NULL; ki = Next(ki))
    {
        Printf(stdout, " '%s': ", ki.key);
        if (DohIsString(ki.item))
        {
            if (Len(ki.item) > 80 || Strstr(ki.item, "\n"))
            {
                Printf(stdout, "r'''\\\n%s''',\n", ki.item);
            }
            else
            {
                Printf(stdout, "r'%s',\n", ki.item);
            }
        }
        else
        {
            Printf(stdout, "None,\n");
        }
    }
    Printf(stdout, "},\n\n", name);
}

//---------------------------------------------------------------------------//
} // end anonymous namespace


class FORTRAN : public Language
{
  private:
    // >>> OUTPUT FILES

    // Injected into .cxx file
    String* f_begin; //!< Very beginning of output file
    String* f_runtime; //!< SWIG runtime code
    String* f_header; //!< Declarations and inclusions from .i
    String* f_wrapper; //!< C++ Wrapper code
    String* f_init; //!< C++ initalization functions

    // Injected into module file
    String* f_fbegin;       //!< Very beginning of output file
    String* f_fmodule;      //!< Fortran "module" and "use" directives
    String* f_fpublic;      //!< List of public interface functions and mapping
    String* f_fparams;      //!< Generated enumeration/param types
    String* f_ftypes;       //!< Generated class types
    String* f_finterfaces;  //!< Fortran interface declarations to SWIG functions
    String* f_fwrapper;     //!< Fortran subroutine wrapper functions

    // Temporary mappings
    Hash* d_overloads; //!< Overloaded subroutine -> overload names

    // Current class parameters
    Hash* d_method_overloads; //!< Overloaded subroutine -> overload names

    // Inside of the 'enum' definitions
    List* d_enum_public; //!< List of enumerator values

    // >>> CONFIGURE OPTIONS

    String* d_fext; //!< Fortran file extension

  public:
    virtual void main(int argc, char *argv[]);
    virtual int top(Node *n);
    virtual int moduleDirective(Node *n);
    virtual int functionWrapper(Node *n);
    virtual int destructorHandler(Node *n);
    virtual int constructorHandler(Node *n);
    virtual int classHandler(Node *n);
    virtual int memberfunctionHandler(Node *n);
    virtual int membervariableHandler(Node *n);
    virtual int globalvariableHandler(Node *n);
    virtual int staticmemberfunctionHandler(Node *n);
    virtual int staticmembervariableHandler(Node *n);
    virtual int enumDeclaration(Node *n);
    virtual int constantWrapper(Node *n);
    virtual int classforwardDeclaration(Node *n);

    virtual String *makeParameterName(Node *n, Parm *p, int arg_num,
                                      bool is_setter = false) const;
    virtual void replaceSpecialVariables(String *method, String *tm, Parm *parm);

    FORTRAN()
        : d_overloads(NULL)
        , d_method_overloads(NULL)
        , d_enum_public(NULL)
    {
        /* * */
    }

  private:
    void cfuncWrapper(Node* n);
    void imfuncWrapper(Node* n);
    void proxyfuncWrapper(Node* n);
    void write_docstring(Node* n, String* dest);

    void write_wrapper(String* filename);
    void write_module(String* filename);


    String* attach_class_typemap(const_String_or_char_ptr tmname, int warning);

    bool replace_fclassname(SwigType* type, String* tm);
    void replace_fspecial_impl(SwigType* classnametype, String* tm,
                               const char* classnamespecialvariable,
                               bool is_enum);

    // Add lowercase symbol (fortran)
    int add_fsymbol(String *s, Node *n);
    // Make a unique symbolic name
    String* make_unique_symname(Node* n);
    // Whether the current class is a BIND(C) struct
    bool is_basic_struct() const { return d_method_overloads == NULL; }
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

    // Default string extension
    d_fext = NewString("f90");

    // Set command-line options
    for (int i = 1; i < argc; ++i)
    {
        if (strcmp(argv[i], "-cppcast") == 0)
        {
            cppcast = 1;
            Swig_mark_arg(i);
        }
        else if (strcmp(argv[i], "-nocppcast") == 0)
        {
            cppcast = 0;
            Swig_mark_arg(i);
        }
        else if (strcmp(argv[i], "-fext") == 0)
        {
            Swig_mark_arg(i);
            if (argv[i + 1])
            {
                Delete(d_fext);
                d_fext = NewString(argv[i + 1]);
                Swig_mark_arg(i + 1);
                ++i;
            }
            else
            {
                Swig_arg_error();
            }
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
int FORTRAN::top(Node* n)
{
    // Configure output filename using the name of the SWIG input file
    String* foutfilename = NewStringf(
            "%s%s.%s", SWIG_output_directory(), Getattr(n, "name"), d_fext);
    Setattr(n, "fortran:outfile", foutfilename);
    Delete(foutfilename);

    // >>> C++ WRAPPER CODE

    // run time code (beginning of .cxx file)
    f_begin = NewStringEmpty();
    Swig_register_filebyname("begin", f_begin);

    // run time code (beginning of .cxx file)
    f_runtime = NewStringEmpty();
    Swig_register_filebyname("runtime", f_runtime);

    // header code (after run time)
    f_header = NewStringEmpty();
    Swig_register_filebyname("header", f_header);

    // C++ wrapper code (middle of .cxx file)
    f_wrapper = NewStringEmpty();
    Swig_register_filebyname("wrapper", f_wrapper);

    // initialization code (end of .cxx file)
    f_init = NewStringEmpty();
    Swig_register_filebyname("init", f_init);

    // >>> FORTRAN WRAPPER CODE

    // Code before the `module` statement
    f_fbegin = NewStringEmpty();
    Swig_register_filebyname("fbegin", f_fbegin);

    // Start of module:
    f_fmodule = NewStringEmpty();
    Swig_register_filebyname("fmodule", f_fmodule);

    // Public interface functions
    f_fpublic = NewStringEmpty();
    Swig_register_filebyname("fpublic", f_fpublic);

    // Enums and parameters
    f_fparams = NewStringEmpty();
    Swig_register_filebyname("fparams", f_fparams);

    // Fortran classes
    f_ftypes = NewStringEmpty();
    Swig_register_filebyname("ftypes", f_ftypes);

    // Fortran BIND(C) interfavces
    f_finterfaces = NewStringEmpty();
    Swig_register_filebyname("finterfaces", f_finterfaces);

    // Fortran subroutines (proxy code)
    f_fwrapper = NewStringEmpty();
    Swig_register_filebyname("fwrapper", f_fwrapper);

    // Tweak substitution code
    Swig_name_register("wrapper", "swigc_%f");
    Swig_name_register("set", "set_%n%v");
    Swig_name_register("get", "get_%n%v");

    d_overloads = NewHash();

    // Declare scopes: fortran types and forward-declared types
    this->symbolAddScope("fortran");
    this->symbolAddScope("fortran_fwd");

    // Emit all other wrapper code
    Language::top(n);

    // Write C++ wrapper file
    write_wrapper(Getattr(n, "outfile"));

    // Write fortran module file
    write_module(Getattr(n, "fortran:outfile"));

    // Clean up files and other data
    Delete(d_overloads);
    Delete(f_fwrapper);
    Delete(f_finterfaces);
    Delete(f_ftypes);
    Delete(f_fpublic);
    Delete(f_fmodule);
    Delete(f_init);
    Delete(f_wrapper);
    Delete(f_header);
    Delete(f_runtime);
    Delete(f_fbegin);
    Delete(f_begin);

    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Write C++ wrapper code
 */
void FORTRAN::write_wrapper(String* filename)
{
    // Open file
    File* out = NewFile(filename, "w", SWIG_output_files());
    if (!out)
    {
        FileErrorDisplay(filename);
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
void FORTRAN::write_module(String* filename)
{
    // Open file
    File* out = NewFile(filename, "w", SWIG_output_files());
    if (!out)
    {
        FileErrorDisplay(filename);
        SWIG_exit(EXIT_FAILURE);
    }

    // Write SWIG auto-generation banner
    Swig_banner_target_lang(out, "!");

    // Write module
    Dump(f_fbegin, out);
    Dump(f_fmodule, out);
    Printv(out, " implicit none\n"
                " private\n" , NULL);
    if (Len(f_fpublic) > 0 || Len(d_overloads) > 0)
    {
        Printv(out, "\n ! PUBLIC METHODS AND TYPES\n",
                    f_fpublic, NULL);
    }

    // Write overloads
    for (Iterator kv = First(d_overloads); kv.key; kv = Next(kv))
    {
        const char* prepend_comma = "";
        Printv(out, " public :: ", kv.key, "\n"
                    " interface ", kv.key, "\n"
                    "  module procedure ", NULL);

        // Write overloaded procedure names
        for (Iterator it = First(kv.item); it.item; it = Next(it))
        {
            Printv(out, prepend_comma, it.item, NULL);
            prepend_comma = ", ";
        }
        Printv(out, "\n"
                    " end interface\n", NULL);
    }

    if (Len(f_fparams) > 0)
    {
        Printv(out, "\n ! PARAMETERS\n",
                    f_fparams,
                    NULL);
    }
    if (Len(f_ftypes) > 0)
    {
        Printv(out, "\n ! TYPES\n",
                    f_ftypes,
                    "\n", NULL);
    }
    if (Len(f_finterfaces) > 0)
    {
        Printv(out, "\n ! WRAPPER DECLARATIONS\n"
                    " interface\n",
                    f_finterfaces,
                    " end interface\n"
                    "\n", NULL);
    }
    if (Len(f_fwrapper) > 0)
    {
        Printv(out, "\ncontains\n"
                    " ! FORTRAN PROXY CODE\n",
                    f_fwrapper, NULL);
    }
    Printv(out, "\nend module", "\n",
                NULL);

    // Close file
    Delete(out);
}

//---------------------------------------------------------------------------//
/*!
 * \brief Process a %module
 */
int FORTRAN::moduleDirective(Node *n)
{
    Language::moduleDirective(n);

    // Check for module name uniqueness. If this is the "real" module command
    // then the symbol should be the first instance; but if the code mistakenly
    // has multiple %module directives only the first should be considered.
    String* modname = Getattr(n, "name");
    bool added_symbol = add_fsymbol(modname, n);

    if (ImportMode)
    {
        // This %module directive is inside another module being %imported
        Printv(f_fmodule, " use ", modname, "\n", NULL);
        return SWIG_OK;
    }

    if (!added_symbol)
    {
        return SWIG_NOWRAP;
    }

    // Write documentation if given. Note that it's simply labeled "docstring"
    // and in a daughter node; to unify the doc string processing we just set
    // it as a feature attribute on the module.
    Node* options = Getattr(n, "options");
    if (options)
    {
        String* docstring = Getattr(options, "docstring");
        if (docstring)
        {
            Setattr(n, "feature:docstring", docstring);
            this->write_docstring(n, f_fmodule);
        }
    }

    Printv(f_fmodule, "module ", modname, "\n"
                      " use, intrinsic :: ISO_C_BINDING\n",
                      NULL);

    // Prevent other fortran symbols from clashing

    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Wrap basic functions.
 *
 * This is also passed class methods via memberfunctionHandler.
 */
int FORTRAN::functionWrapper(Node *n)
{
    // >>> SET UP WRAPPER NAME

    String* symname = Getattr(n, "sym:name");

    // Create name for C wrapper function
    String* wname = Swig_name_wrapper(symname);
    // Create name for private fortran wrapper function
    String* fname = NULL;
    if (is_wrapping_class())
    {
        // Create "private" fortran class name
        fname = NewStringf("swigf_%s", symname);
    }
    else
    {
        // Use actual symbolic function name
        fname = Copy(symname);
    }

    // Add suffix if the function is overloaded
    const bool is_overloaded = Getattr(n, "sym:overloaded");
    if (is_overloaded)
    {
        String* overload_ext = Getattr(n, "sym:overname");
        Append(wname, overload_ext);
        Append(fname, overload_ext);
    }

    Setattr(n, "wrap:name",  wname);
    Setattr(n, "wrap:fname", fname);

    if (add_fsymbol(fname, n) == SWIG_NOWRAP)
        return SWIG_NOWRAP;

    // Get modified Fortran member name, defaulting to sym:name
    String* alias = NULL;
    if (String* varname = Getattr(n, "fortran:variable"))
    {
        if (Getattr(n, "varset") || Getattr(n, "memberset"))
        {
            alias = Swig_name_set(getNSpace(), varname);
        }
        else if (Getattr(n, "varget") || Getattr(n, "memberget"))
        {
            alias = Swig_name_get(getNSpace(), varname);
        }
    }
    else
    {
        // Get manually-set alias and make a copy
        alias = Getattr(n, "fortran:alias");
        if (!alias)
        {
            // Alias defaults to symname
            alias = Getattr(n, "sym:name");
        }
        alias = Copy(alias);
    }
    assert(alias);

    // >>> GENERATE WRAPPER CODE

    this->cfuncWrapper(n);
    this->imfuncWrapper(n);
    this->proxyfuncWrapper(n);

    // >>> GENERATE CODE FOR MODULE INTERFACE

    if (is_wrapping_class())
    {
        assert(!is_basic_struct());
        String* qualifiers = NewStringEmpty();

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
            Delete(alias);
            alias = overalias;
        }
        if (String* extra_quals = Getattr(n, "fortran:procedure"))
        {
            // Add qualifiers like "static" for static functions
            Printv(qualifiers, ", ", extra_quals, NULL);
        }

        Printv(f_ftypes,
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
            Printv(f_fpublic,
                   " public :: ", alias, "\n",
                   NULL);
        }
    }
    Setattr(n, "fortran:alias", alias);

    Delete(alias);
    Delete(fname);
    Delete(wname);
    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Generate C/C++ wrapping code
 */
void FORTRAN::cfuncWrapper(Node *n)
{
    String* symname = Getattr(n, "sym:name");

    Wrapper* cfunc = NewWrapper();

    // >>> RETURN VALUES

    // Get the SWIG type representation of the C return type, but first the
    // ctype typemap has to be attached
    Swig_typemap_lookup("ctype", n, Getattr(n, "name"), NULL);
    SwigType* c_return_type = parse_typemap("ctype", "out", n,
                                            WARN_FORTRAN_TYPEMAP_CTYPE_UNDEF);
    const bool is_csubroutine = (Strcmp(c_return_type, "void") == 0);

    String* c_return_str = NULL;
    if (needs_typedef(c_return_type))
    {
        // For these types (where the name is the middle of the expression
        // rather than at the right side,
        // i.e. void (*func)() instead of int func,
        // we either have to add a new typedef OR wrap the
        // entire function in parens. The former is easier.
        c_return_str = NewStringf("%s_swigrtype", symname);

        String* typedef_str = SwigType_str(c_return_type, c_return_str);
        Printv(cfunc->def, "typedef ", typedef_str, ";\n", NULL);
        Delete(typedef_str);
    }
    else
    {
        // Typical case: convert return type into a regular string
        c_return_str = SwigType_str(c_return_type, NULL);
    }

    Printv(cfunc->def, "SWIGEXPORT ", c_return_str, " ",
           Getattr(n, "wrap:name"), "(", NULL);

    if (!is_csubroutine)
    {
        // Add local variables for result
        Wrapper_add_localv(cfunc, "fresult",
                           c_return_str, "fresult", NULL);
    }

    // >>> FUNCTION PARAMETERS/ARGUMENTS

    // Emit all of the local variables for holding arguments.
    ParmList* parmlist = Getattr(n, "parms");
    emit_parameter_variables(parmlist, cfunc);
    Swig_typemap_attach_parms("ctype",  parmlist, cfunc);
    emit_attach_parmmaps(parmlist, cfunc);
    Setattr(n, "wrap:parms", parmlist);

    // Create a list of parameters wrapped by the intermediate function
    List* cparmlist = NewList();

    const char* prepend_comma = "";
    Parm* p = parmlist;
    while (p)
    {
        if (checkAttribute(p, "tmap:in:numinputs", "0"))
        {
            // Skip this typemap
            p = Getattr(p, "tmap:in:next");
            continue;
        }
        else if (SwigType_isvarargs(Getattr(p, "type")))
        {
            Swig_warning(WARN_LANG_NATIVE_UNIMPL, Getfile(p), Getline(p),
                    "Variable arguments (in function '%s') are not implemented "
                    "in Fortran.\n",
                    SwigType_namestr(Getattr(n, "sym:name")));
        }
        else
        {
            // Name of the argument in the function call (e.g. farg1)
            String* imname = NewStringf("f%s", Getattr(p, "lname"));
            Setattr(p, "imname", imname);
            Append(cparmlist, p);

            // Get the user-provided C type string, and convert it to a SWIG
            // internal representation using Swig_cparse_type . Then convert the
            // type and argument name to a valid C expression using SwigType_str.
            SwigType* parsed_tm = parse_typemap(
                    "ctype", NULL, p, WARN_FORTRAN_TYPEMAP_CTYPE_UNDEF);
            if (!parsed_tm)
            {
                Swig_error(input_file, line_number, "Failed to parse 'ctype' "
                           "typemap for argument %s of %s", 
                           SwigType_str(Getattr(p, "type"), Getattr(p, "name")),
                           SwigType_namestr(symname));
                return;
            }
            String* carg = SwigType_str(parsed_tm, imname);
            Printv(cfunc->def, prepend_comma, carg, NULL);
            Delete(carg);

            // Next iteration
            prepend_comma = ", ";
        }

        // Next iteration
        p = nextSibling(p);
    }

    // Save list of wrapped parms for im declaration and proxy
    Setattr(n, "wrap:cparms", cparmlist);

    // END FUNCTION DEFINITION
    Printv(cfunc->def,  ") {", NULL);

    // >>> ADDITIONAL WRAPPER CODE

    String* cleanup = NewStringEmpty();
    String* outarg = NewStringEmpty();
    
    // Insert input conversion, constraint checking, and cleanup code
    for (Iterator it = First(cparmlist); it.item; it = Next(it))
    {
        Parm* p = it.item;
        if (String* tm = Getattr(p, "tmap:in"))
        {
            this->replace_fclassname(Getattr(p, "type"), tm);
            String* imname = Getattr(p, "imname");
            Replaceall(tm, "$input", imname);
            Setattr(p, "emit:input", imname);
            Printv(cfunc->code, tm, "\n", NULL);
        }
        if (String* tm = Getattr(p, "tmap:check"))
        {
            Replaceall(tm, "$input", Getattr(p, "emit:input"));
            Printv(cfunc->code, tm, "\n", NULL);
        }
        if (String* tm = Getattr(p, "tmap:freearg"))
        {
            Replaceall(tm, "$input", Getattr(p, "emit:input"));
            Printv(cleanup, tm, "\n", NULL);
        }
        if (String* tm = Getattr(p, "tmap:argout"))
        {
            Replaceall(tm, "$result", "fresult");
            Replaceall(tm, "$input", Getattr(p, "emit:input"));
            Printv(outarg, tm, "\n", NULL);
        }
    }

    // Generate code to make the C++ function call
    Swig_director_emit_dynamic_cast(n, cfunc);
    if (Strstr(symname, "assign")) // XXX debug code
    {
        Swig_print_node(n);
    }
    String* actioncode = emit_action(n);

    // Generate code to return the value
    String* cpp_return_type = Getattr(n, "type");
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
                     SwigType_str(cpp_return_type, 0), Getattr(n, "name"));
    }
    emit_return_variable(n, cpp_return_type, cfunc);

    // Output argument output and cleanup code
    Printv(cfunc->code, outarg, NULL);
    Printv(cfunc->code, cleanup, NULL);

    // Return value "resource management", as opposed to the "out" typemap's
    // "value conversion" (not used in any of SWIG codebase as far as I can
    // tell; only mentioned once in manual)
    if (String* ret_code
        = Swig_typemap_lookup("ret", n, Swig_cresult_name(), NULL))
    {
        Chop(ret_code);
        Printv(cfunc->code, ret_code, "\n", NULL);
    }

    if (!is_csubroutine)
    {
        String* qualified_return = SwigType_rcaststr(c_return_str, "fresult");
        Printf(cfunc->code, "    return %s;\n", qualified_return);
        Delete(qualified_return);
    }

    Printf(cfunc->code, "}\n");

    // Update contract assertion macro to include 'return' function
    Replaceall(cfunc->code,
               "SWIG_contract_assert(",
               "SWIG_contract_assert(return $null, ");

    // Apply standard SWIG substitutions
    if (Strstr(cfunc->code, "$"))
    {
        // Cleanup code if a function exits early -- in practice, not used.
        Replaceall(cfunc->code, "$cleanup", cleanup);
        // Function name for error messages
        if (Strstr(cfunc->code, "$decl"))
        {
            // Full function name
            String *decl = Swig_name_decl(n);
            Replaceall(cfunc->code, "$decl", decl);
            Delete(decl);
        }
        
        // Get 'null' return type if specified
        String* null_return_type = Getattr(n, "tmap:ctype:null");
        Replaceall(cfunc->code, "$null",
                   null_return_type ? null_return_type : "0");
    }

    // Write the C++ function into the wrapper code file
    Wrapper_print(cfunc, f_wrapper);

    Delete(cparmlist);
    Delete(outarg);
    Delete(cleanup);
    Delete(c_return_str);
    DelWrapper(cfunc);
}

//---------------------------------------------------------------------------//
/*!
 * \brief Generate Fortran interface code
 *
 * This is the Fortran equivalent of the cfuncWrapper's declaration.
 */
void FORTRAN::imfuncWrapper(Node *n)
{
    // Name of the C wrapper function
    String* wname = Getattr(n, "wrap:name");
    String* cpp_return_type = Getattr(n, "type");

    Wrapper* imfunc = NewFortranWrapper();

    // >>> RETURN VALUES

    // Attach typemap for return value
    String* im_return_str = attach_typemap("imtype", "out", n,
                                           WARN_FORTRAN_TYPEMAP_IMTYPE_UNDEF);

    // Check whether the C routine returns a variable
    const bool is_imsubroutine = (Len(im_return_str) == 0);
    const char* im_func_type = (is_imsubroutine ? "subroutine" : "function");

    Printv(imfunc->def, im_func_type, " ", wname, "(", NULL);

    // Hash of import statements needed for the interface code
    Hash* imimport_hash = NewHash();

    // If return type is a fortran C-bound type, add import statement
    String* imimport = Getattr(n, "tmap:imtype:import");
    if (imimport)
    {
        this->replace_fclassname(cpp_return_type, imimport);
        Setattr(imimport_hash, imimport, "1");
    }

    // >>> FUNCTION PARAMETERS/ARGUMENTS

    ParmList* parmlist = Getattr(n, "parms");
    Swig_typemap_attach_parms("imtype", parmlist, NULL);

    // Get the list of actual parameters used by the C function
    // (these are pointers to values in parmlist, with some elements possibly
    // removed)
    List* cparmlist = Getattr(n, "wrap:cparms");
    assert(cparmlist);

    // Append "using" statements and dummy variables to the interface
    // "definition" (before the code and local variable declarations)
    String* imlocals = NewStringEmpty();

    // >>> BUILD WRAPPER FUNCTION AND INTERFACE CODE
    const char* prepend_comma = "";
    for (Iterator it = First(cparmlist); it.item; it = Next(it))
    {
        Parm* p = it.item;

        // Name of the argument in the function call (e.g. farg1)
        String* imname = Getattr(p, "imname");

        // Add parameter name to declaration list
        Printv(imfunc->def, prepend_comma, imname, NULL);

        // Add dummy argument to wrapper body
        String* imtype = get_typemap("imtype", "in", p,
                                     WARN_FORTRAN_TYPEMAP_IMTYPE_UNDEF);
        this->replace_fclassname(Getattr(p, "type"), imtype);
        Printv(imlocals, "\n   ", imtype, " :: ", imname, NULL);

        // Include import statements if present; needed for actual structs
        // passed into interface code
        String* imimport = Getattr(p, "tmap:imtype:import");
        if (imimport)
        {
            this->replace_fclassname(Getattr(p, "type"), imimport);
            Setattr(imimport_hash, imimport, "1");
        }

        // Next iteration
        prepend_comma = ", ";
    }


    // END FUNCTION DEFINITION
    Printv(imfunc->def, ") &\n"
           "    bind(C, name=\"", wname, "\")", NULL);

    if (!is_imsubroutine)
    {
        // Declare dummy return value if it's a function
        Printv(imfunc->def, " &\n     result(fresult)", NULL);
        this->replace_fclassname(cpp_return_type, im_return_str);
        Printv(imlocals, "\n", im_return_str, " :: fresult", NULL);
    }

    // Write the function local block
    Printv(imfunc->code, "   use, intrinsic :: ISO_C_BINDING", NULL);
    for (Iterator kv = First(imimport_hash); kv.key; kv = Next(kv))
    {
        Printv(imfunc->code, "\n   import :: ", kv.key, NULL);
    }
    Printv(imfunc->code, imlocals, "\n  end ", im_func_type, NULL);

    // Write the C++ function into the wrapper code file
    Wrapper_print(imfunc, f_finterfaces);

    DelWrapper(imfunc);
    Delete(imimport_hash);
}

//---------------------------------------------------------------------------//
/*!
 * \brief Generate Fortran proxy code
 *
 * This is for the native Fortran interaction.
 */
void FORTRAN::proxyfuncWrapper(Node *n)
{
    Wrapper* ffunc = NewFortranWrapper();

    // Write documentation
    this->write_docstring(n, f_fwrapper);

    // >>> FUNCTION RETURN VALUES

    const char* swigf_result_name = "";
    String* fargs = NewStringEmpty();

    String* f_return_str = NULL;
    if (node_is_constructor(n))
    {
        // ftype is overridden by constructor
        swigf_result_name = "self";
        f_return_str = NewStringEmpty();
    }
    if (!f_return_str)
    {
        f_return_str = Getattr(n, "feature:ftype");
        Chop(f_return_str);
    }
    if (!f_return_str)
    {
        f_return_str = attach_typemap("ftype", "out", n,
                                      WARN_FORTRAN_TYPEMAP_FTYPE_UNDEF);
    }
    assert(f_return_str);

    // Return type for the C call
    String* im_return_str = get_typemap("imtype", "out", n, WARN_NONE);

    // Check whether the Fortran proxy routine returns a variable, and whether
    // the actual C function does
    const bool is_fsubroutine = (Len(f_return_str) == 0);
    const bool is_imsubroutine = (Len(im_return_str) == 0);

    // Replace any instance of $fclassname in return type
    String* cpp_return_type = Getattr(n, "type");
    this->replace_fclassname(cpp_return_type, f_return_str);
    this->replace_fclassname(cpp_return_type, im_return_str);

    // String for calling the im wrapper on the fortran side (the "action")
    String* fcall  = NewStringEmpty();

    if (!is_imsubroutine)
    {
        Wrapper_add_localv(ffunc,  "fresult",
                           im_return_str, ":: fresult", NULL);
        // Call function and set intermediate result
        Printv(fcall, "fresult = ", NULL);
    }
    else
    {
        Printv(fcall, "call ", NULL);
    }
    Printv(fcall, Getattr(n, "wrap:name"), "(", NULL);

    if (!is_fsubroutine)
    {
        // Add dummy variable for Fortran proxy return
        swigf_result_name = "swigf_result";
        Printv(fargs, f_return_str, " :: ", swigf_result_name, "\n", NULL);
    }

    // >>> FUNCTION NAME

    const char* f_func_type  = (is_fsubroutine ? "subroutine" : "function");
    Printv(ffunc->def, f_func_type,  " ", Getattr(n, "wrap:fname"), "(", NULL);

    // >>> FUNCTION PARAMETERS/ARGUMENTS

    // Get the list of actual parameters used by the C function
    // (these are pointers to values in parmlist, with some elements possibly
    // removed)
    List* cparmlist = Getattr(n, "wrap:cparms");
    assert(cparmlist);

    if (node_is_constructor(n))
    {
        // Prepend "self" to the parameter list (with trailing comma if
        // necessary)
        Printv(ffunc->def, "self", (Len(cparmlist) > 0 ? ", " : ""), NULL);

        // Add dummy argument to wrapper body
        String* ftype = attach_typemap("ftype", n,
                                       WARN_FORTRAN_TYPEMAP_FTYPE_UNDEF);
        this->replace_fclassname(cpp_return_type, ftype);
        Printv(fargs, "   ", ftype, " :: self\n", NULL);
    }

    for (Iterator it = First(cparmlist); it.item; it = Next(it))
    {
        Parm* p = it.item;
        // Temporarily set lname to imname so that "fin" typemap will
        // substitute farg1 instead of arg1
        Setattr(p, "lname:saved", Getattr(p, "lname"));
        Setattr(p, "lname", Getattr(p, "imname"));
    }

    // Attach proxy input typemap (proxy arg -> farg1 in fortran function)
    ParmList* parmlist = Getattr(n, "parms");
    Swig_typemap_attach_parms("ftype",    parmlist, ffunc);
    Swig_typemap_attach_parms("fin",      parmlist, ffunc);
    Swig_typemap_attach_parms("findecl",  parmlist, ffunc);
    Swig_typemap_attach_parms("ffreearg", parmlist, ffunc);

    // Restore parameter names
    for (Iterator it = First(cparmlist); it.item; it = Next(it))
    {
        Parm* p = it.item;
        String* imname = Getattr(p, "imname");

        // Emit local intermediate parameter in the proxy function
        String* imtype = get_typemap("imtype", p,
                                     WARN_FORTRAN_TYPEMAP_IMTYPE_UNDEF);
        this->replace_fclassname(Getattr(p, "type"), imtype);
        Wrapper_add_localv(ffunc, imname, imtype, "::", imname, NULL);

        // Restore local variable name
        Setattr(p, "lname", Getattr(p, "lname:saved"));
        Delattr(p, "lname:saved");
    }

    // >>> BUILD WRAPPER FUNCTION AND INTERFACE CODE

    String* prepend = Getattr(n, "feature:fortranprepend");
    if (prepend)
    {
        Chop(prepend);
        Printv(ffunc->code, prepend, "\n", NULL);
    }

    int i = 0;
    const char* prepend_comma = "";
    for (Iterator it = First(cparmlist); it.item; it = Next(it), ++i)
    {
        Parm* p = it.item;
        String* cpptype = Getattr(p, "type");

        // Add parameter name to declaration list
        String* farg = this->makeParameterName(n, p, i);
        Setattr(p, "fname", farg);
        Printv(ffunc->def, prepend_comma, farg, NULL);

        // Add dummy argument to wrapper body
        String* ftype = get_typemap("ftype", "in", p,
                                    WARN_FORTRAN_TYPEMAP_FTYPE_UNDEF);
        this->replace_fclassname(cpptype, ftype);
        Printv(fargs, "   ", ftype, " :: ", farg, "\n", NULL);

        // Add this argument to the intermediate call function
        Printv(fcall, prepend_comma, Getattr(p, "imname"), NULL);

        // >>> F PROXY CONVERSION

        String* fin = get_typemap("fin", p, WARN_TYPEMAP_IN_UNDEF);
        Replaceall(fin, "$input", farg);
        Printv(ffunc->code, fin, "\n", NULL);

        // Add any needed temporary variables
        String* findecl = get_typemap("findecl", p, WARN_NONE);
        if (findecl)
        {
            Chop(findecl);
            Printv(fargs, findecl, "\n", NULL);
        }

        Delete(farg);

        // Next iteration
        prepend_comma = ", ";
    }

    // END FUNCTION DEFINITION
    Printv(ffunc->def,  ")", NULL);
    Printv(fcall, ")", NULL);

    // Save fortran function call action
    Setattr(n, "wrap:faction", fcall);

    if (!is_fsubroutine)
    {
        Setattr(n, "fname", swigf_result_name);
        Printv(ffunc->def, " &\n     result(", swigf_result_name, ")", NULL);
    }

    // Append dummy variables to the proxy function definition
    Chop(fargs);
    Printv(ffunc->def,
           "\n   use, intrinsic :: ISO_C_BINDING\n",
           fargs, NULL);

    // >>> ADDITIONAL WRAPPER CODE

    // Emit code to make the Fortran function call in the proxy code
    Printv(ffunc->code, fcall, "\n", NULL);

    // Get transformations on the output data in the fortran proxy code
    String* fbody = Getattr(n, "feature:fout");
    String* fparm = Getattr(n, "feature:foutdecl");

    if (!fbody)
    {
        // Instead of using a feature (overriding), use a typemap
        if (fparm)
        {
            // Foutdecl *must* have fout
            Swig_warning(WARN_NONE, input_file, line_number,
                         "'feature:foutdecl' is being ignored for %s "
                         "because 'feature:fout' is not defined for it\n",
                         Getattr(n, "name"));
        }

        // Get the typemap for output argument conversion
        Parm* temp = NewParm(cpp_return_type, Getattr(n, "name"), n);
        Setattr(temp, "lname", "fresult"); // Replaces $1
        fbody = attach_typemap("fout", temp,
                               WARN_FORTRAN_TYPEMAP_FOUT_UNDEF);
        fparm = attach_typemap("foutdecl", temp, WARN_NONE);
        Delete(temp);
    }
    else
    {
        // Replace special variables in feature
        Replaceall(fbody, "$1", "fresult");
    }
    Chop(fbody);

    if (fparm)
    {
        Chop(fparm);
        // Write fortran output parameters after dummy argument
        Printv(ffunc->def, "\n", fparm, NULL);
    }

    // Output typemap is defined; emit the function call and result
    // conversion code
    if (Len(fbody) > 0)
    {
        Replaceall(fbody, "$result", swigf_result_name);
        Replaceall(fbody, "$owner", (GetFlag(n, "feature:new") ? "1" : "0"));
        this->replace_fclassname(cpp_return_type, fbody);
        Printv(ffunc->code, fbody, "\n", NULL);
    }

    // Optional "append" proxy code
    String* append = Getattr(n, "feature:fortranappend");
    if (append)
    {
        Chop(append);
        Printv(ffunc->code, append, "\n", NULL);
    }

    // Insert Fortran cleanup code
    String* fcleanup = NewStringEmpty();
    for (Iterator it = First(cparmlist); it.item; it = Next(it), ++i)
    {
        Parm* p = it.item;
        if (String* tm = Getattr(p, "tmap:ffreearg"))
        {
            Chop(tm);
            Replaceall(tm, "$input", Getattr(p, "emit:input"));
            Printv(fcleanup, tm, "\n", NULL);
        }
    }
    if (Len(fcleanup) > 0)
    {
        Printv(ffunc->code, fcleanup, "\n", NULL);
    }

    // Output argument output and cleanup code
    Printv(ffunc->code, "  end ", f_func_type, NULL);

    // Apply standard SWIG substitutions
    Replaceall(ffunc->code, "$symname", Getattr(n, "sym:name"));

    // Write the C++ function into the wrapper code file
    Wrapper_print(ffunc, f_fwrapper);

    DelWrapper(ffunc);
    Delete(fcleanup);
    Delete(fcall);
    Delete(fargs);
}

//---------------------------------------------------------------------------//
/*!
 * \brief Write documentation for the given node to the passed string.
 */
void FORTRAN::write_docstring(Node* n, String* dest)
{
    String* docs = Getattr(n, "feature:docstring");

    if (!docs)
        return;

    List* lines = SplitLines(docs);
    for (Iterator it = First(lines); it.item; it = Next(it))
    {
        // Chop(it.item);
        Printv(dest, "! ", it.item, "\n", NULL);
    }

    Delete(lines);
}

//---------------------------------------------------------------------------//
/*!
 * \brief Create a friendly parameter name
 */
String* FORTRAN::makeParameterName(Node *n, Parm *p,
                                   int arg_num, bool setter) const
{
    String* name = Getattr(p, "name");
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
    // Fortran parameters will all be lowercase
    String* oldname = name;
    name = Swig_string_lower(oldname);
    Delete(oldname);
    oldname = NULL;

    // If the parameter name is in the fortran scope, or in the
    // forward-declared classes, mangle it
    Hash* symtab = this->symbolScopeLookup("fortran");
    Hash* fwdsymtab = this->symbolScopeLookup("fortran_fwd");
    String* origname = name; // save pointer to unmangled name
    while (Getattr(symtab, name) || Getattr(fwdsymtab, name))
    {
        // Rename
        Delete(oldname);
        oldname = name;
        name = NewStringf("%s%d", origname, arg_num++);
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
    bool basic_struct = false;

    if (add_fsymbol(symname, n) == SWIG_NOWRAP)
        return SWIG_NOWRAP;

    if (GetFlag(n, "feature:fortran:bindc"))
    {
        // Instead of adding setters/getters and methods,
        basic_struct = true;
        // Warn because this is still relatively untesteed
        Swig_warning(WARN_LANG_NATIVE_UNIMPL, Getfile(n), Getline(n),
             "C struct binding (class '%s') is still under development\n",
             SwigType_namestr(symname));
    }

    // Process base classes
    List *baselist = Getattr(n, "bases");
    if (baselist && Len(baselist) > 0)
    {
        String* typestr = SwigType_namestr(symname);
        if (basic_struct)
        {
            // Disallow inheritance for BIND(C) types
            Swig_error(input_file, line_number, "Struct '%s' has the 'bindc' "
                       "feature set, so it cannot use inheritance",
                       typestr);
            return SWIG_NOWRAP;
        }
        else if (Len(baselist) > 1)
        {
            // Disallow if multiple base classes
            Swig_warning(WARN_LANG_NATIVE_UNIMPL, Getfile(n), Getline(n),
                         "Multiple inheritance (class '%s') is not currently "
                         "supported in Fortran\n",
                         typestr);
            return SWIG_NOWRAP;
        }
        else
        {
            // Warn even if inheriting from a single class
            Swig_warning(WARN_LANG_NATIVE_UNIMPL, Getfile(n), Getline(n),
                    "Inheritance (class '%s') support is under development and "
                    "limited.\n",
                    typestr);
        }

        Node* base = Getitem(baselist, 0);
        basename = Getattr(base, "sym:name");
    }

    // Make the class publicly accessible
    Printv(f_fpublic, " public :: ", symname, "\n",
                    NULL);

    // Write documentation
    this->write_docstring(n, f_ftypes);

    // Declare class
    Printv(f_ftypes, " type", NULL);
    if (basename)
    {
        Printv(f_ftypes, ", extends(", basename, ")", NULL);
    }
    else if (basic_struct)
    {
        Printv(f_ftypes, ", bind(C)", NULL);
    }
    Printv(f_ftypes, " :: ", symname, "\n", NULL);

    if (!basic_struct)
    {
        if (!basename)
        {
            String* fdata = this->attach_class_typemap("fdata", WARN_NONE);
            if (!fdata)
            {
                Swig_error(input_file, line_number, "Class '%s' has no "
                           "'%s' typemap defined", 
                           SwigType_namestr(symname), "fdata");
                return SWIG_NOWRAP;
            }
            Chop(fdata);
            // Insert the class data if this doesn't inherit from anything
            Printv(f_ftypes,
                   "  ! These should be treated as PROTECTED data\n"
                   "  ", fdata, "\n", NULL);
            Delete(fdata);
        }
        Printv(f_ftypes, " contains\n", NULL);

        // Initialize output strings that will be added by 'functionHandler'.
        d_method_overloads = NewHash();
    }

    assert(basic_struct == this->is_basic_struct());

    // Emit class members
    Language::classHandler(n);

    if (!basic_struct)
    {
        // Write overloads
        for (Iterator kv = First(d_method_overloads); kv.key; kv = Next(kv))
        {
            Printv(f_ftypes, "  generic :: ", kv.key, " => ", NULL);
            // Note: subtract 2 becaues this first line is an exception to
            // prepend_comma, added inside the iterator
            int line_length = 13 + Len(kv.key) + 4 - 2;

            // Write overloaded procedure names
            print_wrapped_list(f_ftypes, First(kv.item), line_length);
            Printv(f_ftypes, "\n", NULL);
        }
    }

    // Close out the type
    Printv(f_ftypes, " end type\n", NULL);

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
        alias = symname;

        // To avoid conflicts with templated functions, modify the
        // constructor's symname
        String* mrename = NewStringf("%s_%s", classname, symname);
        Setattr(n, "sym:name", mrename);
        Delete(mrename);
    }
    Setattr(n, "fortran:alias", alias);

    // Add statement to deallocate if already allocated
    String* fassoc = this->attach_class_typemap("fassociated", WARN_NONE);
    if (!fassoc)
    {
        Swig_error(input_file, line_number, "Class '%s' has no "
                   "'%s' typemap defined", 
                   SwigType_namestr(classname), "fassociated");
        return SWIG_NOWRAP;
    }
    
    String* releasestr = NewStringf("if (%s) call self%%release()\n", fassoc);
    Replaceall(releasestr, "$input", "self");
    if (String* prependstr = Getattr(n, "feature:fortranprepend"))
    {
        Printv(prependstr, "\n", releasestr, NULL);
    }
    else
    {
        Setattr(n, "feature:fortranprepend", releasestr);
    }
    Delete(releasestr);

    // The 'new' C function returns memory marked as MOVE; the constructor
    // method must capture it.
    const char update_flag[] = "self%swigdata%mem = SWIGF_OWN";
    if (String* appendstr = Getattr(n, "feature:fortranappend"))
    {
        Printv(appendstr, "\n", update_flag, NULL);
    }
    else
    {
        Setattr(n, "feature:fortranappend", update_flag);
    }

    // NOTE: return type has not yet been assigned at this point
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

    Node* classnode = getCurrentClass();

    // Add statement to return early if we're not associated
    String* fassoc = this->attach_class_typemap("fassociated", WARN_NONE);
    String* returnstr = NewStringf("if (.not. (%s)) return\n", fassoc);
    Replaceall(returnstr, "$input", "self");
    if (String* prependstr = Getattr(n, "feature:fortranprepend"))
    {
        Printv(prependstr, "\n", returnstr, NULL);
    }
    else
    {
        Setattr(n, "feature:fortranprepend", returnstr);
    }

    // Add statement to clear pointer after releasing
    String* fdis = this->attach_class_typemap("fdisassociate", WARN_NONE);
    if (!fdis)
    {
        Swig_error(input_file, line_number, "Class '%s' has no "
                   "'%s' typemap defined", 
                   SwigType_namestr(Getattr(classnode, "sym:name")),
                   "fdisassociate");
        return SWIG_NOWRAP;
    }
    Replaceall(fdis, "$input", "self");
    
    if (String* appendstr = Getattr(n, "feature:fortranappend"))
    {
        Printv(appendstr, "\n", fdis, NULL);
    }
    else
    {
        Setattr(n, "feature:fortranappend", fdis);
    }

    Language::destructorHandler(n);

    if (Getattr(classnode, "feature:final"))
    {
        // Create 'final' name wrapper
        String* classname = Getattr(classnode, "sym:name");
        String* fname = NewStringf("swigf_final_%s", classname);

        // Add the 'final' subroutine to the methods
        Printv(f_ftypes, "  final :: ", fname, "\n",
               NULL);

        // Add the 'final' implementation
        Printv(f_fwrapper,
           "  subroutine ", fname, "(self)\n"
           "   use, intrinsic :: ISO_C_BINDING\n"
           "   type(", classname, ") :: self\n"
           "   call ", Getattr(n, "sym:name"), "(self%swigdata%ptr)\n"
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
    if (is_basic_struct())
    {
        String* class_symname = Getattr(getCurrentClass(), "sym:name");
        Swig_error(input_file, line_number, "Struct '%s' has the 'bindc' "
                   "feature set, so it cannot have member functions",
                   SwigType_namestr(class_symname));
        return SWIG_NOWRAP;
    }

    // If the function name starts with two underscores, modify it
    String* symname = Getattr(n, "sym:name");
    String* alias = NULL;
    List* overloads = NULL;
    if (Strstr(symname, "__assign__"))
    {
        // This is the assignment operator
        assert(d_method_overloads);

        // Special assignment operator
        alias = NewString("assignment(=)");
        // Add assignment to generics, even if only one instance is created
        overloads = Getattr(d_method_overloads, alias);
        if (!overloads)
        {
            overloads = NewList();
            Setattr(d_method_overloads, alias, overloads);
        }

        // Set return type to void: fortran requires a subroutine but C++
        // usually returns *this;
        Setattr(n, "type", "void");
        Swig_print_node(n);
    }

    if (strncmp(Char(symname), "__", 2) == 0)
    {
        // For now, just delete the leading underscores
        alias = NewString(Char(symname) + 2);
    }
    else
    {
        // Preserve original member name
        alias = Copy(symname);
    }
    Setattr(n, "fortran:alias", alias);

    Language::memberfunctionHandler(n);

    if (overloads)
    {
        // We need to add the newly constructed function name to the list of
        // overloads, *after* the member function handler has passed the node
        // through functionWrapper etc.
        String* fname = Getattr(n, "fortran:alias");
        assert(fname);
        Append(overloads, fname);
    }

    Delete(alias);
    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Process member variables.
 */
int FORTRAN::membervariableHandler(Node *n)
{
    if (is_basic_struct())
    {
        // Write the type for the class member
        String* im_typestr = attach_typemap(
                "imtype", n, WARN_FORTRAN_TYPEMAP_IMTYPE_UNDEF);
        String* symname = Getattr(n, "sym:name");

        if (!im_typestr)
        {
            // In order for the struct's data to correspond to the C-aligned
            // data, an interface type MUST be specified!
            String* class_symname = Getattr(getCurrentClass(), "sym:name");
            Swig_error(input_file, line_number, "Struct '%s' has the 'bindc' "
                       "feature set, but member variable '%s' has no 'imtype' "
                       "defined",
                       SwigType_namestr(class_symname), symname);
            return SWIG_NOWRAP;
        }

        Printv(f_ftypes, "  ", im_typestr, ", public :: ", symname, "\n",
               NULL);
    }
    else
    {
        // Create getter/setter functions, first preserving
        // the original member variable name
        String* alias = Copy(Getattr(n, "sym:name"));
        Setattr(n, "fortran:variable", alias);
        Delete(alias);

        Language::membervariableHandler(n);
    }
    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Process static member functions.
 */
int FORTRAN::globalvariableHandler(Node *n)
{
    if (GetFlag(n, "feature:parameter"))
    {
        this->constantWrapper(n);
    }
    else
    {
        Language::globalvariableHandler(n);
    }
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
    // Preserve variable name
    Setattr(n, "fortran:variable", Getattr(n, "sym:name"));

    // Add 'nopass' procedure qualifier for getters and setters
    Setattr(n, "fortran:procedure", "nopass");
    Language::staticmembervariableHandler(n);
    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Wrap an enum declaration
 */
int FORTRAN::enumDeclaration(Node *n)
{
    if (ImportMode)
        return SWIG_OK;

    String* access = Getattr(n, "access");
    if (access && Strcmp(access, "public") != 0)
    {
        // Not a public enum
        return SWIG_NOWRAP;
    }

    String* enum_name = NULL;
    String* symname = Getattr(n, "sym:name");
    if (!symname)
    {
        // Anonymous enum TYPE:
        // enum {FOO=0, BAR=1};
    }
    else if (Strstr(symname, "$unnamed") != NULL)
    {
        // Anonymous enum VALUE
        // enum {FOO=0, BAR=1} foo;
    }
    else if (Node* classnode = getCurrentClass())
    {
        // Scope the enum since it's in a class
        enum_name = NewStringf("%s_%s", Getattr(classnode, "sym:name"),
                               symname);
        // Save the alias name
        Setattr(n, "fortran:alias", enum_name);
    }
    else
    {
        enum_name = Copy(symname);
    }

    // Make sure the enum name isn't a duplicate
    if (enum_name && (add_fsymbol(enum_name, n) == SWIG_NOWRAP))
        return SWIG_NOWRAP;

    // Determine whether to add enum as a native fortran enumeration. If false,
    // the values are all wrapped as constants.
    if (is_native_enum(n))
    {
        // Create enumerator statement and initialize list of enum values
        d_enum_public = NewList();
        Printv(f_fparams, " enum, bind(c)\n", NULL);
    }

    if (enum_name)
    {
        // Print a placeholder enum value so we can use 'kind(ENUM)'
        Swig_save("enumDeclaration", n, "sym:name", "value", "type", NULL);

        // Type may not be set if this enum is actually a typedef
        if (!Getattr(n, "type"))
        {
            String* type = NewStringf("enum %s", enum_name);
            Setattr(n, "type", type);
            Delete(type);
        }

        // Create placeholder for the enumeration type
        Setattr(n, "sym:name", enum_name);
        Setattr(n, "value", "-1");
        constantWrapper(n);

        Swig_restore(n);
        Delete(enum_name);
    }

    // Emit enum items
    Language::enumDeclaration(n);

    if (d_enum_public)
    {
        // End enumeration
        Printv(f_fparams, " end enum\n", NULL);

        // Make the enum class *and* its values public
        Printv(f_fpublic, " public :: ", NULL);
        print_wrapped_list(f_fpublic, First(d_enum_public), 11);
        Putc('\n', f_fpublic);
        Delete(d_enum_public);
        d_enum_public = NULL;
    }

    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Process constants
 *
 * These include callbacks declared with

     %constant int (*ADD)(int,int) = add;

 * as well as values such as

     %constant int wrapped_const = (1 << 3) | 1;

 * that need to be interpreted by the C compiler.
 *
 * They're also called inside enumvalueDeclaration (either directly or through
 * memberconstantHandler)
 */
int FORTRAN::constantWrapper(Node* n)
{
    String* nodetype = nodeType(n);
    String* symname = Getattr(n, "sym:name");
    String* value = Getattr(n, "rawval");

    if (Strcmp(nodetype, "enumitem") == 0)
    {
        // Make unique enum values for the user
        symname = this->make_unique_symname(n);

        // Set type from the parent enumeration
        String* t = Getattr(parentNode(n), "enumtype");
        Setattr(n, "type", t);

        if (d_enum_public)
        {
            // We are wrapping an enumeration in Fortran. Get the enum value OR
            // the automatically generated value (PREV + 1). Since the
            // name of PREV typically needs updating (since we just created a
            // unique symname), we update the next enum value if appropriate.
            if (!value)
            {
                value = Getattr(n, "enumvalue");
            }
            if (!value)
            {
                value = Getattr(n, "enumvalueex");
            }

            // This is the ONLY place where we can fix the next enum's automatic
            // value if this one has its name changed.
            Node* next = nextSibling(n);
            if (next && !Getattr(next, "enumvalue"))
            {
                String* updated_ex = NewStringf("%s + 1", symname);
                Setattr(next, "enumvalueex", updated_ex);
            }
        }
    }
    else if (Strcmp(nodetype, "enum") == 0)
    {
        // Symbolic name is already unique
    }
    else
    {
        // Not an enum or enumitem
        if (add_fsymbol(symname, n) == SWIG_NOWRAP)
            return SWIG_NOWRAP;
    }

    if (!value)
    {
        // For constants, the given value. For enums etc., the C++ identifier.
        value = Getattr(n, "value");
    }
    assert(value);

    // Get Fortran data type
    String* im_typestr = attach_typemap(
            "imtype", n, WARN_FORTRAN_TYPEMAP_IMTYPE_UNDEF);
    if (!im_typestr)
        return SWIG_NOWRAP;

    if (d_enum_public)
    {
        // We're wrapping a native enumerator: add to the list of enums being
        // built
        Append(d_enum_public, symname);
        // Print the enum to the list
        Printv(f_fparams, "  enumerator :: ", symname, " = ", value, "\n",
               NULL);
    }
    else if (is_native_parameter(n))
    {
        // Search for the KIND embedded in `integer(C_DOUBLE)` so that we can
        // append the fortran specifier. This is kind of a hack, but native
        // parameters should really only be used for the kinds we define in
        // fortypemaps.swg
        const char* start = Char(im_typestr);
        const char* stop  = start + Len(im_typestr);
        for (; start != stop; ++start)
        {
            if (*start == '(')
            {
                ++start;
                break;
            }
        }
        for (; stop != start; --stop)
        {
            if (*stop == ')')
            {
                break;
            }
        }

        if (stop != start)
        {
            // Append fortran type specifier; otherwise e.g. 1.000000001 will
            // be truncated to 1 because fortran will think it's a float
            String* suffix = NewStringWithSize(start, (int)(stop - start));
            Printv(value, "_", suffix, NULL);
            Delete(suffix);
        }

        Printv(f_fparams, " ", im_typestr, ", parameter, public :: ",
               symname, " = ", value, "\n", NULL);
    }
    else
    {
        /*! Add to public fortran code:
         *
         *   IMTYPE, protected, bind(C, name="swigc_SYMNAME") :: SYMNAME
         *
         * Add to wrapper code:
         *
         *   {const_CTYPE = SwigType_add_qualifier(CTYPE, "const")}
         *   {SwigType_str(const_CTYPE, swigc_SYMNAME) = VALUE;}
         */
        Swig_save("constantWrapper", n, "wrap:name", "lname", NULL);

        // SYMNAME -> swigc_SYMNAME
        String* wname = Swig_name_wrapper(symname);
        Setattr(n, "wrap:name",  wname);

        // Set the value to replace $1 with in the 'out' typemap
        Setattr(n, "lname", value);

        // Get conversion to C type from native c++ type, *AFTER* changing
        // lname and wrap:name
        String* cwrap_code = attach_typemap(
                "out", n, WARN_TYPEMAP_OUT_UNDEF);
        if (!cwrap_code)
            return SWIG_NOWRAP;

        if (Strstr(cwrap_code, "\n"))
        {
            // There's a newline in the output code, indicating it's
            // nontrivial.
            Swig_warning(WARN_LANG_NATIVE_UNIMPL,
                         input_file, line_number,
                         "The 'out' typemap for '%s' is too complex "
                         "to wrap as a %%constant variable. This will be "
                         "implemented later\n", symname);

            return SWIG_NOWRAP;
        }

        // Get type of C value
        Swig_typemap_lookup("ctype", n, symname, NULL);
        SwigType* c_return_type = parse_typemap(
                "ctype", "out", n, WARN_FORTRAN_TYPEMAP_CTYPE_UNDEF);
        if (!c_return_type)
            return SWIG_NOWRAP;

        // Add a const to the return type
        SwigType_add_qualifier(c_return_type, "const");
        String* declstring = SwigType_str(c_return_type, wname);

        // Write SWIG code
        Replaceall(cwrap_code, "$result", declstring);
        Printv(f_wrapper, "SWIGEXPORT SWIGEXTERN ", cwrap_code, "\n\n", NULL);

        // Replace fclassname if needed
        this->replace_fclassname(c_return_type, im_typestr);

        // Add bound variable to interfaces
        Printv(f_fparams, " ", im_typestr, ", protected, public, &\n",
               "   bind(C, name=\"", wname, "\") :: ", symname, "\n",
               NULL);

        Swig_restore(n);
        Delete(declstring);
        Delete(wname);
    }

    return SWIG_OK;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Handle a forward declaration of a class.
 *
 * This is necessary for the case:
 *
 *   struct A;
 *   void foo(A a);
 *
 * to allow 'a' to be correctly renamed.
 */
int FORTRAN::classforwardDeclaration(Node *n)
{
    // Add symbolic name to the forward declaration symbol table
    String* symname = Getattr(n, "sym:name");
    if (symname)
    {
        String* lower = Swig_string_lower(symname);

        const char scope[] = "fortran_fwd";
        Node* existing = this->symbolLookup(lower, scope);
        if (!existing)
        {
            this->addSymbol(lower, n, scope);
        }
        Delete(lower);
    }

    return Language::classforwardDeclaration(n);
}

//---------------------------------------------------------------------------//
// HELPER FUNCTIONS
//---------------------------------------------------------------------------//
/*!
 * \brief Attach and return a typemap belonging to the current class.
 *
 * This is used by things like `fdata`.
 */
String* FORTRAN::attach_class_typemap(
        const_String_or_char_ptr tmname,
        int warning)
{
    assert(this->is_wrapping_class());
    String* class_type = this->getClassType();
    Node* class_node = this->getCurrentClass();

    String* temp_name = NewString("temp_class");
    Parm* temp = NewParm(class_type, temp_name, class_node);
    String* result = attach_typemap(tmname, temp, warning);
    Delete(temp_name);
    Delete(temp);

    if (result)
    {
        this->replace_fclassname(class_type, result);
    }

    return result;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Substitute special '$fXXXXX' in typemaps.
 *
 * This is currently only used for '$fclassname'
 */
bool FORTRAN::replace_fclassname(SwigType* intype, String* tm)
{
    assert(intype);
    bool substitution_performed = false;
    SwigType* basetype = SwigType_base(intype);

    if (Strstr(tm, "$fclassname"))
    {
        replace_fspecial_impl(basetype, tm, "$fclassname", false);
        substitution_performed = true;
    }
    if (Strstr(tm, "$fenumname"))
    {
        replace_fspecial_impl(basetype, tm, "$fenumname", true);
        substitution_performed = true;
    }

#if 0
    Printf(stdout, "replace %s (%c): %s => %s => '%s'\n",
           SwigType_isenum(basetype) ? "ENUM " : "CLASS",
           substitution_performed ? 'X' : ' ',
           intype,
           basetype,
           tm);
#endif

    Delete(basetype);

    return substitution_performed;
}

//---------------------------------------------------------------------------//

void FORTRAN::replace_fspecial_impl(SwigType* basetype, String* tm,
                                    const char *classnamespecialvariable,
                                    bool is_enum)
{
    String* replacementname = NULL;
    String* alloc_string = NULL;
    Node* lookup = (is_enum ? enumLookup(basetype) : classLookup(basetype));

    if (lookup)
    {
        // Check first to see if there's a fortran alias on the node
        replacementname = Getattr(lookup, "fortran:alias");
        if (!replacementname)
        {
            // If not, use the symbolic name
            replacementname = Getattr(lookup, "sym:name");
        }
    }

    if (!replacementname)
    {
        // No class/enum type or symname was found:
        // use raw C pointer since  SWIG does not know anything about this
        // type.
        Swig_warning(WARN_FORTRAN_TYPEMAP_FTYPE_UNDEF,
                     input_file, line_number,
                     "No '$fclassname' replacement (wrapped %s) "
                     "found for %s\n",
                     is_enum ? "enum" : "class",
                     SwigType_str(basetype, 0));

        // Emit fragments for the unknown type, and use that type for
        // replacement
        if (is_enum)
        {
            alloc_string = NewString("SwigfUnknownEnum");
        }
        else
        {
            alloc_string = NewString("SwigfUnknownClass");
        }
        Swig_fragment_emit(alloc_string);
        replacementname = alloc_string;
    }
    Replaceall(tm, classnamespecialvariable, replacementname);
    Delete(alloc_string);
}

//---------------------------------------------------------------------------//

void FORTRAN::replaceSpecialVariables(String* method, String* tm, Parm* parm)
{
    (void)method;
    SwigType *type = Getattr(parm, "type");
    this->replace_fclassname(type, tm);
}

//---------------------------------------------------------------------------//
/*!
 * \brief Add lowercase symbol since fortran is case insensitive
 */
int FORTRAN::add_fsymbol(String* s, Node *n)
{
    assert(s);
    const char scope[] = "fortran";
    String* lower = Swig_string_lower(s);
    Node* existing = this->symbolLookup(lower, scope);

    if (existing)
    {
        String* n1 = Getattr(n, "sym:name");
        if (!n1)
        {
            n1 = Getattr(n, "name");
        }
        String* n2 = Getattr(existing, "sym:name");
        if (!n2)
        {
            n2 = Getattr(existing, "name");
        }
        Swig_warning(WARN_FORTRAN_NAME_CONFLICT, input_file, line_number,
                     "Ignoring '%s' due to Fortran name ('%s') conflict "
                     "with '%s'\n",
                     n1, lower, n2);
        Delete(lower);
        return SWIG_NOWRAP;
    }

    int success = this->addSymbol(lower, n, scope);
    assert(success);
    Delete(lower);
    return success;
}

//---------------------------------------------------------------------------//
/*!
 * \brief Make a unique fortran symbol name by appending numbers.
 */
String* FORTRAN::make_unique_symname(Node* n)
{
    String* symname = Getattr(n, "sym:name");

    // Since enum values are in the same namespace as everything else in the
    // module, make sure they're not duplicated with the scope
    Hash* symtab = this->symbolScopeLookup("fortran");
    Hash* fwdsymtab = this->symbolScopeLookup("fortran_fwd");

    // Lower-cased name for scope checking
    String* orig_lower = Swig_string_lower(symname);
    String* lower = orig_lower;

    int i = 0;
    while (Getattr(symtab, lower) || Getattr(fwdsymtab, lower))
    {
        // Duplicate symbol!
        if (i != 0)
            Delete(lower);

        // Check with an extra number
        ++i;
        lower = NewStringf("%s%d", orig_lower, i);
    }
    if (i != 0)
    {
        // Warn that name has changed
        String* newname = NewStringf("%s%d", symname, i);
        Swig_warning(WARN_FORTRAN_NAME_CONFLICT, input_file, line_number,
                     "Renaming duplicate %s '%s' (Fortran name '%s') "
                     " to '%s'\n",
                    nodeType(n), symname, lower, newname);
        symname = newname;
        // Replace symname and decrement reference counter
        Setattr(n, "sym:name", newname);
        Delete(newname);
    }

    // Add lowercase name to symbol table
    Setattr(symtab, lower, n);
    Delete(lower);

    return symname;
}
//---------------------------------------------------------------------------//
// Expose the code to the SWIG main function.
//---------------------------------------------------------------------------//

extern "C" Language *
swig_fortran(void)
{
    return new FORTRAN();
}

