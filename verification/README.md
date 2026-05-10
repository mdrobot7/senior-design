# Verification
To setup SVUnit, run ``source setup-svunit.bsh`` in the verification directory. This catches us up to "Installation and Setup" in the [documentation](https://docs.svunit.org/en/latest/).

From here, let's talk about writing a testbench. The testbenches are written in ``/unit_tests``. To make a TB file, cd into ``unit_tests`` then call ``create_unit_test.pl ../../verilog/rtl/<Path to verilog file>``. This will make a TB for you.

When writing tests, your metrics are the following:
```
FAIL_IF(exp)
FAIL_UNLESS(exp)

FAIL_IF_EQUAL(a,b)
FAIL_UNLESS_EQUAL(a,b)

FAIL_IF_STR_EQUAL(a,b)
FAIL_UNLESS_STR_EQUAL(a,b)
```

After writing your tests, you may want to run them! This is done by running ``cf_run_svunit [name_of_unit_test.sv]`` or ``cf_run_svunit_waves [name_of_unit_test.sv]`` (if you want waveforms).
