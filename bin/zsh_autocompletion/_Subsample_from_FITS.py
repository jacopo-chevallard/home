#compdef Subsample_from_FITS.py
#
# this is zsh completion function file.
# generated by genzshcomp(ver: 0.5.2)
#

typeset -A opt_args
local context state line

_arguments -s -S \
  "-h[show this help message and exit]:" \
  "--help[show this help message and exit]:" \
  "--input[Name of the input catalogue]::INPUT:_files" \
  "-i[Name of the input catalogue]::INPUT:_files" \
  "--output[Name of the output catalogue]::OUTPUT:_files" \
  "-o[Name of the output catalogue]::OUTPUT:_files" \
  "--ID-list[List of object IDs to copy to the new file]::ID_LIST:_files" \
  "--ID-key[Column name containing object IDs]::ID_KEY:_files" \
  "--ID-filename[File containing list of object IDs to copy to the new file]::ID_FILE_LIST:_files" \
  "--number[Number of catalogue entries to copy to new file.]::N_OBJECTS:_files" \
  "-n[Number of catalogue entries to copy to new file.]::N_OBJECTS:_files" \
  "--shuffle[Whether to shuffle the catalogue entries or not.]" \
  "--force[Force overwriting of an already existing file.]" \
  "-f[Force overwriting of an already existing file.]" \
  "--seed[Seed of random number random generator]::SEED:_files" \
  "*::args:_files"
