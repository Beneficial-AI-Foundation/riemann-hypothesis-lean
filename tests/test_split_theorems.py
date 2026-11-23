import tempfile
import unittest
from pathlib import Path

from scripts.split_theorems import inventory, split, strip_comments


class TheoremSplitTests(unittest.TestCase):
    def test_comments_do_not_create_theorems(self):
        source = """/- theorem fake : True := by trivial
/- lemma nested : True := by trivial -/
-/
-- theorem line_comment : True := by trivial
theorem real : True := by trivial
"""
        self.assertEqual(len(strip_comments(source).splitlines()), len(source.splitlines()))
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "Corpus").mkdir()
            (root / "Corpus" / "A.lean").write_text(source)
            found = inventory(root, Path("Corpus"))
            self.assertEqual([(item["name"], item["line"]) for item in found], [("real", 5)])

    def test_split_is_exact_reproducible_and_forces_holdout(self):
        entries = [
            {"file": "A.lean", "line": index, "kind": "theorem", "name": f"t{index}"}
            for index in range(1, 12)
        ]
        train, test = split(entries, "42", [("A.lean", "t11")])
        self.assertEqual((len(train), len(test)), (8, 3))
        self.assertIn(entries[-1], test)
        self.assertEqual((train, test), split(entries, "42", [("A.lean", "t11")]))
        self.assertEqual(set(map(id, train)) | set(map(id, test)), set(map(id, entries)))
        self.assertFalse(set(map(id, train)) & set(map(id, test)))

    def test_statement_wrappers_are_excluded_by_default(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "Corpus").mkdir()
            (root / "Corpus" / "A.lean").write_text("private lemma helper : True := by trivial\n")
            (root / "Corpus" / "AStatement.lean").write_text("theorem helper : True := by trivial\n")
            self.assertEqual(len(inventory(root, Path("Corpus"))), 1)
            self.assertEqual(len(inventory(root, Path("Corpus"), True)), 2)


if __name__ == "__main__":
    unittest.main()
