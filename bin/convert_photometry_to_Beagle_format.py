#! /usr/bin/env python

from astropy.io import ascii
from astropy.table import Table
from astropy.io import fits
import argparse
import os
import pandas as pd
import numpy as np
from collections import OrderedDict

PREFIXES = ["F"]
OPERATORS = ["<", "<=", ">", ">="]

if __name__ == '__main__':

    parser = argparse.ArgumentParser()

    parser.add_argument(
        '-i', '--input',
        help="name of the input ASCII catalogue containing photometry",
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
        '--limit-n-sigma',
        help="The upper/lower limit definition in units of sigma",
        action="store", 
        type=int, 
        dest="limit_n_sigma",
        default=3 
    )

    # Get parsed arguments
    args = parser.parse_args()    

    if args.output is None:
        output = os.path.splitext(args.input)[0] + '.fits'
    else:
        output = args.output

    # Open and read ASCII file line by line
    data = OrderedDict()

    # Count number of objects
    n_object = 0
    with open(args.input) as file:
        for line in file:
            line = line.strip()
            if line.startswith('ID'):
                n_object += 1

    data['ID'] = np.zeros(n_object, dtype='20a')
    data['z'] = np.zeros(n_object, dtype=float)
    data['z_err'] = np.zeros(n_object, dtype=float)
    i = -1
    with open(args.input) as file:
        for line in file:
            if line.strip():
                line = line.strip().rstrip('\\') 
                if line.startswith('ID'):
                    i += 1
                    data['ID'][i] = line.split()[-1]
                elif line.startswith('z'):
                    data['z_err'][i] = float(line.split()[-1])
                    data['z'][i] = float(line.split()[-3])
                else:
                    for prefix in PREFIXES:
                        if line.lower().startswith(prefix.lower()):
                            col_name = line.split()[0]
                            if col_name+'_error' not in data:
                                data[col_name + "_value"] = np.array([-99.]*n_object)
                                data[col_name + "_error"] = np.array([-99.]*n_object)
                                data[col_name + "_type"] = np.array(['standard']*n_object)
                            if any(op in line for op in OPERATORS):
                                if "<" or "<=" in line:
                                    col_type = "upper"
                                elif ">" or ">=" in line:
                                    col_type = "lower"
                                col_error = float(line.split()[-1])/args.limit_n_sigma
                                col_value = 0.
                            else:
                                col_type = "standard"
                                col_error = float(line.split()[-1])
                                col_value = float(line.split()[-3])

                            data[col_name + "_value"][i] = col_value
                            data[col_name + "_error"][i] = col_error
                            data[col_name + "_type"][i] = col_type

    df = pd.DataFrame(data)
    t = Table.from_pandas(df)       
    t.write(output, overwrite=True)