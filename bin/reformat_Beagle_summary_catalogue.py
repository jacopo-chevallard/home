#! /usr/bin/env python

import argparse
import os
from collections import OrderedDict
import json
from astropy.io import fits
import numpy as np
from scipy.interpolate import interp1d
from scipy import stats


_COLUMNS_TO_KEEP = ['ID', 'MAP_probability', 'MAP_ln_likelihood', 'MAP_chi_square', 'MAP_n_data']

if __name__ == '__main__':

    parser = argparse.ArgumentParser()

    parser.add_argument(
        '--summary-catalogue',
        help="Name of the Beagle summary catalogue that will be reformatted.",
        action="store", 
        type=str, 
        dest="beagle_summary",
        default="BEAGLE_summary_catalogue.fits"
    )

    parser.add_argument(
        '--output',
        help="Name of the output, reformatted Beagle summary catalogue.",
        action="store", 
        type=str, 
        dest="output",
        default="BEAGLE_summary_catalogue_reformatted.fits"
    )

    parser.add_argument(
        '--include',
        help="List of physical parameters to be included in the reformatted file",
        action="store", 
        type=str, 
        nargs="+",
        dest="included_parameters"
    )

    parser.add_argument(
        '--exclude',
        help="List of physical parameters to be excluded from the reformatted file",
        action="store", 
        type=str, 
        nargs="+",
        dest="excluded_parameters"
    )


    # Get parsed arguments
    args = parser.parse_args()

    with fits.open(args.beagle_summary) as hdulist:
    
        columns_names = list()

        for hdu in hdulist[1:]:
            for col in hdu.columns:
                if col.name not in columns_names:
                    columns_names.append(col.name)

    columns_names = np.array(columns_names)

    if args.included_parameters:
        columns_to_keep = list()
        for suffix in args.included_parameters:
            columns_to_keep = columns_to_keep + list(columns_names[np.char.startswith(columns_names,suffix)])
    elif args.excluded_parameters:
        columns_to_keep = list()
        for suffix in args.excluded_parameters:
            columns_to_keep = columns_to_keep + list(columns_names[~np.char.startswith(columns_names,suffix)])
    else:
        columns_to_keep = list(columns_names)

    columns_to_keep = _COLUMNS_TO_KEEP + columns_to_keep

    new_hdulist = fits.HDUList(fits.PrimaryHDU())
    new_cols = list()
    new_cols_names = list()

    with fits.open(args.beagle_summary) as hdulist:
        for name in columns_to_keep:
            for hdu in hdulist[1:]:
                if name in hdu.columns.names and name not in new_cols_names:
                    for col in hdu.columns:
                        if col.name == name:
                            new_cols.append(fits.Column(name=col.name, array=hdu.data[col.name], format=col.format))
                            new_cols_names.append(col.name)
                            continue

        # Compute p-value from chi-square and n_data
        chisquare = hdulist['POSTERIOR PDF'].data['MAP_chi_square']
        dof = hdulist['POSTERIOR PDF'].data['MAP_n_data']
        p_value = list()
        for c, d in zip(chisquare, dof):
            p = 1 - stats.chi2.cdf(c, d)
            p_value.append(p)

    p_value = np.array(p_value)
    is_good_fit = np.ones(len(p_value), dtype=int)
    is_good_fit[p_value <= 0.05] = 0

    p_value_col = fits.Column(name='p_value', array=p_value, format='E')
    new_cols.insert(new_cols_names.index('MAP_n_data')+1, p_value_col)

    is_good_fit_col = fits.Column(name='good_fit', array=is_good_fit, format='I')
    new_cols.insert(new_cols_names.index('MAP_n_data')+2, is_good_fit_col)

    colsDef = fits.ColDefs(new_cols)

    new_hdulist.append(fits.BinTableHDU.from_columns(colsDef))

    new_hdulist.writeto(args.output, overwrite=True)





