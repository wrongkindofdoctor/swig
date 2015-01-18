/* -----------------------------------------------------------------------------
 * std_vector.i
 * ----------------------------------------------------------------------------- */

%include <std_common.i>

%{
#include <vector>
#include <stdexcept>
%}

namespace std
{
template<class T>
class vector
{
  public:
    typedef size_t size_type;
    typedef T value_type;
    typedef const value_type& const_reference;
  public:
    vector();
    vector(size_type n);
    size_type size() const;
    size_type capacity() const;
    void reserve(size_type n);
    bool empty() const;
    void clear();
    void push_back(const value_type& x);
    T& front();
    T& back();
    void at(size_type i);

    %extend {
void set(size_type i, const value_type& val)
{
    if (i < self->size())
    {
        (*self)[i] = val;
    }
    else
    {
        throw std::out_of_range("vector index out of range");
    }
}
    }
};
}
