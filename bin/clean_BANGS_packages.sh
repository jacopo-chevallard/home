#!/bin/bash
display_usage() { 
	echo -e "\nUsage:\n$0 [installation directory of BANGS] \n" 
	} 

# if less than one argument supplied, display usage 
if [  $# -le 0 ]; then 
	display_usage
	exit 1
fi 
 
cd ${1}/include
\rm fits*.mod manipulate_fits.mod metropolis_hastings.mod prosit.mod mcmc*mod affine_invariant.mod nested_sampling.mod lib_checking.mod lib_constants.mod lib_fft.mod lib_functions.mod lib_gnufor.mod lib_histogram.mod lib_integration.mod lib_interpolation.mod lib_io.mod lib_kernels.mod lib_messages.mod lib_random.mod lib_rebin.mod lib_statistics.mod lib_strings.mod 
cd ${1}/lib
\rm libmcfor* libastrofortran*

