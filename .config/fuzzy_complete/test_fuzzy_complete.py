
import io
import os
import sys
import unittest
from unittest.mock import patch

import fuzzy_complete


def define_test(cls, name, path, args, target):
    def _inner_test(self):
        os.chdir(path)
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

#     def test_doc_aoc_split(self):
#         os.chdir("/home/valentin")
#         args = self.common_args + ["doc", "aoc"]
#         with patch.object(sys, "argv", args):
#             fuzzy_complete.main()

#         output = self.captured_output.getvalue()
#         self.assertEqual(output, "AdventOfCode\n")

#     def test_doc_aoc_joined(self):
#         os.chdir("/home/valentin")
#         args = self.common_args + ["doc/aoc"]
#         with patch.object(sys, "argv", args):
#             fuzzy_complete.main()

#         output = self.captured_output.getvalue()
#         self.assertEqual(output, "Documents/AdventOfCode\n")

#     def test_root_split(self):
#         os.chdir("/home/valentin")
#         args = self.common_args + ["doc/aoc"]
#         with patch.object(sys, "argv", args):
#             fuzzy_complete.main()

#         output = self.captured_output.getvalue()
#         self.assertEqual(output, "Documents/AdventOfCode\n")

    # def test_cd_tilde(self):
    #     os.chdir("/home/valentin")
    #     args = self.common_args + ["~", ""]
    #     with patch.object(sys, "argv", args):
    #         fuzzy_complete.main()

    #     print(self.captured_output.getvalue())


if __name__ == "__main__":
    define_test(CdTest, "doc", "/home/valentin", ["doc"], "Documents\n")
    define_test(CdTest, "doc_aoc_split", "/home/valentin", ["doc", "aoc"], "AdventOfCode\n")
    define_test(CdTest, "doc_aoc_joined", "/home/valentin", ["doc/aoc"], "Documents/AdventOfCode\n")
    unittest.main()
