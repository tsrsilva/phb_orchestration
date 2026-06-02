#!/bin/bash
# Data Integration Script
# Automatically copies outputs from one stage to inputs of the next stage
#
# Usage from orchestration/ directory: ./integrate.sh full
# Usage from parent directory: ./orchestration/integrate.sh full

set -e

# Find the orchestration directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECTS_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Helper functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check if directory exists
check_dir() {
    if [[ ! -d "$1" ]]; then
        print_error "Directory not found: $1"
        return 1
    fi
    return 0
}

# Check if files exist in directory
check_files() {
    local dir=$1
    local pattern=$2
    if ! ls "$dir"/$pattern 1> /dev/null 2>&1; then
        print_error "No files matching '$pattern' in $dir"
        return 1
    fi
    return 0
}

# Integrate Phylo Parser outputs to RDF Generator input characters
integrate_tool2_to_tool3() {
    print_header "Integrating Phylo Parser → RDF Generator (input character JSON)"
    
    # Source and destination (relative to PROJECTS_DIR)
    source_dir="$PROJECTS_DIR/tool2/output_json"
    dest_dir="$PROJECTS_DIR/tool3/data/examples"
    
    # Check source
    if ! check_dir "$source_dir"; then
        print_error "Phylo Parser outputs not found. Has Phylo Parser been run yet?"
        print_info "Run: cd '$SCRIPT_DIR' && ./orchestrate.sh tool2"
        return 1
    fi
    
    # Check for JSON files
    if ! check_files "$source_dir" "*.json"; then
        print_error "No JSON files found in Phylo Parser outputs"
        return 1
    fi
    
    # Create destination if needed
    mkdir -p "$dest_dir"
    
    # Copy files
    print_info "Copying JSON files from Phylo Parser to RDF Generator examples..."
    cp "$source_dir"/*.json "$dest_dir/" 2>/dev/null || true
    
    # Verify
    local count=$(ls "$dest_dir"/*.json 2>/dev/null | wc -l)
    if [[ $count -gt 0 ]]; then
        print_success "Copied $count JSON files to RDF Generator"
        return 0
    else
        print_error "No JSON files were copied"
        return 1
    fi
}

# Integrate RDF Generator outputs to Query Service
integrate_tool3_to_tool4() {
    print_header "Integrating RDF Generator → Query Service (RDF outputs)"
    
    # Source and destination (relative to PROJECTS_DIR)
    source_dir="$PROJECTS_DIR/tool3/outputs/combined_graphs"
    dest_dir="$PROJECTS_DIR/tool4/data"
    dest_file="$dest_dir/kb.ttl"
    
    # Check source
    if ! check_dir "$source_dir"; then
        print_error "RDF Generator outputs not found. Has RDF Generator been run yet?"
        print_info "Run: cd '$SCRIPT_DIR' && ./orchestrate.sh tool3"
        return 1
    fi
    
    # Check for TTL files
    if ! check_files "$source_dir" "*.ttl"; then
        print_error "No TTL files found in RDF Generator outputs"
        return 1
    fi
    
    # Create destination if needed
    mkdir -p "$dest_dir"
    
    # Copy main combined file
    print_info "Copying RDF files from RDF Generator to Query Service..."
    
    if [[ -f "$source_dir/all_combined.ttl" ]]; then
        cp "$source_dir/all_combined.ttl" "$dest_file"
        print_success "Copied all_combined.ttl to tool4/data/kb.ttl"
        return 0
    else
        print_error "all_combined.ttl not found in RDF Generator outputs"
        return 1
    fi
}

# Full integration workflow
full_integration() {
    print_header "Full Integration Workflow"
    print_info "Working directory: $PROJECTS_DIR"
    
    local failed=0
    
    print_info "Step 1: Integrating Phylo Parser → RDF Generator"
    integrate_tool2_to_tool3 || ((failed++))
    
    print_info "Step 2: Integrating RDF Generator → Query Service"
    integrate_tool3_to_tool4 || ((failed++))
    
    if [[ $failed -eq 0 ]]; then
        print_success "All integrations completed successfully!"
        return 0
    else
        print_error "$failed integration(s) failed"
        return 1
    fi
}

# Validation only
validate_integration() {
    print_header "Validating Data Flow"
    print_info "Working directory: $PROJECTS_DIR"
    
    # Check Phylo Parser → RDF Generator
    print_info "Checking Phylo Parser outputs for RDF Generator..."
    if check_dir "$PROJECTS_DIR/tool2/output_json" && check_files "$PROJECTS_DIR/tool2/output_json" "*.json"; then
        print_success "Phylo Parser outputs ready for RDF Generator input"
    else
        print_error "Phylo Parser outputs not ready"
        return 1
    fi
    
    # Check RDF Generator required inputs
    print_info "Checking RDF Generator examples input..."
    if check_dir "$PROJECTS_DIR/tool3/data/examples" && check_files "$PROJECTS_DIR/tool3/data/examples" "*.json"; then
        print_success "RDF Generator examples ready"
    else
        print_error "RDF Generator examples not ready"
        return 1
    fi

    # Check RDF Generator → Query Service
    print_info "Checking RDF Generator outputs for Query Service..."
    if check_dir "$PROJECTS_DIR/tool3/outputs/combined_graphs" && check_files "$PROJECTS_DIR/tool3/outputs/combined_graphs" "*.ttl"; then
        print_success "RDF Generator outputs ready for Query Service input"
    else
        print_error "RDF Generator outputs not ready"
        return 1
    fi
    
    return 0
}

# Show integration status
show_status() {
    print_header "Integration Status"
    print_info "Working directory: $PROJECTS_DIR"
    
    echo -e "${BLUE}Phylo Parser outputs (source for RDF Generator):${NC}"
    if [[ -d "$PROJECTS_DIR/tool2/output_json" ]]; then
        count=$(ls "$PROJECTS_DIR/tool2/output_json"/*.json 2>/dev/null | wc -l)
        echo "  Files: $count JSON files"
        ls -lh "$PROJECTS_DIR/tool2/output_json"/*.json 2>/dev/null | awk '{print "    - " $9 " (" $5 ")"}' || echo "    (none)"
    else
        echo "  [NOT FOUND]"
    fi
    
    echo -e "\n${BLUE}RDF Generator data/examples (destination for Phylo Parser):${NC}"
    if [[ -d "$PROJECTS_DIR/tool3/data/examples" ]]; then
        count=$(ls "$PROJECTS_DIR/tool3/data/examples"/*.json 2>/dev/null | wc -l)
        echo "  Files: $count JSON files"
        ls -lh "$PROJECTS_DIR/tool3/data/examples"/*.json 2>/dev/null | awk '{print "    - " $9 " (" $5 ")"}' || echo "    (none)"
    else
        echo "  [NOT FOUND]"
    fi
    
    echo -e "\n${BLUE}RDF Generator RDF outputs (source for Query Service):${NC}"
    if [[ -d "$PROJECTS_DIR/tool3/outputs/combined_graphs" ]]; then
        count=$(ls "$PROJECTS_DIR/tool3/outputs/combined_graphs"/*.ttl 2>/dev/null | wc -l)
        echo "  Files: $count TTL files"
        ls -lh "$PROJECTS_DIR/tool3/outputs/combined_graphs"/*.ttl 2>/dev/null | awk '{print "    - " $9 " (" $5 ")"}' || echo "    (none)"
    else
        echo "  [NOT FOUND]"
    fi
    
    echo -e "\n${BLUE}Query Service data (destination for RDF Generator):${NC}"
    if [[ -f "$PROJECTS_DIR/tool4/data/kb.ttl" ]]; then
        size=$(ls -lh "$PROJECTS_DIR/tool4/data/kb.ttl" | awk '{print $5}')
        echo "  kb.ttl exists ($size)"
    else
        echo "  kb.ttl not found"
    fi
}

# Show help
usage() {
    cat << EOF
${BLUE}Data Integration Script for Four-Stage Pipeline${NC}

Automatically copies outputs from one stage to inputs of the next:
  - tool2 outputs → tool3 inputs
  - tool3 outputs → tool4 inputs

${BLUE}Usage:${NC}
  ./integrate.sh [COMMAND]

${BLUE}Commands:${NC}
  full              Run full integration (tool2→3, tool3→4)
  tool2-to-tool3    Integrate tool2 outputs to tool3 only
  tool3-to-tool4    Integrate tool3 outputs to tool4 only
  validate          Check if data is ready for integration
  status            Show current integration status
  help              Show this help message

${BLUE}Examples:${NC}
  ./integrate.sh full              # Full integration
  ./integrate.sh validate          # Check readiness
  ./integrate.sh status            # Show current status
  ./integrate.sh tool2-to-tool3    # Integrate only tool2→3

${BLUE}Integration Flow:${NC}
  1. Run tool2: cd orchestration && ./orchestrate.sh tool2
  2. Integrate: ./integrate.sh tool2-to-tool3
  3. Run tool3: ./orchestrate.sh tool3
  4. Integrate: ./integrate.sh tool3-to-tool4
  5. Run tool4: ./orchestrate.sh tool4

${BLUE}OR run the full pipeline with automatic integration:${NC}
  docker compose --profile full-pipeline up --build

${BLUE}RUN FROM:${NC}
  orchestration/ directory: ./integrate.sh full
  parent directory: ./orchestration/integrate.sh full

EOF
}

# Main
COMMAND="${1:-help}"

case "$COMMAND" in
    full)
        full_integration
        ;;
    tool2-to-tool3)
        integrate_tool2_to_tool3
        ;;
    tool3-to-tool4)
        integrate_tool3_to_tool4
        ;;
    validate)
        validate_integration
        ;;
    status)
        show_status
        ;;
    help)
        usage
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac
