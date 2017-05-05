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
        help="Input file containing BEAGLE results",
        type=str, 
        dest="file", 
        required=True
    )

    parser.add_argument(
        '--output', '-o',
        help="Output ASCII file",
        type=str, 
        dest="output" 
    )

    parser.add_argument(
        '--rows',
        help="Row in the FULL SED extension to be plotted",
        dest="rows", 
        type=int,
        nargs='+'
    )

    args = parser.parse_args()    

    hdulist = fits.open(args.file)

    columns = list()

    # Get the wavelength array
    wl = hdulist['full sed wl'].data['wl'][0,:] / 1.E+04
    tmpCol = Column(wl, name='wl', dtype=np.float32, format='%.5E')
    columns.append(tmpCol)

    # Get the SED
    SEDs = hdulist['full sed'].data

    if args.rows:
        for i, row in enumerate(args.rows):
            sed = SEDs[row,:]
            tmpCol = Column(sed, name='flux_'+str(i), dtype=np.float32, format='%.5E')
            columns.append(tmpCol)
    else:
        for i in range(len(SEDs[:,0])):
            sed = SEDs[i,:]
            tmpCol = Column(sed, name='flux_'+str(i), dtype=np.float32, format='%.5E')
            columns.append(tmpCol)

    newTable = Table(columns)

    if args.output:
        file_name = args.output
    else:
        file_name =  os.path.splitext(args.file)[0] + '.txt'

    newTable.write(file_name, format="ascii.commented_header")

    hdulist.close()


