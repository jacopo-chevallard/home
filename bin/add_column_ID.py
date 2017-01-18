#! /usr/bin/env python

import argparse
from astropy.table import Table, Column
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

    t = Table.read(args.input, format='fits')

    n = len(t)
    indices = np.array(range(n)) + 1

    ID_col = Column(indices, name=args.ID_key, dtype='i4')

    t.add_column(ID_col, index=0)

    output = args.input
    if args.output is not None:
        output = args.output

    t.write(output, format='fits', overwrite=True)
