#! /usr/bin/env python

from smoothing import smoothspec

from astropy.io import fits, ascii
import os, glob, sys
import matplotlib.pyplot as plt
import numpy as np
import bisect

def downgrade_Beagle_spectrum(wl, flux, sigma, bin_width):
    """
        wl: input wavelength array, in angstrom
        flux: input flux array (same length as wl)
        sigma: resolution in angstrom
        bin_width: width of the bins (in angstrom). For Nyquist sampling bin_width = FWHM/2 = 2.355 * sigma / 2 = 1.1775 * sigma
    """

    #print "Original wl range: ", wl[0], wl[-1]

    new_wl = np.arange(wl[0], wl[-1], bin_width)   
    new_flux = np.zeros(len(new_wl))

    resolution_regions = list()

    resolution_regions.append({"wl_range":[5.6, 911.], "fwhm":2.0})
    resolution_regions.append({"wl_range":[911, 3540.5], "fwhm":1.0})
    resolution_regions.append({"wl_range":[3540.5, 7351.], "fwhm":2.5})
    resolution_regions.append({"wl_range":[7351., 8750.], "fwhm":3.0})

    for region in resolution_regions:

        wl_range0 = region["wl_range"][0] 
        wl_range1 = region["wl_range"][1]

        wl0 = region["wl_range"][0] - 2.*bin_width
        wl1 = region["wl_range"][1] + 2.*bin_width

        #print ""
        #print "wl_range: ", region["wl_range"]

        if wl_range0 > new_wl[-1] or wl_range1 < new_wl[0]:
            continue


        if wl_range0 < new_wl[0]:
            i0 = 0
        else:
            i0 = bisect.bisect_left(new_wl, wl_range0)

        if wl_range1 > new_wl[-1]:
            i1 = len(new_wl)-1
        else:
            i1 = bisect.bisect_right(new_wl, wl_range1)


        if wl0 < wl[0]:
            il0 = 0
        else:
            il0 = bisect.bisect_left(wl, wl0)

        if wl1 > wl[-1]:
            il1 = len(wl)-1
        else:
            il1 = bisect.bisect_right(wl, wl1)

        #print "wl: ", wl[il0], wl[il1]
        #print "new_wl: ", new_wl[i0], new_wl[i1]

        sigma_models = region["fwhm"] / 2.355

        smoothed = smoothspec(wl[il0:il1+1], flux[il0:il1+1], outwave=new_wl[i0:i1+1], smoothtype="lambda", resolution=sigma, inres=sigma_models)

        new_flux[i0:i1+1] = smoothed

    return new_flux, new_wl

if __name__ == '__main__':

    file_name = "/Users/jchevall/Coding/BEAGLE/files/tests/bc2003_hrs_miles_m52n_kroup_ssp_SHORT.sed"
    file_name = "/Users/jchevall/Coding/BEAGLE/files/tests/bc2003_hrs_miles_m52n_kroup_ssp.sed"

    data = ascii.read(file_name, Reader=ascii.basic.CommentedHeader, header_start=-1)

    wl = data['wl']

    ok = np.where((wl >= 3500) & (wl <= 4500))[0]

    wl = data['wl'][ok]
    flux = data['flux'][ok]


    print "data: ", data

    fig = plt.figure()
    ax = fig.add_subplot(1, 1, 1)

    ax.plot(wl,
       flux,
       lw=1.0,
       color="red"
        )

    wl0 = wl[0] ; wl1 = wl[-1]
    bin_width = 5.0
    rebinned_wl = np.arange(wl0, wl1, bin_width)   

    smoothed = smoothspec(wl, flux, outwave=rebinned_wl, smoothtype="lambda", resolution=5., inres=2.5/2.355)

    ax.plot(rebinned_wl,
       smoothed,
       lw=1.0,
       color="green"
        )

    smoothed, out_wl = downgrade_Beagle_spectrum(wl, flux, sigma=5.0, bin_width=0.5)

    ax.plot(out_wl,
       smoothed,
       lw=1.0,
       color="orange"
        )

    #rebinned_spec = rebin_spec(wl, flux, rebinned_wl)

    #ax.plot(rebinned_wl,
    #   rebinned_spec,
    #   lw=1.0,
    #   color="blue"
    #    )

    plt.show()


