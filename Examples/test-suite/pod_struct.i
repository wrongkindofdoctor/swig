%module pod_struct

#ifdef SWIGFORTRAN
// Treat the struct as a native fortran struct rather than as a class with
// getters/setters.
%fortran_bindc_struct(SimpleStruct);
#endif


%inline %{

typedef double (*BinaryOp)(double x, double y);

struct SimpleStruct {
    int i;
    double d;
    char c;
    BinaryOp funptr;
    void* v;
    const char* s;
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
