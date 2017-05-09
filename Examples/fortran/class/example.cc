/* File : example.cxx */

#include "example.hh"

#include <stdexcept>
#define M_PI 3.14159265358979323846

/* Move the shape to a new location */
void Shape::move(double dx, double dy) {
  x += dx;
  y += dy;
}

int Shape::nshapes = 0;

Circle::Circle(double r)
    : radius(r)
{
    if (r < 0)
        throw std::logic_error("Invalid radius");
}

double Circle::area() {
  return M_PI*radius*radius;
}

double Circle::perimeter() {
  return 2*M_PI*radius;
}

double Square::area() {
  return width*width;
}

double Square::perimeter() {
  return 4*width;
}
