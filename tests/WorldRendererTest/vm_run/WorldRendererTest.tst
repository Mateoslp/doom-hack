load,
output-file WorldRendererTest.out,
compare-to WorldRendererTest.cmp,
output-list RAM[8000]%D1.6.1 RAM[8001]%D1.6.1 RAM[8002]%D1.6.1 RAM[8003]%D1.6.1 RAM[8004]%D1.6.1 RAM[8005]%D1.6.1 RAM[8006]%D1.6.1 RAM[8007]%D1.6.1 RAM[8008]%D1.6.1 RAM[8009]%D1.6.1 RAM[8010]%D1.6.1 RAM[8011]%D1.6.1;

repeat 26000000 {
  vmstep;
}
output;
