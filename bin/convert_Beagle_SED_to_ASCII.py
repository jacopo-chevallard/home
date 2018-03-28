#! /usr/bin/env python

from astropy.io import fits
import os, glob, sys
import matplotlib.pyplot as plt
import numpy as np
from collections import OrderedDict
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
        '--marginal-sed',
        help="Extract the 'marginal SED'",
        action="store_true",
        dest="marginal_sed" 
    )

    parser.add_argument(
        '--full-sed',
        help="Extract the 'full SED'",
        action="store_true",
        dest="full_sed" 
    )

    parser.add_argument(
        '--rows',
        help="Row in the FULL SED extension to be plotted",
        dest="rows", 
        type=int,
        nargs='+'
    )

    parser.add_argument(
        '--wl-units',
        help="Wavelength units.",
        action="store",
        type=str,
        dest="wl_units",
        choices=['ang', 'nm', 'micron'],
        default='micron'
        )

    parser.add_argument(
        '--wl-range',
        help="Wavelength range to plot.",
        action="store",
        type=float,
        nargs=2,
        dest="wl_range" 
        )

    parser.add_argument(
        '--wl-rest',
        help="Print spectra in rest-frame wavelength",
        action="store_true", 
        dest="wl_rest" 
        )

    parser.add_argument(
        '--print-to-header',
        help="Physical parameters to be reported in the file header, one per row",
        dest="header_par", 
        type=str,
        nargs='+'
    )

    args = parser.parse_args()    

    hdulist = fits.open(args.file)

    columns = list()

    wl_factor = 1.
    if args.wl_units == 'micron':
        wl_factor = 1.E+04
    elif args.wl_units == 'nm':
        wl_factor = 1.E+01



    is_marginal = False
    # Get the wavelength array
    if args.full_sed or 'full sed' in hdulist:
        wl = hdulist['full sed wl'].data['wl'][0,:] / wl_factor

        # Get the SED
        SEDs = hdulist['full sed'].data

    elif args.marginal_sed or 'marginal sed' in hdulist:
        wl = hdulist['marginal sed wl'].data['wl'][0,:] / wl_factor

        # Get the SED
        SEDs = hdulist['marginal sed'].data
        is_marginal = True
    else:
        raise ValueError("No SED present in Beagle output file!")

    if args.wl_range is not None:
        loc = np.where((wl >= args.wl_range[0]) & (wl <= args.wl_range[1]))[0]
    else:
        loc = np.arange(len(wl))

    if is_marginal and args.wl_rest:
        if not args.rows:
            raise ValueError("You can only print rest-frame  'marginal SED' per file!")
        elif len(args.rows) > 1:
            raise ValueError("You can only print rest-frame  'marginal SED' per file!")

    wl = wl[loc]
    if is_marginal and args.wl_rest:
        row = args.rows[0]
        redshift = hdulist['galaxy properties'].data['redshift'][row]
        wl /= (1.+redshift)

    tmpCol = Column(wl, name='wl', dtype=np.float32, format='%.5E')
    columns.append(tmpCol)

    if args.header_par is not None:
        header = OrderedDict()

    if args.rows:
        for i, row in enumerate(args.rows):
            sed = SEDs[row,loc]
            if is_marginal and args.wl_rest:
                sed *= (1.+redshift)
            tmpCol = Column(sed, name='flux_'+str(i), dtype=np.float32, format='%.5E')
            columns.append(tmpCol)

            if args.header_par is not None:
                for par in args.header_par:
                    for hdu in hdulist:
                        try:
                            if par in hdu.columns.names:
                                if par in header:
                                    header[par] = hdu.data[par][row]
                                else:
                                    header[par] = np.zeros(len(args.rows))
                                    header[par] = hdu.data[par][row]
                        except:
                            continue
    else:
        if len(SEDs.shape) == 2:
            for i in range(len(SEDs[:,0])):
                sed = SEDs[i,loc]
                tmpCol = Column(sed, name='flux_'+str(i), dtype=np.float32, format='%.5E')
                columns.append(tmpCol)
        else:
            sed = SEDs[:]
            tmpCol = Column(sed, name='flux_0', dtype=np.float32, format='%.5E')
            columns.append(tmpCol)

    newTable = Table(columns)
    if args.header_par is not None:
        comments = list()
        for key, value in header.iteritems():
            comments.append(key + " = " + "{:.4E}".format(value))
        newTable.meta['comments']  = comments

    if args.output:
        file_name = args.output
    else:
        file_name =  os.path.splitext(args.file)[0] + '.txt'

    newTable.write(file_name, format="ascii.commented_header")

    hdulist.close()


