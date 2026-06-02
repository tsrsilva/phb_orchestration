# Orchestration Documentation Index

This folder contains the orchestration setup and documentation for the TaxReport, Phylo Parser, RDF Generator, and Query Service pipeline.

## Start Here

For most users, start with [README.md](README.md).

## Document Guide

1. [README.md](README.md)
Purpose: High-level explanation for external users.
Use when: You want to understand what runs, in what order, and how to execute it.

2. [QUICK_START.md](QUICK_START.md)
Purpose: Short command reference.
Use when: You already understand the flow and need commands quickly.

3. [ORCHESTRATION_PLAN.md](ORCHESTRATION_PLAN.md)
Purpose: Detailed operational plan and runtime behavior.
Use when: You need implementation-level orchestration details.

4. [DATA_FLOW.md](DATA_FLOW.md)
Purpose: Stage-by-stage inputs, outputs, and integration checkpoints.
Use when: You need to troubleshoot data handoffs between tools.

## Runtime Files

1. [docker-compose.yml](docker-compose.yml)
Master Docker Compose definition for all stages.

2. [orchestrate.sh](orchestrate.sh)
Helper script to run full pipeline, stages, logs, and maintenance commands.

3. [integrate.sh](integrate.sh)
Helper script for explicit data handoffs between stage outputs and inputs.

## Tool Directories

Tool code and data live outside this folder:

1. [../tool1](https://github.com/tsrsilva/checker)
2. [../tool2](https://github.com/tsrsilva/phylo-parser)
3. [../tool3](https://github.com/tsrsilva/rdf-generator)
4. [../tool4](https://github.com/tsrsilva/query-service)

## Typical Usage Path

1. Read [README.md](README.md).
2. Run `./orchestrate.sh full --build` from this folder.
3. Monitor with `./orchestrate.sh logs`.
4. Validate handoffs with `./integrate.sh validate` when needed.
