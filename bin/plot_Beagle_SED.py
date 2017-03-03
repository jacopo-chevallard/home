#! /usr/bin/env python

from astropy.io import fits
import os, glob, sys
import matplotlib.pyplot as plt
import numpy as np
import argparse

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

    args = parser.parse_args()    

    hdulist = fits.open(args.file)

    # Get the wavelength array
    wl = hdulist['full sed wl'].data['wl'][0,:]

    # Get the SED
    SEDs = hdulist['full sed'].data
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

    ax.plot(wl/1.E+04,
       sed,
       lw=1.0,
       color="red"
        )

    plt.show()
    hdulist.close()
