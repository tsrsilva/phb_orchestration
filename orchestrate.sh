#!/bin/bash
# Pipeline orchestration helper script
# Simplifies running the four-stage poetry analysis pipeline
# 
# Usage from orchestration/ directory: ./orchestrate.sh full --build
# Usage from parent directory: ./orchestration/orchestrate.sh full --build

set -e

# Find the orchestration directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECTS_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if docker compose is available
check_docker() {
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed"
        exit 1
    fi
    print_success "Docker Compose found"
}

# Show usage
usage() {
    cat << EOF
${BLUE}Four-Stage Poetry Analysis Pipeline Orchestration${NC}

Usage: ./orchestrate.sh [COMMAND] [OPTIONS]

${BLUE}COMMANDS:${NC}
  full              Run the complete pipeline (tool1 → tool2 → tool3 → tool4)
  stage1            Run only Stage 1 (Tax Report)
  stage2            Run only Stage 2 (Phylo Parser)
  stage3            Run only Stage 3 (RDF Generator)
  stage4            Run only Stage 4 (Query Service)
  stage2-4          Run Stages 2-4 (skip tool1)
  tool1             Run tool1 independently
  tool2             Run tool2 independently
  tool3             Run tool3 independently
  tool4             Run tool4 independently
  logs              Show live logs from all services
  logs [TOOL]       Show logs from a specific tool (e.g., logs tool1)
  status            Show status of all services
  stop              Stop and remove all containers
  clean             Remove containers, volumes, and images
  rebuild           Rebuild all Docker images
  shell [TOOL]      Open a shell in a running container
  help              Show this help message

${BLUE}OPTIONS:${NC}
  --build           Build images before running
  --detach          Run in detached mode
  --no-build        Skip image build
  --verbose         Show verbose output

${BLUE}EXAMPLES:${NC}
  ./orchestrate.sh full --build          # Run full pipeline with rebuild
  ./orchestrate.sh stage1                # Run only Stage 1
  ./orchestrate.sh logs tool2            # View logs from tool2
  ./orchestrate.sh status                # Show container status
  ./orchestrate.sh stop                  # Stop all services

${BLUE}RUN FROM:${NC}
  orchestration/ directory: ./orchestrate.sh full --build
  parent directory: ./orchestration/orchestrate.sh full --build

EOF
}

# Run full pipeline
run_full_pipeline() {
    print_header "Running Full Pipeline (tool1 → tool2 → tool3 → tool4)"
    print_info "Working directory: $SCRIPT_DIR"
    
    local build_flag=""
    [[ "$SKIP_BUILD" != "true" ]] && build_flag="--build"
    
    cd "$SCRIPT_DIR"
    
    if [[ "$DETACH" == "true" ]]; then
        docker compose --profile full-pipeline up -d $build_flag
        print_success "Pipeline started in detached mode"
        print_info "View logs with: cd '$SCRIPT_DIR' && ./orchestrate.sh logs"
    else
        docker compose --profile full-pipeline up $build_flag
        print_success "Pipeline completed"
    fi
}

# Run individual stage
run_stage() {
    local stage=$1
    print_header "Running Stage: $stage"
    print_info "Working directory: $SCRIPT_DIR"
    
    local build_flag=""
    [[ "$SKIP_BUILD" != "true" ]] && build_flag="--build"
    
    cd "$SCRIPT_DIR"
    docker compose --profile "$stage" up $build_flag
    print_success "Stage $stage completed"
}

# Run individual tool
run_tool() {
    local tool=$1
    print_header "Running $tool (independent)"
    print_info "Working directory: $SCRIPT_DIR"
    
    local build_flag=""
    [[ "$SKIP_BUILD" != "true" ]] && build_flag="--build"
    
    cd "$SCRIPT_DIR"
    docker compose run --no-deps --rm $build_flag "$tool"
    print_success "$tool completed"
}

# Show logs
show_logs() {
    local tool=$1
    cd "$SCRIPT_DIR"
    if [[ -z "$tool" ]]; then
        print_header "Live Logs (Press Ctrl+C to exit)"
        docker compose logs -f
    else
        print_header "Logs for $tool"
        docker compose logs -f "$tool"
    fi
}

# Show status
show_status() {
    print_header "Pipeline Status"
    cd "$SCRIPT_DIR"
    docker compose ps
    echo ""
    print_info "Volume status:"
    docker volume ls | grep pipeline || print_info "No pipeline volumes found"
}

# Stop all services
stop_services() {
    print_header "Stopping All Services"
    cd "$SCRIPT_DIR"
    docker compose down
    print_success "All services stopped"
}

# Clean everything
clean_all() {
    print_header "Cleaning Pipeline (containers, volumes, images)"
    print_info "This will remove all containers, volumes, and images"
    read -p "Are you sure? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$SCRIPT_DIR"
        docker compose --profile full-pipeline down -v
        docker compose --profile full-pipeline images -q | xargs -r docker rmi
        print_success "Pipeline cleaned"
    else
        print_info "Cancelled"
    fi
}

# Rebuild images
rebuild_images() {
    print_header "Rebuilding All Images"
    cd "$SCRIPT_DIR"
    docker compose --profile full-pipeline build --no-cache
    print_success "Images rebuilt"
}

# Open shell in container
open_shell() {
    local tool=$1
    if [[ -z "$tool" ]]; then
        print_error "Please specify a tool: orchestrate.sh shell [tool1|tool2|tool3|tool4]"
        exit 1
    fi
    print_header "Opening shell in $tool"
    cd "$SCRIPT_DIR"
    docker compose exec "$tool" bash
}

# Parse arguments
COMMAND=""
SKIP_BUILD="false"
DETACH="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        full|stage1|stage2|stage3|stage4|stage2-4|tool1|tool2|tool3|tool4)
            COMMAND="$1"
            shift
            ;;
        logs)
            COMMAND="logs"
            TOOL_ARG="$2"
            shift 2 || shift
            ;;
        shell)
            COMMAND="shell"
            TOOL_ARG="$2"
            shift 2 || shift
            ;;
        status|stop|clean|rebuild|help)
            COMMAND="$1"
            shift
            ;;
        --build)
            SKIP_BUILD="false"
            shift
            ;;
        --no-build)
            SKIP_BUILD="true"
            shift
            ;;
        --detach)
            DETACH="true"
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Main execution
check_docker

case "$COMMAND" in
    full)
        run_full_pipeline
        ;;
    stage1|stage2|stage3|stage4|stage2-4)
        run_stage "$COMMAND"
        ;;
    tool1|tool2|tool3|tool4)
        run_tool "$COMMAND"
        ;;
    logs)
        show_logs "$TOOL_ARG"
        ;;
    status)
        show_status
        ;;
    stop)
        stop_services
        ;;
    clean)
        clean_all
        ;;
    rebuild)
        rebuild_images
        ;;
    shell)
        open_shell "$TOOL_ARG"
        ;;
    help|"")
        usage
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac
