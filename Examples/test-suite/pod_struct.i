%module pod_struct

%rename(RenamedOtherStruct) OtherStruct;

#ifdef SWIGFORTRAN
// Treat the struct as a native fortran struct rather than as a class with
// getters/setters.
%fortran_bindc_struct(OtherStruct);
%fortran_bindc_struct(SimpleStruct);
%bindc set_val;
%bindc set_ptr;
%bindc get_ptr_arg;
%bindc get_ptr;
%bindc get_val;
%bindc get_cptr;
%bindc get_handle;
#endif


%inline %{

typedef double (*BinaryOp)(double x, double y);

struct Foo;

struct OtherStruct {
    int j;
    int k;
};

struct SimpleStruct {
    int i;
    double d;
    char c;
    BinaryOp funptr;
    void* v;
    const char* s;
    OtherStruct o;
    float p[3];
    int argv[];
    // Foo f // uncommenting will produce an error in Fortran since 'Foo' is a
             // class and not POD
};

#ifdef __cplusplus
void set_ref(const SimpleStruct& s);
void get_ref_arg(SimpleStruct& s);
SimpleStruct& get_ref();
const SimpleStruct& get_cref();

extern "C" {
#endif

void set_val(SimpleStruct s);
void set_ptr(const SimpleStruct* s);
void get_ptr_arg(SimpleStruct* s);
SimpleStruct get_val();
SimpleStruct* get_ptr();
const SimpleStruct* get_cptr();
SimpleStruct** get_handle();

#ifdef __cplusplus
}
#endif
%}
