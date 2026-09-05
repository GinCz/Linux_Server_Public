"""Offline regression tests; no public measurements are submitted."""

import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import monitor


def row(country, asn, target, control="OK"):
    return {"country": country, "asn": asn, "target": target, "control": control}


class MonitorTests(unittest.TestCase):
    def test_incomplete_ip_rejected(self):
        with self.assertRaises(ValueError):
            monitor.validate_target({"name": "test", "ip": "1.1.1", "port": 443})

    def test_private_ip_rejected(self):
        with self.assertRaises(ValueError):
            monitor.validate_target({"name": "test", "ip": "127.0.0.1", "port": 443})

    def test_port_and_name_validation(self):
        for name, port in (("bad\nname", 443), ("valid", 0), ("valid", True), ("valid", 65536)):
            with self.assertRaises(ValueError):
                monitor.validate_target({"name": name, "ip": "1.1.1.1", "port": port})

    def test_tcp_parser(self):
        for value in (None, [], [None], [[None]], [{"unexpected": 1}]):
            self.assertEqual(monitor.parse_tcp(value), "NO_DATA")
        self.assertEqual(monitor.parse_tcp([{"time": 0.03}]), "OK")
        self.assertEqual(monitor.parse_tcp([{"error": "timeout"}]), "FAIL")

    def test_independent_asn_selection(self):
        nodes = {"ru1": {"location": ["ru"], "asn": "AS1"},
                 "ru2": {"location": ["ru"], "asn": "AS1"},
                 "ru3": {"location": ["ru"], "asn": "AS2"},
                 "de1": {"location": ["de"], "asn": "AS3"}}
        self.assertEqual(set(monitor.select_nodes(nodes)), {"ru1", "ru3", "de1"})

    def test_two_russian_networks_fail(self):
        self.assertEqual(monitor.classify([row("ru", "AS1", "FAIL"), row("ru", "AS2", "FAIL"),
                                           row("de", "AS3", "OK")]), "RU_RESTRICTION_SUSPECTED")

    def test_duplicate_asn_not_national_evidence(self):
        self.assertEqual(monitor.classify([row("ru", "AS1", "FAIL"), row("ru", "AS1", "FAIL"),
                                           row("de", "AS3", "OK")]), "RU_NETWORK_FAILURE")

    def test_broken_controls_not_blocking(self):
        self.assertEqual(monitor.classify([row("ru", "AS1", "FAIL", "FAIL"),
                                           row("de", "AS3", "OK")]), "INCONCLUSIVE")

    def test_no_russian_nodes(self):
        self.assertEqual(monitor.classify([row("de", "AS3", "OK")]), "INCONCLUSIVE")

    def test_missing_result_not_green(self):
        self.assertEqual(monitor.classify([row("ru", "AS1", "OK"), row("ru", "AS2", "NO_DATA"),
                                           row("de", "AS3", "OK")]), "PARTIAL_DATA")

    def test_reachable_and_global_failure(self):
        for outcome, expected in (("OK", "TCP_REACHABLE"), ("FAIL", "TARGET_OR_ROUTE_FAILURE")):
            self.assertEqual(monitor.classify([row("ru", "AS1", outcome), row("ru", "AS2", outcome),
                                               row("de", "AS3", outcome)]), expected)

    def test_pending_poll_and_unreturned_node(self):
        responses = iter([{"ok": 1, "request_id": "abc", "nodes": {"ru1": []}},
                          {"ru1": None}, {"ru1": [{"time": 0.01}]}])
        results, request_id = monitor.measure("1.1.1.1:443", {"ru1": {}, "ru2": {}},
                                              get=lambda _: next(responses), sleep=lambda _: None)
        self.assertEqual(results, {"ru1": "OK", "ru2": "NO_DATA"})
        self.assertEqual(request_id, "abc")

    def test_poll_timeout(self):
        responses = iter([{"ok": 1, "request_id": "abc", "nodes": {"ru1": []}}, {"ru1": None}])
        results, _ = monitor.measure("1.1.1.1:443", {"ru1": {}}, get=lambda _: next(responses),
                                     sleep=lambda _: None, polls=1)
        self.assertEqual(results["ru1"], "NO_DATA")

    def test_rejected_api(self):
        with self.assertRaises(ValueError):
            monitor.measure("1.1.1.1:443", {"ru1": {}}, get=lambda _: {"ok": 0})

    def test_hysteresis_recovery_and_interruption(self):
        state = {}
        for expected in (False, False, True, False):
            state, changed = monitor.transition(state, "RU_NETWORK_FAILURE", 3)
            self.assertEqual(changed, expected)
        for status in ("TCP_REACHABLE", "INCONCLUSIVE", "TCP_REACHABLE", "TCP_REACHABLE"):
            state, changed = monitor.transition(state, status, 3)
            self.assertFalse(changed)
        state, changed = monitor.transition(state, "TCP_REACHABLE", 3)
        self.assertTrue(changed)

    def test_api_failure_saved_as_inconclusive(self):
        target = {"name": "test", "ip": "1.1.1.1", "port": 443}
        with tempfile.TemporaryDirectory() as directory, patch.object(monitor, "api_get", side_effect=OSError), patch("builtins.print"):
            report = monitor.run_cycle([target], "example.com:443", Path(directory), 3, {})
            self.assertEqual(report["targets"][0]["status"], "INCONCLUSIVE")
            self.assertEqual(json.loads((Path(directory) / "latest.json").read_text()), report)
            self.assertTrue((Path(directory) / "history.jsonl").is_file())

    def test_local_probe_timeout_and_errors(self):
        self.assertEqual(monitor.probe(None), "NOT_CONFIGURED")
        with patch.object(monitor.subprocess, "run", side_effect=OSError):
            self.assertEqual(monitor.probe(["missing"]), "NO_DATA")
        for code, status in ((0, "PASS"), (1, "FAIL"), (2, "NO_DATA")):
            with patch.object(monitor.subprocess, "run") as run:
                run.return_value.returncode = code
                self.assertEqual(monitor.probe(["test"]), status)
                self.assertFalse(run.call_args.kwargs.get("shell", False))


if __name__ == "__main__":
    unittest.main()
