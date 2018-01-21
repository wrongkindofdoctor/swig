%module pod_struct

%rename(RenamedOtherStruct) OtherStruct;

#ifdef SWIGFORTRAN
// Treat the struct as a native fortran struct rather than as a class with
// getters/setters.
%fortran_bindc_struct(OtherStruct);
%fortran_bindc_struct(SimpleStruct);
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

void set_val(SimpleStruct s);
void set_ptr(const SimpleStruct* s);
void set_ref(const SimpleStruct& s);

void get_ptr_arg(SimpleStruct* s);
void get_ref_arg(SimpleStruct& s);

SimpleStruct get_val();
SimpleStruct* get_ptr();
SimpleStruct& get_ref();

const SimpleStruct* get_cptr();
const SimpleStruct& get_cref();

SimpleStruct** get_handle();
%}
