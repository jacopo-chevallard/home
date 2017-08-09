#! /usr/bin/env python

import argparse
from astropy.table import Table, Column
from astropy.io import fits
import numpy as np

if __name__ == '__main__':

    parser = argparse.ArgumentParser()

    parser.add_argument(
        '-i', '--input',
        help="name of the input FITS catalogue",
        action="store", 
        type=str, 
        dest="input", 
        required=True
    )

    parser.add_argument(
        '-o', '--output',
        help="name of the output FITS catalogue",
        action="store", 
        type=str, 
        dest="output" 
    )

    parser.add_argument(
        '--ID-key',
        help="Column name containing object IDs",
        action="store", 
        type=str, 
        default="ID",
        dest="ID_key"
    )

    # Get parsed arguments
    args = parser.parse_args()    

    hdulist = fits.open(args.input)
    n = len(hdulist[1].data.field(0))

    indices = np.array(range(n)) + 1
    ID_col = fits.Column(array=indices, name=args.ID_key, format='I')

    new_hdulist = fits.HDUList([hdulist[0]])
    cols = None

    for hdu in hdulist:

        if hdu.data is None:
            continue

        if cols is None and not hdu.is_image:
            cols = list()
            cols.append(ID_col)
            for col in hdu.columns:
                cols.append(col)

            cols_ = fits.ColDefs(cols)
            new_hdu = fits.BinTableHDU.from_columns(cols_)
            new_hdu.name = hdu.name
            new_hdulist.append(new_hdu)
        else:
            new_hdulist.append(hdu)

    output = args.input
    if args.output is not None:
        output = args.output

    new_hdulist.writeto(output, clobber=True)
