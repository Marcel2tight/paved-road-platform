import unittest

from app import app


class ReferenceApplicationTest(unittest.TestCase):
    def setUp(self):
        app.config["TESTING"] = True
        self.client = app.test_client()

    def test_index(self):
        response = self.client.get("/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["status"], "active")

    def test_health(self):
        response = self.client.get("/health")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["status"], "healthy")

    def test_readiness(self):
        response = self.client.get("/ready")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["status"], "ready")

    def test_version(self):
        response = self.client.get("/version")

        self.assertEqual(response.status_code, 200)
        self.assertIn("version", response.get_json())
        self.assertIn("commit_sha", response.get_json())

    def test_metrics(self):
        response = self.client.get("/metrics")

        self.assertEqual(response.status_code, 200)
        self.assertIn(
            "paved_road_http_requests_total",
            response.get_data(as_text=True),
        )


if __name__ == "__main__":
    unittest.main()
