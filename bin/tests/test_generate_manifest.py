import json
import os
import subprocess
from pathlib import Path
from typing import Any

import pytest

SCRIPT = Path(__file__).parent.parent / "generate-manifest"


def run_generate_manifest(
    tmp_path: Path,
    build_outputs: dict[str, Any],
    *,
    env_overrides: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    build_outputs_file = tmp_path / "build-outputs.json"
    manifest_file = tmp_path / "manifest.json"
    build_outputs_file.write_text(json.dumps(build_outputs))

    env = dict(os.environ)
    env["BUILD_OUTPUTS_FILE"] = str(build_outputs_file)
    env["MANIFEST_FILE"] = str(manifest_file)
    if env_overrides is not None:
        env = env_overrides

    return subprocess.run(
        [str(SCRIPT)], env=env, capture_output=True, text=True, check=False
    )


def generate_manifest(tmp_path: Path, build_outputs: dict[str, Any]) -> dict[str, Any]:
    result = run_generate_manifest(tmp_path, build_outputs)
    assert result.returncode == 0, result.stderr
    manifest_file = tmp_path / "manifest.json"
    manifest: dict[str, Any] = json.loads(manifest_file.read_text())
    return manifest


def test_datastructure_invert(tmp_path: Path) -> None:
    """Test the basic inversion of the data structure"""
    build_outputs = {
        "name": {"image-a": "image-a", "image-b": "image-b"},
        "source-image": {"image-a": "source-a", "image-b": "source-b"},
        "target-image": {"image-a": "target-a", "image-b": "target-b"},
    }

    manifest = generate_manifest(tmp_path, build_outputs)

    assert manifest == {
        "image-a": {
            "name": "image-a",
            "source-image": "source-a",
            "target-image": "target-a",
            "properties": [],
        },
        "image-b": {
            "name": "image-b",
            "source-image": "source-b",
            "target-image": "target-b",
            "properties": [],
        },
    }


def test_datastructure_invert_2(tmp_path: Path) -> None:
    "Test datastructure invert with multiple keys"
    build_outputs = {
        "name": {"image-a": "image-a", "image-b": "image-b"},
        "source-image": {"image-a": "source-a", "image-b": "source-b"},
        "manifest-extra": {
            "image-a": {"os_distro": "ubuntu"},
            "image-b": {"os_distro": "rocky"},
        },
    }

    manifest = generate_manifest(tmp_path, build_outputs)

    assert manifest["image-a"] == {
        "name": "image-a",
        "source-image": "source-a",
        "properties": ["os_distro=ubuntu"],
    }
    assert manifest["image-b"] == {
        "name": "image-b",
        "source-image": "source-b",
        "properties": ["os_distro=rocky"],
    }


def test_properties_passthrough(tmp_path: Path) -> None:
    """Test that image properties are correctly passed through."""
    build_outputs = {
        "name": {"image-a": "image-a"},
        "manifest-extra": {
            "image-a": {
                "hw_architecture": "x86_64",
                "os_distro": "ubuntu",
                "os_version": "22.04",
            },
        },
    }

    manifest = generate_manifest(tmp_path, build_outputs)

    # PROPERTY_KEYS is a set, so the order of entries in "properties" isn't guaranteed
    assert set(manifest["image-a"]["properties"]) == {
        "hw_architecture=x86_64",
        "os_distro=ubuntu",
        "os_version=22.04",
    }


def test_manifest_extra_other_keys_are_merged_directly(tmp_path: Path) -> None:
    """Test that other extra keys are passed through directly and not
    merged into properties"""
    build_outputs = {
        "name": {"image-a": "image-a"},
        "manifest-extra": {
            "image-a": {"hw_architecture": "x86_64", "description": "some image"},
        },
    }

    manifest = generate_manifest(tmp_path, build_outputs)

    assert manifest["image-a"]["properties"] == ["hw_architecture=x86_64"]
    assert manifest["image-a"]["description"] == "some image"


def test_kubernetes_version_is_kept_and_added_as_a_property(tmp_path: Path) -> None:
    """Test that kubernetes_version is passed through directly and added
    to properties as kube_version."""
    build_outputs = {
        "name": {"image-a": "image-a"},
        "manifest-extra": {
            "image-a": {"kubernetes_version": "1.30.0"},
        },
    }

    manifest = generate_manifest(tmp_path, build_outputs)

    assert manifest["image-a"]["kubernetes_version"] == "1.30.0"
    assert manifest["image-a"]["properties"] == ["kube_version=1.30.0"]


def test_empty_build_outputs_produces_empty_manifest(tmp_path: Path) -> None:
    """Test the no-op case."""
    manifest = generate_manifest(tmp_path, {"name": {}})

    assert manifest == {}


@pytest.mark.parametrize("missing_var", ["BUILD_OUTPUTS_FILE", "MANIFEST_FILE"])
def test_missing_required_env_var_fails(tmp_path: Path, missing_var: str) -> None:
    """Test that missing an env var fails."""
    build_outputs_file = tmp_path / "build-outputs.json"
    manifest_file = tmp_path / "manifest.json"
    build_outputs_file.write_text(json.dumps({}))

    env = dict(os.environ)
    env["BUILD_OUTPUTS_FILE"] = str(build_outputs_file)
    env["MANIFEST_FILE"] = str(manifest_file)
    del env[missing_var]

    result = run_generate_manifest(tmp_path, {}, env_overrides=env)

    assert result.returncode != 0
    assert "KeyError" in result.stderr
    assert missing_var in result.stderr
