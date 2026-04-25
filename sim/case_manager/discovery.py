import os
import importlib.util
import sys

from .base import Build, Test


def discover(test_dir):
    """Scan test_dir for .py files, import them, return all Build/Test subclasses.

    Returns:
        dict: {"builds": {name: class}, "tests": {name: class}}
    """
    builds = {}
    tests = {}

    if not os.path.isdir(test_dir):
        raise FileNotFoundError(f"Test directory not found: {test_dir}")

    for fname in sorted(os.listdir(test_dir)):
        if not fname.endswith(".py") or fname.startswith("_"):
            continue

        fpath = os.path.join(test_dir, fname)
        module_name = fname[:-3]

        spec = importlib.util.spec_from_file_location(module_name, fpath)
        module = importlib.util.module_from_spec(spec)
        sys.modules[module_name] = module
        spec.loader.exec_module(module)

        for attr_name in dir(module):
            obj = getattr(module, attr_name)
            if isinstance(obj, type) and issubclass(obj, Build) and obj is not Build:
                if obj.name:
                    builds[obj.name] = obj
            if isinstance(obj, type) and issubclass(obj, Test) and obj is not Test:
                if obj.name:
                    tests[obj.name] = obj

    return {"builds": builds, "tests": tests}


def filter_tests(all_tests, case_name=None, tag=None):
    """Filter tests by case name or tag.

    Args:
        all_tests: dict of {name: TestClass}
        case_name: specific test name to match
        tag: tag to match (any test with this tag in its tag list)

    Returns:
        dict of matching {name: TestClass}
    """
    if case_name:
        if case_name in all_tests:
            return {case_name: all_tests[case_name]}
        matches = {}
        for name, cls in all_tests.items():
            if name.endswith(f".{case_name}"):
                matches[name] = cls
        return matches

    if tag:
        return {
            name: cls for name, cls in all_tests.items()
            if tag in getattr(cls, "tag", [])
        }

    return all_tests
