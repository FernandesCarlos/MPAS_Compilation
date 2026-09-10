import json
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class Era5RequestTest(unittest.TestCase):
    def load(self, name):
        return json.loads((ROOT / "cases/first-global-240km/era5" / name).read_text())

    def test_pressure_request_uses_official_baseline(self):
        doc = self.load("pressure-levels.json")
        req = doc["request"]
        self.assertEqual(doc["baseline_timestamp"], "2014-09-10T00:00:00Z")
        self.assertEqual(req["year"], ["2014"])
        self.assertEqual(req["month"], ["09"])
        self.assertEqual(req["day"], ["10"])
        self.assertEqual(req["time"], ["00:00"])
        self.assertNotIn("area", req)
        self.assertEqual(len(req["pressure_level"]), 37)

    def test_single_request_has_required_surface_fields_and_is_global(self):
        doc = self.load("single-levels.json")
        req = doc["request"]
        self.assertEqual(doc["baseline_timestamp"], "2014-09-10T00:00:00Z")
        self.assertNotIn("area", req)
        for variable in (
            "land_sea_mask",
            "sea_ice_cover",
            "skin_temperature",
            "soil_temperature_level_4",
            "volumetric_soil_water_layer_4",
        ):
            self.assertIn(variable, req["variable"])


if __name__ == "__main__":
    unittest.main()
