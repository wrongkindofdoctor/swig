%module samename

#ifdef SWIGFORTRAN
%rename("samename_cls") "samename";
#endif

#if !(defined(SWIGCSHARP) || defined(SWIGJAVA) || defined(SWIGD))
class samename {
 public:
  void do_something(int sameName);
  void do_something_else(int samename_cls);
};
#endif

%{

class samename {
 public:
  void do_something(int) {
    // ...
  }
  void do_something_else(int) {
    // ...
  }
};

%}

