#!/usr/bin/env python3
from __future__ import annotations
import subprocess, shlex
from typing import Tuple
class ExecError(Exception): pass
def run(cmd: str, timeout: int = 60) -> Tuple[int, str, str]:
    try:
        proc = subprocess.run(shlex.split(cmd), capture_output=True, text=True, timeout=timeout)
        return proc.returncode, proc.stdout, proc.stderr
    except subprocess.TimeoutExpired:
        raise ExecError(f"Timeout after {timeout}s: {cmd}")
