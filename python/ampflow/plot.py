#!/usr/bin/env python3
"""Plot every amplitude CSV of a run folder (PYTHONPATH must contain the repository's python/ folder).

    python -m ampflow.plot data/sm/demo [-o plots/sm/demo] [--logx] [--format png|pdf|svg] [--dpi 150]

Per amplitude  <name>.png : a 2x2 grid
                            Re / Im of the finite part (Delta = 0)   -- top row
                            Re / Im of the divergent part (coefficient of Delta) -- bottom row
and one overview.png with all amplitudes (finite | divergent, Re solid, Im dashed).
"""
import argparse
import os
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

from . import csvio  # noqa: E402

RE, IM = "#2a78d6", "#eb6834"


def style(ax, xlabel, logx):
    ax.grid(True, color="#e1e0d9", lw=0.8)
    for side in ("top", "right"):
        ax.spines[side].set_visible(False)
    ax.set_xlabel(xlabel)
    if logx:
        ax.set_xscale("log")


def subtitle(a):
    fixed = ", ".join(f"{csvio.pretty(k)}={v:.5g}" for k, v in a.params.items())
    parts = [f"{a.meta.get('backend', '?')} backend", f"{csvio.pretty('mu')}\u00b2={float(a.meta.get('mudim', 'nan')):.5g}",
             f"{len(a.slha)} SLHA entries"]
    if fixed:
        parts.append(fixed)
    return "   |   ".join(parts)


def plot_one(a, logx):
    fig, axes = plt.subplots(2, 2, figsize=(10, 6.4), sharex=True)
    panels = [(axes[0][0], a.re_finite, RE, "Re  finite part  (Delta = 0)"),
              (axes[0][1], a.im_finite, IM, "Im  finite part"),
              (axes[1][0], a.re_div, RE, "Re  divergent part  (coefficient of Delta)"),
              (axes[1][1], a.im_div, IM, "Im  divergent part")]
    for ax, y, color, title in panels:
        ax.plot(a.x, y, color=color, lw=1.8)
        ax.set_title(title, fontsize=10)
        style(ax, csvio.pretty(a.x_name) if ax in axes[1] else "", logx)
    fig.suptitle(a.name, fontsize=13, fontweight="bold")
    fig.text(0.5, 0.005, subtitle(a), ha="center", fontsize=7.5, color="#555555")
    fig.tight_layout(rect=(0, 0.02, 1, 0.97))
    return fig


def plot_overview(amps, logx):
    n = len(amps)
    fig, axes = plt.subplots(n, 2, figsize=(11, 2.7 * n + 0.6), squeeze=False)
    for row, a in enumerate(amps):
        for col, (re, im, what) in enumerate([(a.re_finite, a.im_finite, "finite (Delta = 0)"),
                                              (a.re_div, a.im_div, "divergent (coefficient of Delta)")]):
            ax = axes[row][col]
            ax.plot(a.x, re, color=RE, lw=1.6, label="Re")
            ax.plot(a.x, im, color=IM, lw=1.6, ls="--", label="Im")
            ax.set_title(f"{a.name}: {what}", fontsize=9.5)
            style(ax, csvio.pretty(a.x_name) if row == n - 1 else "", logx)
            if row == 0 and col == 1:
                ax.legend(frameon=False, loc="best")
    fig.tight_layout()
    return fig


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("run_dir", help="folder written by ampscan, e.g. data/demo")
    ap.add_argument("-o", "--out", default=None, help="output folder (default: plots/<run name> next to cwd)")
    ap.add_argument("--logx", action="store_true", help="logarithmic x axis")
    ap.add_argument("--format", default="png", choices=["png", "pdf", "svg"])
    ap.add_argument("--dpi", type=int, default=150)
    args = ap.parse_args()

    amps = csvio.read_run(args.run_dir)
    if not amps:
        sys.exit(f"ampflow.plot: no amplitude CSVs in {args.run_dir}")
    out = args.out or os.path.join("plots", os.path.basename(os.path.normpath(args.run_dir)))
    os.makedirs(out, exist_ok=True)

    for a in amps:
        path = os.path.join(out, f"{a.name}.{args.format}")
        fig = plot_one(a, args.logx)
        fig.savefig(path, dpi=args.dpi)
        plt.close(fig)
        print(f"ampflow.plot: {path}")
    path = os.path.join(out, f"overview.{args.format}")
    fig = plot_overview(amps, args.logx)
    fig.savefig(path, dpi=args.dpi)
    plt.close(fig)
    print(f"ampflow.plot: {path}")


if __name__ == "__main__":
    main()
