# Quick Start

This reference covers the most common commands to run and monitor the four-stage pipeline made up of TaxReport, Phylo Parser, RDF Generator, and Query Service.

## Prerequisites

1. Docker is installed and running.
2. Docker Compose is available.
3. Input data is present in the expected tool directories.

## Run Location

Run commands from:

```bash
cd /home/thiagosa/Projects/orchestration
```

## Start the Full Pipeline

Preferred command:

```bash
./orchestrate.sh full --build
```

Equivalent Docker Compose command:

```bash
docker compose --profile full-pipeline up --build
```

## Common Commands

### Using orchestrate.sh

```bash
./orchestrate.sh full
./orchestrate.sh stage1
./orchestrate.sh stage2
./orchestrate.sh stage3
./orchestrate.sh stage4
./orchestrate.sh stage2-4

./orchestrate.sh logs
./orchestrate.sh logs tool3
./orchestrate.sh status
./orchestrate.sh stop
./orchestrate.sh clean
./orchestrate.sh shell tool1
```

### Using Docker Compose directly

```bash
docker compose --profile full-pipeline up --build
docker compose --profile stage1 up --build
docker compose --profile stage2 up --build
docker compose --profile stage3 up --build
docker compose --profile stage4 up --build
docker compose --profile stage2-4 up --build

docker compose logs -f
docker compose ps
docker compose down
docker compose --profile full-pipeline down -v
```

## Pipeline Order

1. TaxReport (taxonomy checking)
2. Phylo Parser (phenotype parsing)
3. RDF Generator (RDF generation and validation)
4. Query Service (materialization and SPARQL queries)

## Data Handoffs

If outputs are not already wired by configuration, run:

```bash
./integrate.sh full
```

Or per stage handoff:

```bash
./integrate.sh tool2-to-tool3
./integrate.sh tool3-to-tool4
```

## Where Outputs Are Written

1. ../tool1/outputs
2. ../tool2/output_csv, ../tool2/output_json, ../tool2/missing_uris
3. ../tool3/outputs
4. ../tool4/outputs

## Troubleshooting Basics

```bash
./orchestrate.sh status
./orchestrate.sh logs
./orchestrate.sh logs tool2
./integrate.sh validate
```

For more detail, see [ORCHESTRATION_PLAN.md](ORCHESTRATION_PLAN.md) and [DATA_FLOW.md](DATA_FLOW.md).
