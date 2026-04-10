import pandas as pd

def main() -> None:
    print("Clean step placeholder. Add transformation logic here.")

def clean_data(df: pd.DataFrame, numeric_columns: list) -> pd.DataFrame:
    """Clean numeric columns by removing spaces and converting to numeric."""
    for col in numeric_columns:
        df[col] = (
            df[col]
            .astype(str)  # Ensure the column is treated as a string
            .str.replace(" ", "")  # Remove spaces
            .astype(float)  # Convert to numeric
        )
    return df

if __name__ == "__main__":
    main()
