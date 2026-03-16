from pathlib import Path


def main() -> None:
    raw_dir = Path("data/raw")
    processed_dir = Path("data/processed")
    processed_dir.mkdir(parents=True, exist_ok=True)
    print(f"Load step placeholder. Add ingestion logic from {raw_dir} to {processed_dir}.")


if __name__ == "__main__":
    main()
