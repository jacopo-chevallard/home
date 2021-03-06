#! /usr/bin/env python

from astropy.io import fits
import os, glob, sys
import matplotlib.pyplot as plt
import numpy as np
import argparse
from astropy.table import Table, Column


if __name__ == '__main__':

    parser = argparse.ArgumentParser()

    parser.add_argument(
        '--input', '-i',
        help="FITS file to which the HDU will be added",
        type=str, 
        dest="input_file", 
        required=True
    )

    parser.add_argument(
        '--from', 
        help="FITS file from which the HDU will be taken",
        type=str, 
        dest="from_file", 
        required=True
    )

    parser.add_argument(
        '--hdu', 
        help="HDU to be added",
        type=str, 
        dest="hdus", 
        nargs='+',
        required=True
    )

    parser.add_argument(
        '--position', 
        help="Position at which the HDU will be inserted (0 = beginning, -1 = end)",
        type=int, 
        dest="position", 
        default=-1
    )

    parser.add_argument(
        '--output', '-o',
        help="Output file name",
        type=str, 
        dest="output" 
    )

    args = parser.parse_args()    

    hdulist = fits.open(args.input_file)

    hdu_from = fits.open(args.from_file)
    write_file = False
    for name in args.hdus:
        if name not in hdulist:
            new_hdu = hdu_from[name]
            write_file = True

    new_hdulist = fits.HDUList()
    for i, hdu in enumerate(hdulist):
        if args.position == i:
            new_hdulist.append(new_hdu)
        new_hdulist.append(hdu)

    if args.position == -1:
        new_hdulist.append(new_hdu)

    file_name = args.input_file
    if args.output:
        file_name = args.output
        write_file = True

    if write_file: 
        new_hdulist.writeto(file_name, overwrite=True)
