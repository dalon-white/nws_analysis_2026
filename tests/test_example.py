from pathlib import Path


def test_required_directories_exist():
    assert Path("src").exists()
    assert Path("notebooks/exploration").exists()
    assert Path("notebooks/analysis").exists()
    assert Path("notebooks/archive").exists()
