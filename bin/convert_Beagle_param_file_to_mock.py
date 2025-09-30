#! /usr/bin/env python

import os
import glob
import argparse
import logging


def process_parameter_file(param_file_path, output_folder):
    # Read the original parameter file
    with open(param_file_path, "r") as f:
        logging.info(f"Reading parameter file: {param_file_path}")
        lines = f.readlines()

    # Get the results directory from the parameter file
    results_dir = None
    for line in lines:
        if line.strip().startswith("RESULTS DIRECTORY"):
            results_dir = line.split("=")[1].strip()
            # Expand environment variables
            results_dir = os.path.expandvars(results_dir)
            logging.info(f"Found RESULTS DIRECTORY: {results_dir}")
            break

    if not results_dir:
        raise ValueError("Could not find RESULTS DIRECTORY in parameter file")

    # Check that the results directory exists
    if not os.path.exists(results_dir):
        raise ValueError(f"Results directory does not exist: {results_dir}")

    # Find all BEAGLE result files
    beagle_files = glob.glob(os.path.join(results_dir, "*_BEAGLE.fits.gz"))

    for beagle_file in beagle_files:
        new_lines = []
        base_name = os.path.basename(beagle_file)
        mock_name = base_name.replace("_BEAGLE.fits.gz", "_mock_BEAGLE.fits.gz")

        for line in lines:
            line = line.rstrip()

            # Keep comment lines and empty lines as is
            if line.startswith("#") or not line.strip():
                new_lines.append(line)
                continue

            # Handle CATALOGUE lines
            if "CATALOGUE" in line.split("=")[0] and not "MOCK CATALOGUE" in line:
                new_lines.append(f"#{line}")
                continue

            # Replace type:fitted with type:from_file
            if "type:fitted" in line:
                line = line.split("type:fitted")[0].rstrip() + "      type:from_file"

            # Update RESULTS DIRECTORY
            if line.startswith("RESULTS DIRECTORY"):
                line = line.replace("fit_base", "mock") + "_LyC_fesc"

            new_lines.append(line)

        # Add MOCK INPUT PARAMETERS and MOCK CATALOGUE NAME
        new_lines.append(f"MOCK INPUT PARAMETERS = fileName:{beagle_file}")
        new_lines.append(f"MOCK CATALOGUE NAME = {mock_name}")

        # Create output filename
        param_file_name = os.path.basename(param_file_path)
        # If the output folder does not exist, create it
        if not os.path.exists(output_folder):
            os.makedirs(output_folder)

        output_file = os.path.join(
            output_folder,
            f"mock_{os.path.splitext(param_file_name)[0]}_{os.path.splitext(base_name)[0]}.param",
        )

        # Write the new parameter file
        with open(output_file, "w") as f:
            f.write("\n".join(new_lines))


# Example usage:
# process_parameter_file('path/to/param_file.param', 'path/to/beagle/output/folder')

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Convert BEAGLE parameter file to mock parameter files."
    )
    parser.add_argument(
        "--param-file",
        help="Path to the input parameter file",
        type=str,
        required=True,
        action="store",
        dest="param_file",
    )
    parser.add_argument(
        "--output-folder",
        help="Path to the output folder",
        type=str,
        required=True,
        action="store",
        dest="output_folder",
    )

    parser.add_argument(
        "--log-level",
        help="Log level",
        type=str,
        required=False,
        action="store",
        dest="log_level",
        default="INFO",
    )

    args = parser.parse_args()

    logging.basicConfig(level=args.log_level)

    process_parameter_file(args.param_file, args.output_folder)
