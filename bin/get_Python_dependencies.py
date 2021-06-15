#! /usr/bin/env python

import importlib
import os
import pathlib
import re
import sys, chardet
from sty import fg

sys.setrecursionlimit(100000000)

dependenciesPaths = list()
dependenciesNames = list()
paths = sys.path
red = fg(255, 0, 0)
green = fg(0, 200, 0)
end = fg.rs


def main(path):
    try:
        print("Finding imports in '" + path + "':")

        file = open(path)
        contents = file.read()
        wordArray = re.split(" |\n", contents)

        currentList = list()
        nextPaths = list()
        skipWord = -1

        for wordNumb in range(len(wordArray)):
            word = wordArray[wordNumb]

            if wordNumb == skipWord:
                continue

            elif word == "from":
                currentList.append(wordArray[wordNumb + 1])
                skipWord = wordNumb + 2

            elif word == "import":
                currentList.append(wordArray[wordNumb + 1])

        currentList = set(currentList)
        for i in currentList:
            print(i)

        print("Found imports in '" + path + "'")
        print("Finding paths for imports in '" + path + "':")

        currentList2 = currentList.copy()
        currentList = list()

        for i in currentList2:
            if i in dependenciesNames:
                print(i, "already found")

            else:
                dependenciesNames.append(i)

                try:
                    fileInfo = importlib.machinery.PathFinder().find_spec(i)
                    print(fileInfo.origin)

                    dependenciesPaths.append(fileInfo.origin)

                    currentList.append(fileInfo.origin)

                except AttributeError as e:
                    print(e)
                    print(i)
                    print(importlib.machinery.PathFinder().find_spec(i))
                    # print(red, "Odd noneType import called ", i, " in path ", path, end, sep='')


        print("Found paths for imports in '" + path + "'")


        for fileInfo in currentList:
            main(fileInfo)

    except Exception as e:
        print(e)


if __name__ == "__main__":
    # args
    args = sys.argv
    print(args)

    if len(args) == 2:
        p = args[1]

    elif len(args) == 3:
        p = args[1]

        open(args[2], "a").close()
        sys.stdout = open(args[2], "w")

    else:
        print('Usage')
        print('PyDependencies <InputFile>')
        print('PyDependencies <InputFile> <OutputFile')

        sys.exit(2)

    if not os.path.exists(p):
        print(red, "Path '" + p + "' is not a real path", end, sep='')

    elif os.path.isdir(p):
        print(red, "Path '" + p + "' is a directory, not a file", end, sep='')

    elif "".join(pathlib.Path(p).suffixes) != ".py":
        print(red, "Path '" + p + "' is not a python file", end, sep='')

    else:
        print(green, "Path '" + p + "' is a valid python file", end, sep='')

        main(p)

    deps = set(dependenciesNames)

    print(deps)

    sys.exit()
