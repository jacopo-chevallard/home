#! /usr/bin/env python

from astropy.io import ascii
from astropy.table import Table
from astropy.io import fits
import argparse
import os
import numpy as np

if __name__ == "__main__":

    parser = argparse.ArgumentParser()

    parser.add_argument(
        "-i",
        "--input",
        help="name of the input ASCII catalogue",
        action="store",
        type=str,
        dest="input",
        required=True,
    )

    parser.add_argument(
        "-o",
        "--output",
        help="name of the output FITS catalogue",
        action="store",
        type=str,
        dest="output",
    )

    parser.add_argument(
        "--format",
        help="ASCII format of the input catalogue",
        action="store",
        type=str,
        dest="format",
    )

    parser.add_argument(
        "--id-length",
        help="Pad IDs with leading zeros to reach this length",
        type=int,
        dest="id_length",
    )

    # Get parsed arguments
    args = parser.parse_args()

    data = Table.read(args.input, format=args.format)

    # Clean up set literals in string columns and ensure ID columns are strings
    for name in data.colnames:
        # Treat both string columns and ID columns as strings
        if isinstance(data[name][0], str) or "ID" in name:
            # Convert column to string type if it isn't already
            if not isinstance(data[name][0], str):
                data[name] = [str(val) for val in data[name]]

            # Replace '--' with empty strings
            data[name] = ["" if val == "--" else val for val in data[name]]

            # Only clean up set literals, preserve empty strings
            data[name] = [val.strip("{}") for val in data[name]]

            # Pad IDs with leading zeros if length is specified
            if args.id_length and "ID" in name:
                data[name] = [
                    val.zfill(args.id_length) if val else val for val in data[name]
                ]

        # Check if column contains boolean-like values
        if all(
            str(val).lower() in ["true", "false", "t", "f", "0", "1"]
            for val in data[name]
            if val != ""
        ):
            # Convert to boolean
            data[name] = [
                str(val).lower() in ["true", "t", "1"] if val != "" else False
                for val in data[name]
            ]
            continue

    if args.output is None:
        output = os.path.splitext(args.input)[0] + ".fits"
    else:
        output = args.output

    message = "Name of the output FITS catalogue: " + output
    print("\n" + "-" * len(message))
    print(message)
    print("-" * len(message) + "\n")

    cols = list()

    for name in data.colnames:

        ascii_name = name.encode("ascii", "ignore").decode("ascii")
        form = data.dtype[name]

        # Convert the default double precision to single precision ("E" and "J" types in a FITS file)
        if form == np.float64:
            form = "E"
        elif form == np.int64:
            form = "J"

        if any(isinstance(val, str) for val in data[name]):
            # Convert strings to a fixed-width numpy character array
            str_len = max(len(val) for val in data[name] if val)
            array = np.char.encode(
                np.char.ljust(data[name], str_len), encoding="ascii", errors="ignore"
            )
            form = f"{str_len}A"
        else:
            array = np.ascontiguousarray(data[name])

        # If the column name is "mask" but it doesn't contain logical values, then we convert 0 and 1 to True/False
        if "mask" in name:
            tmp = np.zeros(len(data[name]), dtype=np.bool)
            tmp[data[name] == 1] = True
            data[name] = tmp
            form = "L"

        cols.append(fits.Column(name=ascii_name, array=array, format=form))

    colsDef = fits.ColDefs(cols)

    hdu = fits.BinTableHDU.from_columns(colsDef)

    # Check if the ASCII file contains a
    # redshift = value
    # line, in which case add a header keyword to set the object redshift
    redshift = None
    with open(args.input) as f:
        for line in f:
            if line.startswith("#"):
                if "redshift" in line:
                    try:
                        redshift = np.float32(line.split("=")[1])
                    except:
                        pass
            else:
                break

    if redshift is not None:
        hdu.header["redshift"] = redshift

    hdu.writeto(output, overwrite=True)
