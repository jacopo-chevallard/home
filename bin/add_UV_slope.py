#!/usr/bin/env python

import argparse
import os
import numpy as np
from astropy.io import fits
from scipy.optimize import curve_fit
from multiprocessing import Pool, cpu_count

def power_law(wavelength, a, b):
    return a * np.power(wavelength, b)

def process_file(f):
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

        # extend wavelength array to include bin boundaries
        binIdx = 0
        wl_ext = []
        for i in range(len(wl)-1):
            while binArr[binIdx,1] < wl[i]:
                if binIdx < len(binArr)-1:
                    binIdx += 1
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
            
            # Interpolate spectrum to extended wavelength range
            spec_ext_flambda = np.interp(wl_ext, wl, spec_flambda)
            
            flambda_windows = np.zeros(10)
            for j in range(10):
                flambda_windows[j] = np.mean(spec_ext_flambda[
                    (wl_ext >= binArr[j,0]) & (wl_ext <= binArr[j,1])
                ])
            
            # Fit power law function in linear space
            popt, _ = curve_fit(power_law, bin_wl, flambda_windows, p0=(1, -2))
            _, b = popt  # extract the exponent
            
            uv_slope[i] = b  # store the exponent for each object
            
        cat['GALAXY PROPERTIES'].data['UV_slope'] = uv_slope
          
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

    parser.add_argument(
        '-np',
        help="Number of parallel executions",
        action="store", 
        type=int, 
        dest="num_cores", 
        default=None
    )

    args = parser.parse_args()

    if args.beagle_file is None:
        files = [file for file in os.listdir(os.getcwd()) 
                 if file.endswith('BEAGLE.fits.gz') and os.path.getsize(file) > 0]
    else:
        files = args.beagle_file

    # Use multiprocessing to process files in parallel
    num_cores = cpu_count() if args.num_cores is None else args.num_cores 
    with Pool(num_cores) as pool:
        pool.map(process_file, files)
