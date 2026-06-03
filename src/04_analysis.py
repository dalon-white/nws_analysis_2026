from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
import squarify


PROCESSED_DATA_PATH = Path("data/processed/rejections_at_risk.csv")
TREEMAP_DATA_OUTPUT_PATH = Path("outputs/tables/rejections_by_port_all_years.csv")
TREEMAP_FIGURE_OUTPUT_PATH = Path("outputs/figures/rejections_by_port_treemap.png")


def build_port_rejections_treemap() -> pd.DataFrame:
    rejections = pd.read_csv(PROCESSED_DATA_PATH)

    required_columns = {"port", "year", "reason_rejected", "volume"}
    missing_columns = required_columns - set(rejections.columns)
    if missing_columns:
        missing = ", ".join(sorted(missing_columns))
        raise ValueError(f"Missing required columns in {PROCESSED_DATA_PATH}: {missing}")

    rejections_by_port = (
        rejections.groupby("port", as_index=False)["volume"]
        .sum()
        .sort_values("volume", ascending=False)
    )

    plotted_rejections = rejections_by_port[rejections_by_port["volume"] > 0].copy()
    if plotted_rejections.empty:
        raise ValueError("No positive rejection totals found for treemap plotting.")

    TREEMAP_DATA_OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    rejections_by_port.to_csv(TREEMAP_DATA_OUTPUT_PATH, index=False)

    labels = [
        f"{port.replace('_', ' ').title()}\n{int(volume):,}"
        for port, volume in zip(plotted_rejections["port"], plotted_rejections["volume"])
    ]

    plt.figure(figsize=(14, 8))
    squarify.plot(
        sizes=plotted_rejections["volume"],
        label=labels,
        color=plt.cm.Reds(
            plotted_rejections["volume"] / plotted_rejections["volume"].max()
        ),
        alpha=0.9,
        text_kwargs={"fontsize": 14, "fontweight": "bold"},
    )
    plt.axis("off")
    plt.title(
        "Total Cattle Rejections by Port\n(All Reasons, All Years)",
        fontsize=20,
        fontweight="bold",
        pad=16,
    )
    plt.figtext(
        0.01,
        0.01,
        "Source: data/processed/rejections_at_risk.csv; values are summed across all years and rejection reasons.",
        ha="left",
        fontsize=12,
    )

    TREEMAP_FIGURE_OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(TREEMAP_FIGURE_OUTPUT_PATH, dpi=300, bbox_inches="tight")
    plt.close()

    return rejections_by_port


def main() -> None:
    rejections_by_port = build_port_rejections_treemap()
    print(
        f"Treemap saved to {TREEMAP_FIGURE_OUTPUT_PATH} using {len(rejections_by_port)} ports."
    )
    print(f"Aggregated table saved to {TREEMAP_DATA_OUTPUT_PATH}.")


if __name__ == "__main__":
    main()
