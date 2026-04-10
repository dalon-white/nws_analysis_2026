from pathlib import Path
import pandas as pd



file_path = Path("data/raw/mexico_cattle_data_2022.csv")

def load_csv(file_path: Path, encoding: str) -> pd.DataFrame:
    """Load data from a CSV file."""
    print(f"Loading data from file: {file_path}")
    df = pd.read_csv(file_path, encoding=encoding)
    return df

df = load_csv(file_path, encoding="latin1")

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

df = clean_data(df, df.columns[3:11])
df.head()
print(df.info())


def save_processed_data(df: pd.DataFrame, output_path: Path) -> None:
    """Save the cleaned DataFrame to a new CSV file."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(output_path, index=False)
    print(f"Processed data saved to: {output_path}")

output_path = Path("data/processed/mexico_cattle_data_2022_cleaned.csv")

save_processed_data(df, output_path)