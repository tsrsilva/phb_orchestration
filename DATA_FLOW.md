# Data Flow Guide

## Purpose

This document explains how data moves between TaxReport, Phylo Parser, RDF Generator, and Query Service, and what to check when integration fails.

## End-to-End Flow

1. TaxReport processes taxonomy input files and writes JSON reports.
2. Phylo Parser parses phenotype text and writes structured CSV/JSON outputs.
3. RDF Generator consumes phenotype data and matrix inputs, then writes RDF graphs and validation outputs.
4. Query Service consumes RDF and query definitions, then writes materialized RDF and CSV query results.

## Stage Inputs and Outputs

### Stage 1: TaxReport

Inputs:

1. ../tool1/data/raw/*.txt

Outputs:

1. ../tool1/outputs/*_taxa_output_report.json

### Stage 2: Phylo Parser

Inputs:

1. ../tool2/data/*.txt
2. ../tool2/dicts/*.json

Outputs:

1. ../tool2/output_csv/*.csv
2. ../tool2/output_json/*.json
3. ../tool2/missing_uris/*.csv

### Stage 3: RDF Generator

Inputs:

1. ../tool3/data/examples/*.json
2. ../tool3/data/**/*.nex
3. ../tool3/data/shapes/shapes.ttl
4. ../tool3/data/ontologies/*

Outputs:

1. ../tool3/outputs/combined_graphs/*.ttl
2. ../tool3/outputs/validation_reports/*

### Stage 4: Query Service

Inputs:

1. ../tool4/data/kb.ttl (or equivalent RDF input)
2. ../tool4/queries/*.sparql
3. ../tool4/data/ontologies/*

Outputs:

1. ../tool4/outputs/materialized.ttl
2. ../tool4/outputs/*.csv

## Integration Checkpoints

### Checkpoint A: Phylo Parser -> RDF Generator

Expected handoff:

1. ../tool2/output_json/*.json -> ../tool3/data/examples/

Manual copy:

```bash
cp ../tool2/output_json/*.json ../tool3/data/examples/
```

Validation:

```bash
./integrate.sh validate
```

### Checkpoint B: RDF Generator -> Query Service

Expected handoff:

1. ../tool3/outputs/combined_graphs/all_combined.ttl -> ../tool4/data/kb.ttl

Manual copy:

```bash
cp ../tool3/outputs/combined_graphs/all_combined.ttl ../tool4/data/kb.ttl
```

Validation:

```bash
./integrate.sh validate
```

## Recommended Integration Command

From orchestration folder:

```bash
./integrate.sh full
```

## Common Failure Patterns

1. Missing upstream outputs
Cause: previous stage failed or did not run.
Check: stage logs and output directories.

2. Output present but downstream not using it
Cause: config points to different input paths.
Check: tool config files and expected input filenames.

3. RDF parse issues in Query Service
Cause: invalid or incomplete TTL handoff.
Check: whether kb.ttl exists and is complete.

## Minimal Debug Workflow

```bash
./orchestrate.sh status
./orchestrate.sh logs
./integrate.sh validate
```

If needed, re-run affected stages:

```bash
./orchestrate.sh stage3
./orchestrate.sh stage4
```

## Related Documents

1. [README.md](README.md)
2. [QUICK_START.md](QUICK_START.md)
3. [ORCHESTRATION_PLAN.md](ORCHESTRATION_PLAN.md)
