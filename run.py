import click
from subprocess import run


@click.group()
def cli():
    """Pipeline runner for this analysis."""


@cli.command()
def all():
    for task in ["data", "process", "model", "analysis", "report"]:
        run(["make", task], check=True)


@cli.command()
def data():
    run(["make", "data"], check=True)


@cli.command()
def process():
    run(["make", "process"], check=True)


@cli.command()
def model():
    run(["make", "model"], check=True)


@cli.command()
def analysis():
    run(["make", "analysis"], check=True)


@cli.command()
def report():
    run(["make", "report"], check=True)


@cli.command()
def archive():
    run(["make", "archive"], check=True)


if __name__ == "__main__":
    cli()
