#!/usr/bin/env python

import argparse
import os
from collections import OrderedDict

import numpy as np
from astropy.io import fits
import sys
from scipy import stats
import math

if __name__ == '__main__':

    parser = argparse.ArgumentParser()

    parser.add_argument(
        '--beagle-file',
        help="Name of the Beagle output file(s).",
        action="store", 
        type=str, 
        nargs="+",
        dest="beagle_file", 
        default=None
    )

    args = parser.parse_args()

    if args.beagle_file is None:
        files = list()
        for file in os.listdir(os.getcwd()):
            if file.endswith('BEAGLE.fits.gz') and os.path.getsize(file) > 0:
                files.append(file)
    else:
        files = args.beagle_file

    for f in files:

        with fits.open(f, mode='update') as cat:
        
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
                slope, intercept, r_value, p_value, std_err = stats.linregress(np.log10(bin_wl), np.log10(flambda_windows))
                uv_slope[i] = slope
                
            cat['GALAXY PROPERTIES'].data['UV_slope'] = uv_slope
                
