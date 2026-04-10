from pathlib import Path
import pandas as pd
import os


def main() -> None:
    raw_dir = Path("data/raw")
    processed_dir = Path("data/processed")
    processed_dir.mkdir(parents=True, exist_ok=True)

    # Example usage of load_csv
    file_path = raw_dir / "example_data.csv"  # Replace with the desired file name
    print(f"Loading data from: {file_path}")
    data = load_csv(file_path)
    print(data.head())

def load_csv(file_path: Path) -> pd.DataFrame:
    """Load data from a CSV file."""
    print(f"Loading data from file: {file_path}")
    df = pd.read_csv(file_path)
    return df

if __name__ == "__main__":
    main()

