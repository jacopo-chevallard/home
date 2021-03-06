#compdef add_keyword_to_FITS_header.py
#
# this is zsh completion function file.
# generated by genzshcomp(ver: 0.5.2)
#

typeset -A opt_args
local context state line

_arguments -s -S \
  "-h[show this help message and exit]:" \
  "--help[show this help message and exit]:" \
  "--input[Name of the input FITS file]::INPUT:_files" \
  "-i[Name of the input FITS file]::INPUT:_files" \
  "--header-keyword[Keyword of the header]::KEYWORD:_files" \
  "--header-value[VALUE ...\] Value of the header]::VALUE:_files" \
  "--header-comment[Comment of the header]::COMMENT:_files" \
  "--hdu[Name or number of the HDU]::HDU:_files" \
  "--output[Name of the output FITS file]::OUTPUT:_files" \
  "-o[Name of the output FITS file]::OUTPUT:_files" \
  "*::args:_files"
