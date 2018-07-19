#compdef add_EWs_to_beagle_output.py
#
# this is zsh completion function file.
# generated by genzshcomp(ver: 0.5.2)
#

typeset -A opt_args
local context state line

_arguments -s -S \
  "-h[show this help message and exit]:" \
  "--help[show this help message and exit]:" \
  "--beagle-file[Name of the Beagle file containing the model SEDs for which EWs must be computed.]::BEAGLE_FILE:_files" \
  "--json-file[JSON file containing the list of emission lines for which EWs will be computed.]::JSON_FILE:_files" \
  "*::args:_files"