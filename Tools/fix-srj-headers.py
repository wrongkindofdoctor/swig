###############################################################################
# File  : Tools/fix-srj-headers.py
# Author: Seth R Johnson
# Date  : Mon Feb 19 10:24:01 2018
###############################################################################
from __future__ import (division, absolute_import, print_function, )
#-----------------------------------------------------------------------------#
import os
import re

from exnihiloenv.utils import LOG as log
from exnihiloenv.rewriter import ReWriter
###############################################################################

IS_SWIG_LIBRARY = False

RE_DIVIDER = re.compile(r'//-+//')
END_OF_FILE = re.compile(r'\s*end of ')

DASHES = '-'*73

def process_func_header(line, oldf):
    return "/* " + DASHES + "\n"

def process_separator(line, oldf):
    """ Transform
// FRAGMENTS
//---------------------------------------------------------------------------//

     into

/* -------------------------------------------------------------------------
 * FRAGMENTS
 * ------------------------------------------------------------------------- */
 """
    if END_OF_FILE.match(line):
        next(oldf)
        return "\n"

    result = ["/* ", DASHES, "\n", " *", line, " */\n"]
    for line in oldf:
        if RE_DIVIDER.match(line):
            result.pop()
            result.extend((" * ", DASHES, " */\n"))
        elif line.startswith("//"):
            result.pop()
            result.append("\n * " + line[2:])
        else:
            result.append(line)
            break

    return "".join(result)


def swig_cpp_headers(path):
    filename = os.path.basename(path)
    with ReWriter(path) as rewriter:
        (old_file, new_file) = rewriter.files
        rewriter.dirty = True

        # Write new header
        if IS_SWIG_LIBRARY:
            new_file.write("".join(["/* ", DASHES, "\n",
                                    " * ", filename, "\n",
                                    " * ", DASHES, " */\n"]))
        else:
            new_file.write("/* File : {} */\n".format(filename))

        # Delete old headr
        for line in old_file:
            if line[:2] not in ['//', '/*', ' *']:
                new_file.write(line)
                break

        for line in old_file:
            if RE_DIVIDER.match(line):
                line = next(old_file)
                if line.startswith('//'):
                    line = process_separator(line[2:], old_file)
                elif line.startswith('/*!'):
                    line = process_func_header(line, old_file)
                else:
                    new_file.write("/* " + DASHES + " */\n")
            new_file.write(line)

        new_file.write("/* vim: set ts=2 sw=2 sts=2 tw=129 : */\n")

def swig_f90_headers(path):
    filename = os.path.basename(path)
    with ReWriter(path) as rewriter:
        (old_file, new_file) = rewriter.files
        rewriter.dirty = True

        new_file.write("! File : {}\n".format(filename))

        # Delete old headr
        for line in old_file:
            if not line.startswith('!'):
                new_file.write(line)
                break

        for line in old_file:
            new_file.write(line.replace("    ", "  "))

        new_file.write("! vim: set ts=2 sw=2 sts=2 tw=129 :\n")

#-----------------------------------------------------------------------------#
def main_cpp():
    extensions = (".h",".cxx",".c",".i",".swg")

    from exnihiloenv.filemodify import _common
    _common.run(swig_cpp_headers,
                default_extensions=",".join(extensions))

#-----------------------------------------------------------------------------#
def main_f90():
    extensions = (".f90",)

    from exnihiloenv.filemodify import _common
    _common.run(swig_f90_headers,
                default_extensions=",".join(extensions))

#-----------------------------------------------------------------------------#
if __name__ == '__main__':
    main_f90()

###############################################################################
# end of Tools/fix-srj-headers.py
###############################################################################
