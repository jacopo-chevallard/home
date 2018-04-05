#!/usr/bin/env python

import argparse
import os
from collections import OrderedDict

import numpy as np
from astropy.io import fits
import sys
import linearFitting as lf
import math

if __name__ == '__main__':

    parser = argparse.ArgumentParser()

    parser.add_argument(
        '--beagle-file',
        help="Name of the Beagle file containing the model SEDs for which EWs must be computed.",
        action="store", 
        type=str, 
        dest="beagle_file", 
        required=True
    )

    args = parser.parse_args()

    cat =  fits.open(args.beagle_file, mode='update')
    
    binArr = np.array([[1268.,1284.], \
          [1309.,1316.], \
          [1342.,1371.], \
          [1407.,1515.], \
          [1562.,1583.], \
          [1677.,1740.], \
          [1760.,1833.], \
          [1866.,1890.], \
          [1930.,1950.], \
          [2400.,2580.]])

    bin_wl = np.zeros(10)
    for i in range(10):
        bin_wl[i] = np.mean(binArr[i])
        
    wl = cat['FULL SED WL'].data[0][0]

    #extend wavelength array to include bin boundaries
    binIdx = 0
    wl_ext = []
    for i in range(len(wl)-1):
        while binArr[binIdx,1] < wl[i]:
            if binIdx < len(binArr)-1:
                binIdx = binIdx + 1
            if binIdx == 9:
                break
        wl_ext.append(wl[i])
        if binIdx < len(binArr):
            if wl[i] < binArr[binIdx,0] and wl[i+1] > binArr[binIdx,0]:
                wl_ext.append(binArr[binIdx,0])
            if wl[i] < binArr[binIdx,1] and wl[i+1] > binArr[binIdx,1]:
                wl_ext.append(binArr[binIdx,1])
   

    wl_ext.append(wl[-1])
    wl_ext = np.array(wl_ext)
    
    nObj = len(cat['FULL SED'].data[:,0])
    
    uv_slope = np.zeros(nObj)
    for i in range(nObj):
        spec_flambda = cat['FULL SED'].data[i,:]

        #calculate mean flambda in each window
        #if the wavelengths for the bin edges are not in the wavelength
        #array, first resample to include them
        spec_ext_flambda = np.interp(wl_ext, wl, spec_flambda)
        flambda_windows = np.zeros(10)
        for j in range(10):
            flambda_windows[j] = np.mean(spec_ext_flambda[np.all([wl_ext >= binArr[j,0], wl_ext <= binArr[j,1]],axis=0)])

        #fit straight line to these fluxes to derive the UV slope

        a, b, sa, sb, rchi2, dof=lf.linear_fit(np.log10(bin_wl), np.log10(flambda_windows),silent=True)
        uv_slope[i] = a
        
        
    cat['GALAXY PROPERTIES'].data['UV_slope'] = uv_slope
        
    cat.flush()
    cat.close()

