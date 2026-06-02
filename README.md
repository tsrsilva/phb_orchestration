# PenoBees Pipeline Orchestration

## Purpose

This guide explains how to run the TaxReport, Phylo Parser, RDF Generator, and Query Service workflow using Docker Compose. It focuses on what to run, what each stage does, and where outputs are produced.

The pipeline runs in this order:

1. TaxReport
2. Phylo Parser
3. RDF Generator
4. Query Service

## What Is Orchestrated

The orchestration setup in this folder coordinates four containerized tools:

1. [TaxReport](https://github.com/tsrsilva/checker): species name checking against GBIF
2. [Phylo Parser](https://github.com/tsrsilva/phylo-parser): phenotype parsing and ontology mapping
3. [RDF Generator](https://github.com/tsrsilva/rdf-generator): RDF graph generation and SHACL validation
4. [Query Service](https://github.com/tsrsilva/query-service): RDF materialization and SPARQL query execution

Execution is controlled by `docker-compose.yml`, with helper scripts `orchestrate.sh` and `integrate.sh`.

### Service Name Mapping

| User-facing name | Compose service |
|---|---|
| TaxReport | tool1 |
| Phylo Parser | tool2 |
| RDF Generator | tool3 |
| Query Service | tool4 |

> Directory naming requirement for external users:\
> The orchestration expects sibling directories named exactly `tool1`, `tool2`, `tool3`, and `tool4`.
> If your folders use different names, update `docker-compose.yml` bind paths before running the pipeline.

## Folder Layout

The orchestration assets are centralized in:

- `docker-compose.yml`
- `orchestrate.sh`
- `integrate.sh`
- `INDEX.md`
- `QUICK_START.md`
- `ORCHESTRATION_PLAN.md`
- `DATA_FLOW.md`

The tool directories remain at the parent level:

- `../tool1`
- `../tool2`
- `../tool3`
- `../tool4`

## How Orchestration Works

### Service ordering

Docker Compose enforces stage ordering with dependencies:

1. Phylo Parser waits for TaxReport
2. RDF Generator waits for Phylo Parser
3. Query Service waits for RDF Generator

### Completion-gated sequencing

Stages are chained as batch jobs. A downstream stage starts only after the upstream stage exits successfully (`service_completed_successfully`).

Health checks are still defined for service validation but are not used as the stage-to-stage gate.

### Volumes

Each tool mounts its own input/output folders from the host. A shared volume (`pipeline-data`) is also available for cross-stage exchange.

## Running the Pipeline

Run commands from this folder:

```bash
cd [PATH]/orchestration
```

### Full pipeline

```bash
./orchestrate.sh full --build
```

Equivalent direct command:

```bash
docker compose --profile full-pipeline up --build
```

### Individual stages

```bash
./orchestrate.sh stage1
./orchestrate.sh stage2
./orchestrate.sh stage3
./orchestrate.sh stage4
```

### Partial pipeline (skip TaxReport)

```bash
./orchestrate.sh stage2-4
```

### Run one tool without dependencies

```bash
./orchestrate.sh tool2
```

## Data Handoffs Between Stages

The primary handoffs are:

1. Phylo Parser JSON outputs to RDF Generator inputs
2. RDF Generator RDF outputs to Query Service inputs

Use `integrate.sh` when explicit copying is needed:

```bash
./integrate.sh full
```

Or per handoff:

```bash
./integrate.sh tool2-to-tool3
./integrate.sh tool3-to-tool4
```

Validate integration readiness:

```bash
./integrate.sh validate
```

## Monitoring and Operations

### Status and logs

```bash
./orchestrate.sh status
./orchestrate.sh logs
./orchestrate.sh logs tool3
```

### Stop and cleanup

```bash
./orchestrate.sh stop
./orchestrate.sh clean
```

### Shell access

```bash
./orchestrate.sh shell tool1
```

## Output Locations

Pipeline outputs are written in each tool directory:

1. TaxReport: `../tool1/outputs`
2. Phylo Parser: `../tool2/output_json`, `../tool2/output_csv`, `../tool2/missing_uris`
3. RDF Generator: `../tool3/outputs`
4. Query Service: `../tool4/outputs`

## Typical External User Workflow

1. Ensure Docker and Docker Compose are available.
2. Confirm input data exists in each tool's expected data folder.
3. Run `./orchestrate.sh full --build`.
4. Monitor with `./orchestrate.sh logs`.
5. Verify outputs in the tool-specific output folders.
6. If needed, run `./integrate.sh full` and re-run downstream stages.

## Troubleshooting

### A stage does not start

Check dependency status and logs:

```bash
./orchestrate.sh status
./orchestrate.sh logs
```

### A health check fails

Inspect whether expected output files/directories were produced by the failing stage.

### Downstream stage has missing input

Run integration checks and copy steps:

```bash
./integrate.sh validate
./integrate.sh full
```

## Related Documentation

- [INDEX.md](INDEX.md)
- [QUICK_START.md](QUICK_START.md)
- [ORCHESTRATION_PLAN.md](ORCHESTRATION_PLAN.md)
- [DATA_FLOW.md](DATA_FLOW.md)
