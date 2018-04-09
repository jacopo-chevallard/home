#! /usr/bin/env python

import argparse
import os
from collections import OrderedDict
import json
from astropy.io import fits
import numpy as np
from scipy.interpolate import interp1d


if __name__ == '__main__':

    parser = argparse.ArgumentParser()

    parser.add_argument(
        '--beagle-file',
        help="Name of the Beagle file containing the model SEDs for which EWs must be computed.",
        action="store", 
        type=str, 
        nargs="+",
        dest="beagle_file", 
        required=True
    )

    parser.add_argument(
        '--json-file',
        help="JSON file containing the list of emission lines for which EWs will be computed.",
        action="store", 
        type=str, 
        dest="json_file", 
        required=True
    )


    # Get parsed arguments
    args = parser.parse_args()    

    # Load the list of lines for which we compute the EWs
    with open(args.json_file) as f:
        lines = json.load(f, object_pairs_hook=OrderedDict)
    
    for f in args.beagle_file:

        hdulist = fits.open(f) 
        wl = np.ravel(hdulist['FULL SED WL'].data[0][:])
        n_rows = len(hdulist[1].data.field(1))

        # Create an empty dictionary of numpy array which will containe the EWs
        EWs = OrderedDict()
        integrated_fluxes = OrderedDict()
        for line in lines:
            EWs[line] = np.zeros(n_rows, dtype=np.float32)

        SEDs = hdulist['FULL SED'].data[:,:]

        # Cycle across all the lines for which we compute the EWs
        for key, value in lines.iteritems():

            # Compute the average left continuum
            il0 = np.searchsorted(wl, value["continuum_left"][0]) ; il0 -= 1
            il1 = np.searchsorted(wl, value["continuum_left"][1])
            if il0 == il1:
                il0 -= 1
            flux_left = np.ravel(np.trapz(SEDs[:,il0:il1+1], x=wl[il0:il1+1], axis=1)) / (wl[il1]-wl[il0])
            wl_left = 0.5*(wl[il0]+wl[il1])

            # Compute the average right continuum
            ir0 = np.searchsorted(wl, value["continuum_right"][0]) ; ir0 -= 1
            ir1 = np.searchsorted(wl, value["continuum_right"][1])
            if ir0 == ir1:
                ir0 -= 1
            flux_right = np.ravel(np.trapz(SEDs[:,ir0:ir1+1], x=wl[ir0:ir1+1], axis=1)) / (wl[ir1]-wl[ir0])
            wl_right = 0.5*(wl[ir0]+wl[ir1])

            # Approximate the continuum with a straght line
            grad = (flux_right-flux_left)/(wl_right-wl_left)
            intercept = flux_right - grad*wl_right
        
            #### Compute EW
            i0 = np.searchsorted(wl, value["wl_range"][0]) ; i0 -= 1
            i1 = np.searchsorted(wl, value["wl_range"][1])
            n_wl = i1-i0+1

            # Repeat the wl array along the 0 axis to be able to run the algorithms over all rows at the same time
            wl_repeat = np.repeat(wl[np.newaxis, i0:i1+1], n_rows, axis=0)

            # Interpolate the SED at the edges to have to right integration limits
            SED = np.copy(SEDs[:,i0:i1+1])
            SED[:,0] = SED[:,0] + (SED[:,1]-SED[:,0])/(wl_repeat[:,1]-wl_repeat[:,0]) * (value["wl_range"][0]-wl_repeat[:,0])
            SED[:,-1] = SED[:,-2] + (SED[:,-2]-SED[:,-1])/(wl_repeat[:,-2]-wl_repeat[:,-1]) * (value["wl_range"][1]-wl_repeat[:,-2])

            # Build the actual wl array over which you will perform the integration
            wl_ = np.zeros(n_wl)
            wl_[0] = value["wl_range"][0]
            wl_[-1] = value["wl_range"][1]
            wl_[1:-1] = wl[i0+1:i1]
            wl_ = np.repeat(wl_[np.newaxis,:], n_rows, axis=0)

            # Linear function approximating the continuum
            grad_ = np.repeat(grad[:, np.newaxis], n_wl, axis=1)
            intercept_ = np.repeat(intercept[:, np.newaxis], n_wl, axis=1)
        
            integrand = 1.0 - SED/(grad_*wl_+intercept_)
            EW = np.ravel(np.trapz(integrand, x=wl_, axis=1))
            EWs[key] = -EW

            integrand = SED-(grad_*wl_+intercept_)
            integrated_flux = np.ravel(np.trapz(integrand, x=wl_, axis=1))
            integrated_fluxes[key] = integrated_flux


        # Create a list of columns from the dictionary containing the EWs
        cols = list()
        for key, value in EWs.iteritems():
            col = fits.Column(name=str(key), format='E', array=value)
            cols.append(col)

        # Create a new binary table HDU 
        columns = fits.ColDefs(cols)
        new_hdu = fits.BinTableHDU.from_columns(columns)
        new_hdu.name = 'EQUIVALENT WIDTHS'

        # Add the new HDU to the Beagle file
        if new_hdu.name in hdulist:
            hdulist[new_hdu.name] = new_hdu
        else:
            hdulist.append(new_hdu)

        # Create a list of columns from the dictionary containing the integrated fluxes
        cols = list()
        for key, value in integrated_fluxes.iteritems():
            col = fits.Column(name=str(key), format='E', array=value)
            cols.append(col)

        # Create a new binary table HDU 
        columns = fits.ColDefs(cols)
        new_hdu = fits.BinTableHDU.from_columns(columns)
        new_hdu.name = 'INTEGRATED FLUXES'

        # Add the new HDU to the Beagle file
        if new_hdu.name in hdulist:
            hdulist[new_hdu.name] = new_hdu
        else:
            hdulist.append(new_hdu)

        hdulist.writeto(f, overwrite=True)

        hdulist.close()



