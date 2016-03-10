
Matlab MEX interface to the wholeBodyModel C++ interface, implemented to be able to create forward dynamics on matlab for prototyping purposes.

## Installation
It is reccomended to install the `mex-wholebodymodel` throught the [`codyco-superbuild`](https://github.com/robotology/codyco-superbuild/).
Once you installed the `codyco-superbuild`, the `mex-wholebodymodel` files should have been installed in
`${CODYCO_SUPERBUILD_ROOT}/build/install/mex` and its subdirectories (for the `mex-wholebodymodel`, this directories are `mexwbi-wrappers` and `mexwbi-utilities`).
To execute scripts that use `mex-wholebodymodel`, make sure that this directories are part of your [MATLAB search path](mathworks.com/help/matlab/ref/path.html).

## Examples 

### Rigid Body Dynamics
An example on how to use mex-wholebodymodel to compute the dynamics quantities of 
a rigid body is available at [examples/rigidBodyDynamics.m](examples/rigidBodyDynamics.m).

## Controllers simulations
In [matlab-src/torqueBalancing_matlab](matlab-src/torqueBalancing_matlab/) the user can find two different
simulations of whole-body controller implemented using the mex-wholebodymodel interface. One uses the Stack of task approach while 
the other is a Joint Space controller. 
For more information please check the relative [README_SoT](matlab-src/torqueBalancing_matlab/StackOfTask_balancing/README) and
[README_Jc](matlab-src/torqueBalancing_matlab/JointSpace_balancing/README)

## Tests
To verify regression in the code when you modify the code, some
regression tests have been implemented in this repository.

### Run tests
Tests use `ctest` infrastructure.
To run the tests on this repository, after you compiled the project, just following the following steps:

- Move (`cd`) to the build directory
- Run the `ctest` command. If your project supports multiples configurations (e.g. Xcode), you also have to specify the configuration with `-C`, thus for example `ctest -C Debug`.

If you want to print out the verbose output of the tests, launch the `ctest` command by adding the `-VV` option.

### Add new tests
To add new tests, just write a script that runs your test and raise and exception
if the test fails (for example using the `assert` command or the [tests/WBAssertEqual.m](tests/wBAAssertEqual.m) function).
Then modify the [tests/WBMTests.m](tests/WBMTests.m) file to call your testing script.

