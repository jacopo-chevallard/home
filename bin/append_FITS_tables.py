#! /usr/bin/env python

import argparse
from astropy.table import Table, Column
from astropy.io import fits
import numpy as np

if __name__ == '__main__':

    parser = argparse.ArgumentParser()

    parser.add_argument(
        '-i', '--input',
        help="name of the input FITS catalogues",
        action="store", 
        type=str, 
        nargs='+',
        dest="input", 
        required=True
    )

    parser.add_argument(
        '-o', '--output',
        help="name of the output FITS catalogue",
        action="store", 
        type=str, 
        dest="output",
        required=True
    )

    # Get parsed arguments
    args = parser.parse_args()    

    # Count the total number of rows in the final table
    n_rows = 0
    for f in args.input:
        hdulist = fits.open(f)
        for hdu in hdulist:
            if hdu.is_image:
                continue
            else:
                n_rows += len(hdu.data.field(0))
                break
        hdulist.close()

    # Copy the structure of the table into the new hdulist structure
    new_hdulist = fits.HDUList(fits.PrimaryHDU())

    first_file = args.input[0]
    hdulist = fits.open(first_file)
    for hdu in hdulist:
        if hdu.is_image:
            continue
        new_columns = list()
        for col in hdu.columns: 
            new_columns.append(fits.Column(name=col.name,
                format=col.format, unit=col.unit))

        cols_ = fits.ColDefs(new_columns)
        new_hdu = fits.BinTableHDU.from_columns(cols_, nrows=n_rows)
        new_hdu.name = hdu.name
        new_hdulist.append(new_hdu)

    # Copy the data from each input FITS table in the output one
    i = 0
    for f in args.input:
        hdulist = fits.open(f)
        for j, hdu in enumerate(new_hdulist):
            if hdu.is_image:
                continue
            if hdu.name:
                old_hdu = hdulist[hdu.name]
            else:
                old_hdu = hdulist[j]
            for col in hdu.columns: 
                if col.name in old_hdu.columns.names:
                    n = len(old_hdu.data[col.name]) 
                    hdu.data[col.name][i:i+n] = old_hdu.data[col.name]

        i += n
        hdulist.close()

    new_hdulist.writeto(args.output, overwrite=True)
