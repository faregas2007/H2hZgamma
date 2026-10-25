"""Reader for the ampflow amplitude CSV format (see src/ampscan/csvout.h).

    # key: value        provenance lines (amplitude, backend, scan, mudim, models, inputs, slha, columns)
    s,re_finite,im_finite,re_div,im_div
    1.0e+03,...

finite = amplitude at Delta = 0,  div = coefficient of Delta (the UV pole).
"""
import csv
import glob
import os
import re
from dataclasses import dataclass, field

import numpy as np


@dataclass
class AmplitudeData:
    name: str
    meta: dict            # '# key: value' lines
    params: dict          # fixed inputs (the scan file's 'set' lines), name -> float
    slha: dict            # SLHA entries the amplitude read, "MASS[24]" -> float
    x_name: str           # name of the scanned variable (first column)
    x: np.ndarray
    re_finite: np.ndarray
    im_finite: np.ndarray
    re_div: np.ndarray
    im_div: np.ndarray

    @property
    def finite(self):
        return self.re_finite + 1j * self.im_finite

    @property
    def div(self):
        return self.re_div + 1j * self.im_div


def read(path):
    meta, data_lines = {}, []
    with open(path, newline="") as fh:
        for line in fh:
            if line.startswith("#"):
                key, _, value = line[1:].partition(":")
                meta[key.strip()] = value.strip()
            elif line.strip():
                data_lines.append(line)
    rows = list(csv.reader(data_lines))
    header, body = rows[0], rows[1:]
    if header[1:] != ["re_finite", "im_finite", "re_div", "im_div"]:
        raise ValueError(f"{path}: unexpected columns {header}")
    cols = np.array(body, dtype=float).T
    def pairs(key):
        out = {}
        for item in meta.get(key, "").split():
            k, _, v = item.partition("=")
            out[k] = float(v)
        return out
    return AmplitudeData(meta.get("amplitude", os.path.splitext(os.path.basename(path))[0]),
                         meta, pairs("inputs"), pairs("slha"), header[0], *cols)


_GREEK = {"alpha": "\u03b1", "beta": "\u03b2", "gamma": "\u03b3", "delta": "\u03b4", "epsilon": "\u03b5",
          "zeta": "\u03b6", "eta": "\u03b7", "theta": "\u03b8", "iota": "\u03b9", "kappa": "\u03ba",
          "lambda": "\u03bb", "mu": "\u03bc", "nu": "\u03bd", "xi": "\u03be", "rho": "\u03c1",
          "sigma": "\u03c3", "tau": "\u03c4", "phi": "\u03c6", "chi": "\u03c7", "psi": "\u03c8", "omega": "\u03c9",
          "Gamma": "\u0393", "Delta": "\u0394", "Theta": "\u0398", "Lambda": "\u039b", "Xi": "\u039e",
          "Sigma": "\u03a3", "Phi": "\u03a6", "Psi": "\u03a8", "Omega": "\u03a9"}


def pretty(text):
    """Display form of a name: the ASCII names the pipeline uses everywhere become Greek letters in plots
    ('alpha' -> the letter alpha). Files, CSV headers and generated code stay ASCII."""
    return re.sub(r"\b(" + "|".join(_GREEK) + r")\b", lambda m: _GREEK[m.group(1)], text)


def read_run(folder):
    """All amplitude CSVs of one run folder (manifest.csv and friends are skipped)."""
    paths = sorted(p for p in glob.glob(os.path.join(folder, "*.csv")) if os.path.basename(p) != "manifest.csv")
    return [read(p) for p in paths]
