int gcd(int i, int (*f)(int)) {
  return i + f(i);
}
