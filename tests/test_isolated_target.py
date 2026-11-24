import unittest

from scripts.make_isolated_target import HOLE, TARGET, extract, sha256
from scripts.split_theorems import DEFAULT_HOLDOUT, ROOT


class IsolatedTargetTests(unittest.TestCase):
    def manifest(self):
        path = ROOT / DEFAULT_HOLDOUT[0]
        source = path.read_text(encoding="utf-8")
        line = next(i for i, text in enumerate(source.splitlines(), 1)
                    if text.startswith("theorem normPrimes_short_interval_lower :"))
        return {"schema": "theorem-split/v1", "test": [{
            "file": DEFAULT_HOLDOUT[0].as_posix(), "name": DEFAULT_HOLDOUT[1],
            "line": line, "source_sha256": sha256(source),
        }]}

    def test_task_hides_original_proof_and_keeps_statement(self):
        task, proof, prefix = extract(self.manifest())
        self.assertIn("theorem normPrimes_short_interval_lower :", task)
        self.assertIn(HOLE, task)
        self.assertNotIn("obtain ⟨A, c₀, e", task)
        self.assertIn("obtain ⟨A, c₀, e", proof)
        self.assertNotIn("#check " + TARGET, prefix)

    def test_stale_manifest_is_rejected(self):
        manifest = self.manifest()
        manifest["test"][0]["source_sha256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "hash differs"):
            extract(manifest)


if __name__ == "__main__":
    unittest.main()
