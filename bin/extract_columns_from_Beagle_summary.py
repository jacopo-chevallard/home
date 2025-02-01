#! /usr/bin/env python

import argparse
import os
import numpy as np
from astropy.io import fits
from fnmatch import fnmatch

if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--input",
        help="Name of the input FITS file.",
        action="store",
        type=str,
        dest="input_file",
        required=True,
    )

    parser.add_argument(
        "--output",
        help="Name of the output ASCII file.",
        action="store",
        type=str,
        dest="output_file",
        required=True,
    )

    parser.add_argument(
        "--columns",
        help="List of column names to extract (wildcards allowed)",
        action="store",
        type=str,
        nargs="+",
        dest="columns",
        required=True,
    )

    parser.add_argument(
        "--separator",
        help="Column separator for the output ASCII file",
        action="store",
        type=str,
        dest="separator",
        default="   ",
    )

    parser.add_argument(
        "--precision",
        help="Number of significant digits for floating-point numbers",
        action="store",
        type=int,
        dest="precision",
        default=3,
    )

    # Get parsed arguments
    args = parser.parse_args()

    # Get all column names from all extensions
    columns_names = []
    with fits.open(args.input_file) as hdulist:
        for hdu in hdulist[1:]:  # Skip primary HDU
            if isinstance(hdu, fits.BinTableHDU):
                for col in hdu.columns:
                    if col.name not in columns_names:
                        columns_names.append(col.name)

    columns_names = np.array(columns_names)

    # Find columns matching the patterns
    columns_to_extract = []
    for pattern in args.columns:
        matches = [col for col in columns_names if fnmatch(col, pattern)]
        columns_to_extract.extend(matches)

    # Remove duplicates while preserving order
    columns_to_extract = list(dict.fromkeys(columns_to_extract))

    if not columns_to_extract:
        raise ValueError("No columns found matching the specified patterns!")

    # Extract data from the matched columns
    data_dict = {}
    with fits.open(args.input_file) as hdulist:
        for col_name in columns_to_extract:
            for hdu in hdulist[1:]:
                if isinstance(hdu, fits.BinTableHDU) and col_name in hdu.columns.names:
                    data_dict[col_name] = hdu.data[col_name]
                    break

    # Write to ASCII file
    with open(args.output_file, "w") as f:
        # Write header
        f.write("# " + args.separator.join(columns_to_extract) + "\n")

        # Write data
        n_rows = len(next(iter(data_dict.values())))
        for i in range(n_rows):
            row_values = []
            for col in columns_to_extract:
                value = data_dict[col][i]
                if isinstance(value, (float, np.floating)):
                    formatted_value = f"{value:.{args.precision}g}"
                else:
                    formatted_value = str(value)
                row_values.append(formatted_value)
            f.write(args.separator.join(row_values) + "\n")
