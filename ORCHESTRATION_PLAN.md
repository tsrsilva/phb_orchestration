# Orchestration Plan

## Scope

This document defines how TaxReport, Phylo Parser, RDF Generator, and Query Service are orchestrated with Docker Compose from the orchestration folder.

Run from:

```bash
cd /home/thiagosa/Projects/orchestration
```

## Pipeline Stages

1. Stage 1: TaxReport
Purpose: species name matching against GBIF.
Inputs: ../tool1/data/raw/*.txt
Outputs: ../tool1/outputs/*.json
Container command: python checker/main.py

2. Stage 2: Phylo Parser
Purpose: parse phenotype text and map ontology terms.
Inputs: ../tool2/data/*.txt, ../tool2/dicts/*
Outputs: ../tool2/output_csv/*, ../tool2/output_json/*, ../tool2/missing_uris/*
Container command: python -m phylo_parser

3. Stage 3: RDF Generator
Purpose: convert parsed data to RDF and validate with SHACL.
Inputs: ../tool3/data/*, optionally JSON produced by tool2
Outputs: ../tool3/outputs/combined_graphs/*, ../tool3/outputs/validation_reports/*
Container command: python rdf_generator/main.py

4. Stage 4: Query Service
Purpose: materialize RDF and execute SPARQL queries.
Inputs: ../tool4/data/*, ../tool4/queries/*
Outputs: ../tool4/outputs/materialized.ttl and query CSV files
Container command: python src/main.py

## Execution Model

Service startup is sequential through Compose dependencies:

1. Phylo Parser depends on TaxReport
2. RDF Generator depends on Phylo Parser
3. Query Service depends on RDF Generator

Service startup is completion-gated for stepwise batch execution. Downstream stages start only after upstream stages complete successfully.

## Profiles

Available Compose profiles:

1. full-pipeline
2. stage1
3. stage2
4. stage3
5. stage4
6. stage2-4

Examples:

```bash
docker compose --profile full-pipeline up --build
docker compose --profile stage3 up --build
```

## Operational Commands

Preferred helper script:

```bash
./orchestrate.sh full --build
./orchestrate.sh stage2
./orchestrate.sh logs
./orchestrate.sh status
./orchestrate.sh stop
./orchestrate.sh clean
```

Direct Compose usage:

```bash
docker compose --profile full-pipeline up --build
docker compose logs -f
docker compose ps
docker compose down
```

## Data Handoff Strategy

Primary handoffs:

1. Phylo Parser output_json -> RDF Generator data/examples
2. RDF Generator combined_graphs -> Query Service data/kb.ttl

If handoffs are not already configured through input paths, use:

```bash
./integrate.sh full
```

Validation:

```bash
./integrate.sh validate
```

## Volumes

1. Tool-specific host mounts are used for each stage's input/output directories.
2. Shared volume pipeline-data is mounted in all services for optional cross-stage exchange.

## Monitoring and Debugging

```bash
./orchestrate.sh logs
./orchestrate.sh logs tool4
./orchestrate.sh status
```

For deeper debugging:

```bash
docker compose exec tool3 bash
docker compose logs --tail 100 tool3
```

## Failure Handling

If a stage fails:

1. Inspect logs for the failing service.
2. Confirm expected input files are present.
3. Confirm expected upstream outputs were produced.
4. Re-run the failed stage or downstream stages after correction.

## Cleanup

```bash
./orchestrate.sh stop
./orchestrate.sh clean
```

Or directly:

```bash
docker compose down
docker compose --profile full-pipeline down -v
```

## Related Documents

1. [README.md](README.md)
2. [QUICK_START.md](QUICK_START.md)
3. [DATA_FLOW.md](DATA_FLOW.md)
