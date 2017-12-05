//---------------------------------*-C++-*-----------------------------------//
/*!
 * \file   SimpleClass.hh
 * \author Seth R Johnson
 * \date   Thu Dec 01 15:07:23 2016
 * \brief  SimpleClass class declaration.
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

#ifndef simple_class_SimpleClass_hh
#define simple_class_SimpleClass_hh

//! Simple public struct
struct BasicStruct
{
    int val;
};

//! A typeless enumeration
enum MyEnum {
    RED = 0,
    GREEN,
    BLUE,
    BLACK = -1
};

//===========================================================================//
/*!
 * \class SimpleClass
 * \brief Simple test class
 */
//===========================================================================//

class SimpleClass
{
  public:
    typedef int  storage_type;
    typedef int  multiple_type;

  private:
    // >>> DATA

    int d_id;
    storage_type d_storage;

  public:

    //! Constructor
    SimpleClass();

    //! Copy constructor
    SimpleClass(const SimpleClass& rhs);

    //! assignment
    SimpleClass& operator=(const SimpleClass& rhs);

    //! Other constructor
    explicit SimpleClass(double d);

    //! Destructor
    ~SimpleClass();

    //! Set the value
    void set(storage_type val);

    //! Multiply the value by 2
    void double_it();

    //! Access the value
    storage_type get() const;
    
    //! templated function
    template<class T>
    void action(T& val) { val *= 2; }

    //! Access the value, multiplied by some parameter
    storage_type get_multiplied(multiple_type multiple) const;
};
//! Free function
void print_value(const SimpleClass& c);

//! Return by value should be converted to set-by-reference
SimpleClass make_class(SimpleClass::storage_type val);

//! Return by reference
const SimpleClass& get_class();

//! Pass class as a parameter
void set_class_by_copy(SimpleClass c);

//! Get a color name
void print_color(MyEnum color);

//---------------------------------------------------------------------------//
#endif // simple_class_SimpleClass_hh

//---------------------------------------------------------------------------//
// end of simple_class/SimpleClass.hh
//---------------------------------------------------------------------------//
