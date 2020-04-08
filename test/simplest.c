uint16 simple_function(uint16 A)
{
  uint16 V = A*A;
  if (V<=8)
    return 0;
  return 1;
}

void main()
{
  uint16 V = 14;
  uint16 K = simple_function(V);
  uint16 L = simple_function(V*2);
  K = K + L;
}
