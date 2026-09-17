"""Tests for bin/flatcar-sysext-update."""

import hashlib
import importlib.machinery
import importlib.util
import json
import subprocess
from pathlib import Path
from types import ModuleType
from typing import Any

import pytest
import ruamel.yaml

SCRIPT = Path(__file__).parent.parent / "flatcar-sysext-update"


def load_module() -> ModuleType:
    loader = importlib.machinery.SourceFileLoader("flatcar_sysext_update", str(SCRIPT))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    assert spec is not None
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


flatcar_sysext_update = load_module()


def fake_gh(*args: str) -> str:
    """Stand in for the gh CLI, supports only gh release download"""
    arg_list = list(args)
    assert arg_list[:2] == ["release", "download"], f"unexpected gh call: {arg_list}"

    dest = Path(arg_list[arg_list.index("--dir") + 1])
    dest.mkdir(parents=True, exist_ok=True)
    patterns = [arg_list[i + 1] for i, a in enumerate(arg_list) if a == "--pattern"]
    raw_name = next(p for p in patterns if p.endswith(".raw"))

    content = f"content-for-{raw_name}".encode()
    (dest / raw_name).write_bytes(content)
    checksum = hashlib.sha256(content).hexdigest()
    (dest / "SHA256SUMS").write_text(f"{checksum}  {raw_name}\n")
    return ""


def fake_subprocess_run(
    args: list[str], *a: Any, **kw: Any
) -> subprocess.CompletedProcess[str]:
    """Stub for ssubprocess run, supports only unsquashfs and syft"""
    if args[0] == "unsquashfs":
        Path(args[2]).mkdir(parents=True, exist_ok=True)
    elif args[0] == "syft":
        stdout = kw.get("stdout")
        if stdout is not None:
            stdout.write("{}")
    else:
        raise AssertionError(f"unexpected subprocess.run call: {args}")
    return subprocess.CompletedProcess(args, 0)


def fake_cosign_sign_and_verify(path: Path) -> Path:
    """Stub for cosign sign and bundle"""
    bundle = path.with_name(path.name + ".cosign.bundle")
    bundle.write_text("bundle")
    return bundle


@pytest.fixture(autouse=True)
def stub_external_tools(monkeypatch: pytest.MonkeyPatch) -> None:
    """Stub out everything that talks to a real external system"""
    monkeypatch.setattr(flatcar_sysext_update, "gh", fake_gh)
    monkeypatch.setattr(flatcar_sysext_update.subprocess, "run", fake_subprocess_run)
    monkeypatch.setattr(
        flatcar_sysext_update, "cosign_sign_and_verify", fake_cosign_sign_and_verify
    )
    monkeypatch.setattr(flatcar_sysext_update, "s3_client", lambda: None)
    # Pin the flatcar image versions to whatever is already on disk, so refresh_image
    # is a no-op and the test can focus purely on the sysext version bookkeeping.
    monkeypatch.setattr(
        flatcar_sysext_update, "latest_flatcar_version", lambda arch: "9999.0.0"
    )
    monkeypatch.delenv("FORCE_REFRESH", raising=False)


def write_versions_file(path: Path, data: dict[str, Any]) -> None:
    """Helper function to write the versions file."""
    yaml = ruamel.yaml.YAML(typ="rt")
    with path.open("w") as f:
        yaml.dump(data, f)


def read_versions_file(path: Path) -> dict[str, Any]:
    """Helper function to read the versions file."""
    yaml = ruamel.yaml.YAML(typ="safe")
    with path.open() as f:
        result: dict[str, Any] = yaml.load(f)
    return result


def run_main(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
    initial_data: dict[str, Any],
    tags: list[str],
) -> dict[str, Any]:
    """Run the main machinery, using the stubbed versions."""
    versions_file = tmp_path / "sysext-versions.yaml"
    write_versions_file(versions_file, initial_data)
    monkeypatch.setattr(flatcar_sysext_update, "VERSIONS_FILE", versions_file)
    monkeypatch.setattr(flatcar_sysext_update, "sysext_bakery_tags", lambda: tags)

    github_output = tmp_path / "github_output.txt"
    monkeypatch.setenv("GITHUB_OUTPUT", str(github_output))

    flatcar_sysext_update.main()

    result = {"versions": read_versions_file(versions_file)}
    if github_output.exists():
        line = github_output.read_text().strip()
        if line:
            result["pr"] = json.loads(line.removeprefix("pr="))
    return result


def containerd_arch_entry(version: str) -> dict[str, dict[str, str]]:
    """Generate a fake containerd entry."""
    bakery_suffix = flatcar_sysext_update.ARCH_TO_BAKERY_SUFFIX
    return {
        arch: {
            "url": f"https://example/containerd-{version}-{bakery_suffix[arch]}.raw",
            "checksum_sha512": "sha512-old",
            "sbom_url": f"https://example/containerd-{version}-{bakery_suffix[arch]}-sbom.json",
            "cosign_bundle_url": f"https://example/containerd-{version}-{bakery_suffix[arch]}.cosign.bundle",
        }
        for arch in ("x86_64", "aarch64")
    }


def base_versions_data(containerd_version: str) -> dict[str, Any]:
    """Generate fake version data."""
    return {
        "image": {
            "x86_64": {"version": "9999.0.0"},
            "aarch64": {"version": "9999.0.0"},
        },
        "sysexts": {
            "containerd": {
                "version": containerd_version,
                **containerd_arch_entry(containerd_version),
            },
            "kubernetes": {},
        },
    }


def test_containerd_update_applies_to_both_architectures(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    """Regression test for #513: a version bump must update every arch, not just the first one processed."""
    initial_data = base_versions_data("2.3.5")

    result = run_main(tmp_path, monkeypatch, initial_data, tags=["containerd-2.4.0"])

    containerd = result["versions"]["sysexts"]["containerd"]
    assert containerd["version"] == "2.4.0"
    assert "2.4.0" in containerd["x86_64"]["url"]
    assert "2.4.0" in containerd["aarch64"]["url"]

    assert "pr" in result, result
    body = result["pr"]["body"]
    assert "containerd sysext (x86_64) -> 2.4.0" in body
    assert "containerd sysext (aarch64) -> 2.4.0" in body
