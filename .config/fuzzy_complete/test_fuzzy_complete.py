
import io
import os
import shutil
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

import fuzzy_complete

FUZZTEST_DIR = Path(os.environ["HOME"]) /"FuzzTest"

def setUpModule():
    files = [
        FUZZTEST_DIR/"Documents",

        FUZZTEST_DIR/"Documents"/".hidden",

        FUZZTEST_DIR/"Documents"/"Misc",
        FUZZTEST_DIR/"Documents"/"Misc"/"dir1_file.txt",
        FUZZTEST_DIR/"Documents"/"Misc"/"dependency",
        FUZZTEST_DIR/"Documents"/"Misc"/"dependency"/"dep 1.txt",
        FUZZTEST_DIR/"Documents"/"Misc"/"dependency"/"dep 2.txt",
        FUZZTEST_DIR/"Documents"/"Misc"/"dependency"/"dep 3.txt",
        FUZZTEST_DIR/"Documents"/"Misc"/"subdir",
        FUZZTEST_DIR/"Documents"/"Misc"/"subdir"/"subfile1.log",
        FUZZTEST_DIR/"Documents"/"Misc"/"subdir"/"subfile2.log",
        FUZZTEST_DIR/"Documents"/"program",
        FUZZTEST_DIR/"Documents"/"program"/"prog.cpp",
        FUZZTEST_DIR/"Documents"/"program"/"prog.hpp",
        FUZZTEST_DIR/"Documents"/"project",
        FUZZTEST_DIR/"Documents"/"project"/"package.py",
        FUZZTEST_DIR/"Documents"/"project"/"utils.py",

        FUZZTEST_DIR/"Downloads",
        FUZZTEST_DIR/"Downloads"/"book.epub",
        FUZZTEST_DIR/"Downloads"/"video.mp4",

        FUZZTEST_DIR/"Videos",
        FUZZTEST_DIR/"Videos"/"movie 1.mkv",
        FUZZTEST_DIR/"Videos"/"movie 2.mkv",
    ]

    for path in files:
        if str(path).startswith(".") or not path.suffix:
            path.mkdir(exist_ok=True, parents=True)
        else:
            path.touch()

def tearDownModule():
    shutil.rmtree(FUZZTEST_DIR, ignore_errors=True)

def define_test(cls, name, args, target):
    def _inner_test(self):
        os.chdir(FUZZTEST_DIR)
        full_args = self.common_args + args
        with patch.object(sys, "argv", full_args):
            fuzzy_complete.main()

        output = self.captured_output.getvalue()
        self.assertEqual(output, target)

    setattr(cls, f"test_{name}", _inner_test)


def define_class(cmd, only_dir):
    class NewClass(unittest.TestCase):
        def setUp(self):
            self.common_args = ["fuzzy_test", str(int(only_dir)), "1", cmd]
            self.captured_output = io.StringIO()
            sys.stdout = self.captured_output

        def tearDown(self):
            sys.stdout = sys.__stdout__

    return NewClass


if __name__ == "__main__":
    LsTest = define_class("ls", only_dir=False)
    define_test(LsTest, "simple", ["Doc"], "Documents\n")
    define_test(LsTest, "case", ["doc"], "Documents\n")
    define_test(LsTest, "skip_letters", ["dw"], "Downloads\n")
    define_test(LsTest, "file", ["dw/b"], "Downloads/book.epub\n")
    define_test(LsTest, "multiple", ["do"], "Documents\nDownloads\n")
    define_test(LsTest, "multiple_files", ["v/m"], "Videos/movie 1.mkv\nVideos/movie 2.mkv\n")
    define_test(LsTest, "successive_joined", ["do/proj"], "Documents/project\n")
    define_test(LsTest, "hidden", ["do/hid"], "Documents/.hidden\n")
    define_test(LsTest, "match_chars", ["dmd"], "Documents/Misc/dependency\nDocuments/Misc/dir1_file.txt\n")

    # With trailing words
    define_test(LsTest, "tr_skip_letters", ["dw", "ignore"], "Downloads\n")
    define_test(LsTest, "tr_file", ["dw/b", "ignore"], "Downloads/book.epub\n")
    define_test(LsTest, "tr_multiple", ["do", "ignore"], "Documents\nDownloads\n")
    define_test(LsTest, "tr_multiple_files", ["v/m", "ignore"], "Videos/movie 1.mkv\nVideos/movie 2.mkv\n")
    define_test(LsTest, "tr_successive_joined", ["do/proj", "ignore"], "Documents/project\n")
    define_test(LsTest, "tr_hidden", ["do/hid", "ignore"], "Documents/.hidden\n")
    define_test(LsTest, "tr_match_chars", ["dmd", "ignore"], "Documents/Misc/dependency\nDocuments/Misc/dir1_file.txt\n")

    LsDirTest = define_class("ls", only_dir=True)
    define_test(LsDirTest, "simple", ["Doc"], "Documents\n")
    define_test(LsDirTest, "skip_letters", ["dw"], "Downloads\n")
    define_test(LsDirTest, "file", ["dw/b"], "")
    define_test(LsDirTest, "multiple", ["do"], "Documents\nDownloads\n")
    define_test(LsDirTest, "successive_joined", ["do/proj"], "Documents/project\n")
    define_test(LsDirTest, "hidden", ["do/hid"], "Documents/.hidden\n")
    define_test(LsDirTest, "match_chars", ["dmd"], "Documents/Misc/dependency\n")

    # define_test(CdTest, "simple", ["Doc"], "Documents\n")
    # define_test(CdTest, "skip_letters", ["dw"], "Downloads\n")
    # define_test(CdTest, "multiple", ["do"], "Documents\nDownloads\n\u1160\n")
    # define_test(CdTest, "successive", ["do", "proj"], "project\n")
    # define_test(CdTest, "successive_joined", ["do/proj"], "Documents/project\n")
    # define_test(CdTest, "hidden", ["do", "hid"], ".hidden\n")
    # define_test(CdTest, "match_chars", ["dmd"], "Documents/Misc/dependency\n")

    unittest.main()