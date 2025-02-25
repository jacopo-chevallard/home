#! /usr/bin/env python

from astropy.io import fits
import numpy as np
import argparse
import os


def extract_rows(input_file, output_file, rows=None, n_rows=None):
    """
    Extract specified rows from a BEAGLE FITS file and create a new FITS file.

    Parameters
    ----------
    input_file : str
        Input FITS file containing BEAGLE results
    output_file : str
        Output FITS file to be created
    rows : list, optional
        List of specific row indices to extract
    n_rows : int, optional
        Number of random rows to extract
    """
    with fits.open(input_file) as hdulist:
        # Get total number of rows from first data extension
        for hdu in hdulist[1:]:
            if hasattr(hdu.data, "__len__"):
                total_rows = len(hdu.data)
                break

        # Generate row indices if n_rows is specified
        if rows is None and n_rows is not None:
            rows = np.random.choice(total_rows, size=n_rows, replace=False)
        elif rows is None and n_rows is None:
            raise ValueError("Either rows or n_rows must be specified")
        # Create new HDUList for output
        new_hdulist = fits.HDUList()

        # Copy primary HDU
        new_hdulist.append(hdulist[0].copy())

        # Process each extension
        for hdu in hdulist[1:]:
            if (
                isinstance(hdu, fits.BinTableHDU)
                and "SED WL" not in hdu.name
                and "SED MASK" not in hdu.name
            ):
                # For binary tables, select specified rows
                new_data = hdu.data[rows]
                new_hdu = fits.BinTableHDU(data=new_data, header=hdu.header)
                new_hdulist.append(new_hdu)

            elif isinstance(hdu, fits.ImageHDU):
                # For image HDUs, extract from first dimension if it matches
                new_data = hdu.data[rows, :]
                new_hdu = fits.ImageHDU(data=new_data, header=hdu.header)
                new_hdulist.append(new_hdu)

            else:
                # Copy other HDU types as is
                new_hdulist.append(hdu.copy())

        # Write the new FITS file
        new_hdulist.writeto(output_file, overwrite=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--input",
        "-i",
        help="Input file containing BEAGLE results",
        type=str,
        required=True,
    )

    parser.add_argument(
        "--output", "-o", help="Output FITS file", type=str, required=True
    )

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--rows", help="Specific row indices to extract", type=int, nargs="+"
    )
    group.add_argument("--n-rows", help="Number of random rows to extract", type=int)

    args = parser.parse_args()

    extract_rows(args.input, args.output, args.rows, args.n_rows)
