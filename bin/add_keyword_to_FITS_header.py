#! /usr/bin/env python

from astropy.io import fits
import argparse
import os
import numpy as np

if __name__ == '__main__':

    parser = argparse.ArgumentParser()

    parser.add_argument(
        '-i', '--input',
        help="Name of the input FITS file",
        action="store", 
        type=str, 
        dest="input", 
        required=True
    )

    parser.add_argument(
        '--header-keyword',
        help="Keyword of the header",
        action="store", 
        type=str, 
        dest="keyword", 
        required=True,
        nargs='+'
    )

    parser.add_argument(
        '--header-value',
        help="Value of the header",
        action="store", 
        dest="value", 
        required=True,
        nargs='+'
    )

    parser.add_argument(
        '--header-comment',
        help="Comment of the header",
        action="store", 
        type=str, 
        dest="comment",
        nargs='+'
    )


    parser.add_argument(
        '--hdu',
        help="Name or number of the HDU",
        action="store", 
        dest="hdu",
        default=1
    )

    parser.add_argument(
        '-o', '--output',
        help="Name of the output FITS file",
        action="store", 
        type=str, 
        dest="output" 
    )

    # Get parsed arguments
    args = parser.parse_args()    

    # Try to convert the value into a float
    try:
        value = np.float32(args.value)
    except:
        value = args.value


    with fits.open(args.input) as hdulist:

        try:
            hdu = np.int(args.hdu)
        except:
            hdu = args.hdu

        header = hdulist[hdu].header


        if args.comment is None:
            for keyword, value in zip(args.keyword, args.value):
                header[keyword] = value
        else:
            for keyword, value, comment in zip(args.keyword, args.value, args.comment):
                header[keyword] = (value, comment)

        # Save the new file
        output = args.input
        if args.output is not None:
            output = args.output

        hdulist.writeto(output, clobber=True)
