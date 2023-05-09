
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
            path.mkdir(parents=True)
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


class CdTest(unittest.TestCase):

    def setUp(self):
        self.common_args = ["fuzzy_test", "1", "cd"]
        self.captured_output = io.StringIO()
        sys.stdout = self.captured_output

    def tearDown(self):
        sys.stdout = sys.__stdout__

if __name__ == "__main__":
    define_test(CdTest, "simple", ["Doc"], "Documents\n")
    define_test(CdTest, "skip_letters", ["dw"], "Downloads\n")
    define_test(CdTest, "multiple", ["do"], "Documents\nDownloads\n\u1160\n")
    define_test(CdTest, "successive", ["do", "proj"], "project\n")
    define_test(CdTest, "successive_joined", ["do/proj"], "Documents/project\n")
    define_test(CdTest, "hidden", ["do", "hid"], ".hidden\n")
    define_test(CdTest, "match_chars", ["dmd"], "Documents/Misc/dependency\n")
    unittest.main()