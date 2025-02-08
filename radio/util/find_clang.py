#
# Most of this code is from clang_complete:
# https://github.com/xavierd/clang_complete/blob/master/plugin/libclang.py
#
import os
import sys
import re

from clang.cindex import *

# Check if libclang is able to find the builtin include files.
#
# libclang sometimes fails to correctly locate its builtin include files. This
# happens especially if libclang is not installed at a standard location. This
# function checks if the builtin includes are available.
def canFindBuiltinHeaders(index, args = []):
    flags = 0
    currentFile = ("test.c", '#include "stddef.h"')
    try:
        tu = index.parse("test.c", args, [currentFile], flags)
    except TranslationUnitLoadError as e:
        return 0

    return len(tu.diagnostics) == 0

# Derive path to clang builtin headers.
#
# This function tries to derive a path to clang's builtin header files. We are
# just guessing, but the guess is very educated. In fact, we should be right
# for all manual installations (the ones where the builtin header path problem
# is very common) as well as a set of very common distributions.
def getBuiltinHeaderPath(library_path):
    if not library_path:
        return None

    if os.path.isfile(library_path):
        library_path = os.path.dirname(library_path)

    knownPaths = [
        library_path + "/../lib/clang",  # default value
        library_path + "/../clang",      # gentoo
        library_path + "/clang",         # opensuse
        library_path + "/",              # Google
        "/usr/lib64/clang",              # x86_64 (openSUSE, Fedora)
        "/usr/lib/clang"
    ]

    for path in knownPaths:
        try:
            subDirs = [f for f in os.listdir(path) if os.path.isdir(path + "/" + f)]
            subDirs = sorted(subDirs) or ['.']
            path = path + "/" + subDirs[-1] + "/include"
            #print("searching builtins in " + path)
            if canFindBuiltinHeaders(index, ["-I" + path]):
                return path
        except:
            pass

    return None

def initLibClang():
    global index

    library_path = os.environ["LIBCLANG_PATH"]
    if library_path:
        if os.path.isdir(library_path):
            Config.set_library_path(library_path)
        else:
            Config.set_library_file(library_path)
    else:
        print("WARN  (find_clang): libclang path not found", file=sys.stderr)

    Config.set_compatibility_check(False)

    try:
        index = Index.create()
    except Exception as e:
        print("ERROR (find_clang): could not load libclang from '%s'." % library_path, file=sys.stderr)
        print("                  : detected platform '%s'" % sys.platform, file=sys.stderr)
        return False

    # Everything is OK, libclang can be used
    return True
