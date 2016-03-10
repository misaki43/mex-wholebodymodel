% note: you can't directly run this script
% from the build directory because the addpathWBMTests
% script is generated at compile time by CMake and
% and place in the build directory

% addpath from the file generated by cmake
addpathWBMTests

% we need to use custom functions because the Matlab Unit Testing
% framework was introduced in Matlab 2013a, and we need to support
% also Matlab 2012x
try
    % if you want to add new tests, just add the name of the script
    % in this list. To make a test fail, just raise an exception,
    % for example by checking a condition with an assert
    WBMTests
catch ME
    disp(getReport(ME,'extended'));
    warning('mex-wholebodymodel matlab tests failed. Exiting matlab.');
    exit(1)
end

% if we arrive at this point all test went well
disp('mex-wholebodymodel tests: all test completed successfully!')
exit(0)
