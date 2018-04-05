#! /usr/bin/env python

from astropy.io import ascii
from astropy.io import fits
import argparse
import os
import numpy as np


def Jy_factor(units):

    if units.lower() == "jy":
        factor = 1.
    elif units.lower() == "millijy":
        factor = 1.e+03
    elif units.lower() == "microjy":
        factor = 1.e+06
    elif units.lower() == "nanojy":
        factor = 1.e+09
    else:
        raise ValueError("Units " + units + " not recognized")

    return factor

def mag_is_valid(value):

    mag_is_valid = True
    if value >= 40. or value < 0.:
        mag_is_valid = False

    return mag_is_valid

if __name__ == '__main__':

    parser = argparse.ArgumentParser()

    parser.add_argument(
        '-i', '--input',
        help="Name of the input FITS catalogue",
        action="store", 
        type=str, 
        dest="input", 
        required=True
    )

    parser.add_argument(
        '--input-units',
        help="Units of the input catalogue",
        action="store", 
        type=str, 
        dest="input_units",
        choices=["AB"],
        default="AB"
    )

    parser.add_argument(
        '-o', '--output',
        help="Name of the output FITS catalogue containing fluxes",
        action="store", 
        type=str, 
        dest="output" 
    )

    parser.add_argument(
        '--output-units',
        help="Units of the output catalogue",
        action="store", 
        type=str, 
        dest="output_units",
        choices=["Jy", "milliJy", "microJy", "nanoJy"],
        default="microJy"
    )

    parser.add_argument(
        '--band-list',
        help="List of column names containing photometric bands",
        action="store", 
        type=str, 
        nargs="+",
        dest="band_list",
        required=True
    )

    parser.add_argument(
        '--error-prefix',
        help="Prefix indicating the columns containing the flux errors",
        action="store", 
        type=str, 
        dest="error_prefix"
    )

    parser.add_argument(
        '--error-suffix',
        help="Suffix indicating the columns containing the flux errors",
        action="store", 
        type=str, 
        dest="error_suffix",
        default="_err"
    )

    # Get parsed arguments
    args = parser.parse_args()    

    if args.output is None:
        output = os.path.splitext(args.input)[0] + "_fnu" + '.fits'
    else:
        output = args.output

    new_hdulist = fits.HDUList(fits.PrimaryHDU())

    hdulist = fits.open(args.input)

    message = "Name of the output FITS catalogue: " + output
    print "\n" + "-"*len(message)
    print message
    print "-"*len(message) + '\n'

    band_err_list = list()
    for band in args.band_list:
        if args.error_prefix is not None:
            err = args.error_prefix + band
        else:
            err = band + args.error_suffix
        band_err_list.append(err)

    band_err_list = np.array(band_err_list)
    print "band_err_list: ", band_err_list

    new_cols = list()

    hdu = hdulist[1]
    for col in hdu.columns:
        if col.name in args.band_list:
            x = hdu.data[col.name]
            mask = np.ones(len(x), dtype=bool)
            non_valid = np.where((x <= 0.) | (x >= 40.))[0]
            x = 10.**(-0.4*(x-8.9)) * Jy_factor(args.output_units)
            x[non_valid] = -99.
            new_cols.append(fits.Column(name=col.name, array=x, format='E'))
        elif col.name in band_err_list:
            sig_x = hdu.data[col.name]
            mask = np.ones(len(sig_x), dtype=bool)
            non_valid = np.where((sig_x <= 0.) | (sig_x >= 40.))[0]
            if args.error_prefix is not None:
                n = len(args.error_prefix)
                name = col.name[n:]
            else:
                n = len(args.error_suffix)
                name = col.name[:-n]
            x = 10.**(-0.4*(hdu.data[name]-8.9)) * Jy_factor(args.output_units)
            xerr = np.log(10.) * 0.4 * x * sig_x
            xerr[non_valid] = -99.
            new_cols.append(fits.Column(name=col.name, array=xerr, format='E'))
        else:
            new_cols.append(col)


    colsDef = fits.ColDefs(new_cols)

    new_hdulist.append(fits.BinTableHDU.from_columns(colsDef))

    new_hdulist.writeto(output, overwrite=True)
