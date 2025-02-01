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
        help="Name of the Beagle output file(s).",
        action="store", 
        type=str, 
        nargs="+",
        dest="beagle_file", 
        required=True
    )

    parser.add_argument(
        '--hdu-name',
        help="Name of the hdu containing the column(s) to rename.",
        action="store", 
        type=str,
        dest="hdu", 
        required=True
    )

    parser.add_argument(
        '--input-column',
        help="Name or position of the input column(s) to rename.",
        action="store", 
        type=str,
        nargs="+",
        dest="input_column", 
        required=True
    )

    parser.add_argument(
        '--output-column',
        help="Name of the renamed column(s).",
        action="store", 
        type=str,
        nargs="+",
        dest="output_column", 
        required=True
    )

    # Get parsed arguments
    args = parser.parse_args()    
    
    for f in args.beagle_file:

        with fits.open(f, mode='update') as hdulist:
            hdu = hdulist[args.hdu]
        
            # Rename column col in hdu my_hdu to new_col
            for input_col, output_col in zip(args.input_column, args.output_column):
                try:
                    col_index = int(input_col)
                except:
                    col_index = hdu.columns.names.index(input_col) + 1
                hdu.header['TTYPE' + str(col_index)] = output_col