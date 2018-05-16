#! /usr/bin/env python

from astropy.io import fits
import os, glob, sys
import matplotlib.pyplot as plt
import numpy as np
import argparse
from autoscale import autoscale_y

c_light = 2.99792e+18 # Ang/s

if __name__ == '__main__':

    parser = argparse.ArgumentParser()

    parser.add_argument(
        '--file',
        help="File containing BEAGLE results",
        type=str, 
        dest="file", 
        required=True
    )

    parser.add_argument(
        '--row',
        help="Row in the FULL SED extension to be plotted",
        dest="row", 
        type=int,
        default=0
    )

    parser.add_argument(
        '--range',
        help="Wavelength range to be plotted",
        dest="xrange", 
        type=np.float32,
        nargs=2,
        default=None
    )

    parser.add_argument(
        '--wl-units',
        help="Wavelength units.",
        action="store",
        type=str,
        dest="wl_units",
        choices=['ang', 'nm', 'micron'],
        default='ang'
        )

    parser.add_argument(
        '--redshift',
        dest="redshift", 
        help="Redshift",
        type=np.float32,
        default=None
        )

    parser.add_argument(
        '--fnu',
        dest="fnu", 
        help="Plot in units of Fnu instead of Flambda",
        action="store_true")

    parser.add_argument(
        '--hdu-name',
        dest="hdu_name", 
        help="Name of the HDU containing the SED to be plotted (it must be a 2D image)",
        type=str,
        default="full sed"
        )
        


    args = parser.parse_args()    

    wl_factor = 1.
    if args.wl_units == 'micron':
        wl_factor = 1.E+04
    elif args.wl_units == 'nm':
        wl_factor = 1.E+01

    hdulist = fits.open(args.file)

    # Get the wavelength array
    hdu_name = args.hdu_name + " wl"
    wl = hdulist[hdu_name].data['wl'][0,:]

    # Get the SED
    hdu_name = args.hdu_name
    SEDs = hdulist[hdu_name].data
    if len(SEDs.shape) == 2 :
        sed = SEDs[args.row,:]
    else:
        sed = SEDs

    # Redshift the SED and wl
    if args.redshift is not None:
        sed /= (1.+args.redshift)
        wl *= (1.+args.redshift)

    # Convert F_lambda [erg s^-1 cm^-2 A^-1] ----> F_nu [erg s^-1 cm^-2 Hz^-1]
    if args.fnu:
        sed = wl**2/c_light*sed

    fig = plt.figure()
    ax = fig.add_subplot(1, 1, 1)

    if args.xrange is not None:
        ax.set_xlim(args.xrange)

    ax.set_xlabel('$\lambda / \mu\\textnormal{m}$')
    if args.fnu:
        ax.set_ylabel('$f_\\nu / \\textnormal{erg} \, \\textnormal{s}^{-1} \, \\textnormal{cm}^{-2} \, \\textnormal{Hz}^{-1} $')
    else:
        ax.set_ylabel('$f_\lambda / \\textnormal{erg} \, \\textnormal{s}^{-1} \, \\textnormal{cm}^{-2} \, \\textnormal{\AA}^{-1} $')

    ax.plot(wl/wl_factor,
       sed,
       lw=1.0,
       color="red"
        )

    autoscale_y(ax)

    plt.show()
    hdulist.close()
