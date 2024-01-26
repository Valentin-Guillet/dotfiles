#!/usr/bin/env -S python3 -B

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
        FUZZTEST_DIR/"Documents"/".conf.vim",

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
        FUZZTEST_DIR/"Documents"/"program"/"utils",
        FUZZTEST_DIR/"Documents"/"project",
        FUZZTEST_DIR/"Documents"/"project"/"__pycache__",
        FUZZTEST_DIR/"Documents"/"project"/"package.py",
        FUZZTEST_DIR/"Documents"/"project"/"utils.py",
        FUZZTEST_DIR/"Documents"/"plugin.vim",

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

def define_test(cls, name, args, targets, workdir=None):
    if workdir is None:
        workdir = FUZZTEST_DIR
    def _inner_test(self):
        os.chdir(workdir)
        full_args = self.common_args + args
        with patch.object(sys, "argv", full_args):
            fuzzy_complete.main()

        output = self.captured_output.getvalue()
        target_str = "\n".join(targets)
        if len(targets) > 1:
            target_str += "\n\u1160\n"
        elif target_str:
            target_str += "\n"
        self.assertEqual(target_str, output)

    setattr(cls, f"test_{name}", _inner_test)

def define_test_class(cmd, only_dir):
    class NewClass(unittest.TestCase):
        def setUp(self):
            self.common_args = ["fuzzy_test", str(int(only_dir)), "1", cmd]
            self.captured_output = io.StringIO()
            sys.stdout = self.captured_output

        def tearDown(self):
            sys.stdout = sys.__stdout__

    return NewClass


if __name__ == "__main__":
    LsTest = define_test_class("ls", only_dir=False)
    define_test(LsTest, "ls_simple", ["Doc"], ["Documents"])
    define_test(LsTest, "ls_simple_slash", ["dw/"], ["Downloads/book.epub", "Downloads/video.mp4"])
    define_test(LsTest, "ls_case", ["doc"], ["Documents"])
    define_test(LsTest, "ls_skip_letters", ["dw"], ["Downloads"])
    define_test(LsTest, "ls_file", ["dw/b"], ["Downloads/book.epub"])
    define_test(LsTest, "ls_multiple", ["do"], ["Documents", "Downloads"])
    define_test(LsTest, "ls_multiple_files", ["v/m"], ["Videos/movie 1.mkv", "Videos/movie 2.mkv"])
    define_test(LsTest, "ls_successive_joined", ["do/proj"], ["Documents/project"])
    define_test(LsTest, "ls_hidden", ["do/hid"], ["Documents/.hidden"])
    define_test(LsTest, "ls_hidden_file", [".cfv"], [".conf.vim"], workdir=FUZZTEST_DIR/"Documents")
    define_test(LsTest, "ls_match_chars", ["dmd"], ["Documents/Misc/dependency", "Documents/Misc/dir1_file.txt"])

    workdir = FUZZTEST_DIR/"Documents"/"Misc"/"dependency"
    define_test(LsTest, "ls_home", ["~/FuzzTest/doc/.hid"], [str(FUZZTEST_DIR)+"/Documents/.hidden"], workdir=workdir)
    define_test(LsTest, "ls_home_multiple", ["~/FuzzTest/d/m/d"],
                [
                    str(FUZZTEST_DIR)+"/Documents/Misc/dependency",
                    str(FUZZTEST_DIR)+"/Documents/Misc/dir1_file.txt",
                ],
                workdir=workdir)
    define_test(LsTest, "ls_match_chars_with_home", ["~fdmd"],
                [
                    str(FUZZTEST_DIR)+"/Documents/Misc/dependency",
                    str(FUZZTEST_DIR)+"/Documents/Misc/dir1_file.txt",
                ],
                workdir=workdir)
    define_test(LsTest, "ls_match_chars_with_root", ["/vo"], ["/var/opt"], workdir=workdir)

    define_test(LsTest, "ls_previous", [".../pg"],
                [
                    "../../program",
                    "../../plugin.vim",
                ],
                workdir=workdir)
    define_test(LsTest, "ls_previous_mult", [".../p/p"],
                [
                    "../../project/__pycache__",
                    "../../program/prog.cpp",
                    "../../program/prog.hpp",
                    "../../project/package.py",
                ],
                workdir=workdir)
    define_test(LsTest, "ls_previous_root", ["............./v/o"], ["/var/opt"])

    # With trailing words
    define_test(LsTest, "ls_tr_skip_letters", ["dw", "ignore"], ["Downloads"])
    define_test(LsTest, "ls_tr_file", ["dw/b", "ignore"], ["Downloads/book.epub"])
    define_test(LsTest, "ls_tr_multiple", ["do", "ignore"], ["Documents", "Downloads"])
    define_test(LsTest, "ls_tr_multiple_files", ["v/m", "ignore"], ["Videos/movie 1.mkv", "Videos/movie 2.mkv"])
    define_test(LsTest, "ls_tr_successive_joined", ["do/proj", "ignore"], ["Documents/project"])
    define_test(LsTest, "ls_tr_hidden", ["do/hid", "ignore"], ["Documents/.hidden"])
    define_test(LsTest, "ls_tr_match_chars", ["dmd", "ignore"], ["Documents/Misc/dependency", "Documents/Misc/dir1_file.txt"])

    LsDirTest = define_test_class("ls", only_dir=True)
    define_test(LsDirTest, "ls_dir_simple", ["Doc"], ["Documents"])
    define_test(LsDirTest, "ls_dir_skip_letters", ["dw"], ["Downloads"])
    define_test(LsDirTest, "ls_dir_file", ["dw/b"], [""])
    define_test(LsDirTest, "ls_dir_multiple", ["do"], ["Documents", "Downloads"])
    define_test(LsDirTest, "ls_dir_successive_joined", ["do/proj"], ["Documents/project"])
    define_test(LsDirTest, "ls_dir_hidden", ["do/hid"], ["Documents/.hidden"])
    define_test(LsDirTest, "ls_dir_match_chars", ["dmd"], ["Documents/Misc/dependency"])

    define_test(LsDirTest, "ls_dir_previous", [".../pg"], ["../../program"], workdir=workdir)
    define_test(LsDirTest, "ls_dir_previous_mult", [".../p/b"], [""], workdir=workdir)

    CdTest = define_test_class("cd", only_dir=True)
    define_test(CdTest, "cd_simple", ["Doc"], ["Documents/"])
    define_test(CdTest, "cd_empty", ["Doc", "m", ""], ["Documents/Misc/dependency", "Documents/Misc/subdir"])
    define_test(CdTest, "cd_empty_no_dirs", ["Doc", "w", ""], [""])
    define_test(CdTest, "cd_case", ["doc"], ["Documents/"])
    define_test(CdTest, "cd_skip_letters", ["dw"], ["Downloads/"])
    define_test(CdTest, "cd_multiple", ["do"], ["Documents", "Downloads"])
    define_test(CdTest, "cd_successive_joined", ["do/proj"], ["Documents/project/"])
    define_test(CdTest, "cd_successive_split", ["do", "proj"], ["project/"])
    define_test(CdTest, "cd_more_successive_split", ["do", "M", "sub"], ["subdir/"])
    define_test(CdTest, "cd_hidden", ["do/hid"], ["Documents/.hidden/"])
    define_test(CdTest, "cd_hidden_split", ["do", ".h"], [".hidden/"])
    define_test(CdTest, "cd_match_chars", ["dmd"], ["Documents/Misc/dependency/"])

    define_test(CdTest, "cd_match_chars_with_home", ["~fdmd"], [str(FUZZTEST_DIR)+"/Documents/Misc/dependency/"], workdir=workdir)
    define_test(CdTest, "cd_match_chars_with_home_split", ["~", "fdms"], ["FuzzTest/Documents/Misc/subdir/"], workdir=workdir)
    define_test(CdTest, "cd_match_chars_with_home_plus", ["~", "fdm", "s"], ["subdir/"], workdir=workdir)
    define_test(CdTest, "cd_match_chars_with_root", ["/vo"], ["/var/opt/"], workdir=workdir)
    define_test(CdTest, "cd_match_chars_with_root_split", ["/", "vo"], ["var/opt/"], workdir=workdir)

    define_test(CdTest, "cd_previous", [".../pg"], ["../../program/"], workdir=workdir)
    define_test(CdTest, "cd_previous_split", ["...", "pg"], ["program/"], workdir=workdir)
    define_test(CdTest, "cd_previous_mult", [".../p"], ["../../program", "../../project"], workdir=workdir)
    define_test(CdTest, "cd_previous_mult_split", ["...", "p"], [str(FUZZTEST_DIR)+"/Documents/program", str(FUZZTEST_DIR)+"/Documents/project"], workdir=workdir)
    define_test(CdTest, "cd_previous_root", ["............."], ["/"])
    define_test(CdTest, "cd_previous_root_plus", ["............./v/o"], ["/var/opt/"])
    define_test(CdTest, "cd_previous_root_spaces", [".............", "v", "o"], ["opt/"])
    define_test(CdTest, "cd_previous_chars", ["...ms"], ["../subdir/"], workdir=workdir)
    define_test(CdTest, "cd_previous_chars_plus", ["....dms"], ["../subdir/"], workdir=workdir)

    define_test(CdTest, "cd_slash_last", ["doc", "mi/"], ["Documents/Misc/dependency", "Documents/Misc/subdir"])
    define_test(CdTest, "cd_slash_last_mult", ["doc", "pro/"], ["Documents/program/utils", "Documents/project/__pycache__"])

    define_test(CdTest, "cd_dot", ["doc", "mi", "./"], ["Documents/Misc/dependency", "Documents/Misc/subdir"])
    define_test(CdTest, "cd_double_dot_space", ["doc", "mi", "dependency", "..", ""], [str(FUZZTEST_DIR)+"/Documents/Misc/dependency", str(FUZZTEST_DIR)+"/Documents/Misc/subdir"])
    define_test(CdTest, "cd_double_dot_space", ["..", ""], ["utils/"], workdir=FUZZTEST_DIR/"Documents"/"program"/"utils")
    define_test(CdTest, "cd_double_dot", ["doc", "mi", ".."], ["../"])
    define_test(CdTest, "cd_double_dot_slash", ["doc", "mi", "../"], ["../.hidden", "../Misc", "../program", "../project"])
    define_test(CdTest, "cd_multi_dot", ["....."], ["../../../../"], workdir=workdir)
    define_test(CdTest, "cd_multi_dot_space", ["....", ""], [str(FUZZTEST_DIR)+"/Documents", str(FUZZTEST_DIR)+"/Downloads", str(FUZZTEST_DIR)+"/Videos"], workdir=workdir)
    define_test(CdTest, "cd_multi_dot_slash", ["..../"], ["../../../Documents", "../../../Downloads", "../../../Videos"], workdir=workdir)
    define_test(CdTest, "cd_multi_dot_split_slash", ["../../../"], ["../../../Documents", "../../../Downloads", "../../../Videos"], workdir=workdir)

    unittest.main()
