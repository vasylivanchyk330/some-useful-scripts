#!/bin/bash

# UNCOMMENT this line to enable debugging
# set -xv

## Get resources requests and limits per container in a Kubernetes cluster.

OUT=resources.csv
NAMESPACE=--all-namespaces
SKIP_USAGE=false
QUITE=false
HEADERS=true
CONSOLE_ONLY=false
SCRIPT_NAME=$0

######### Functions #########

errorExit () {
    echo -e "\nERROR: $1\n"
    exit 1
}

usage () {
    cat << END_USAGE

${SCRIPT_NAME} - Extract resource requests and limits in a Kubernetes cluster for a selected namespace or all namespaces in a CSV format

Usage: ${SCRIPT_NAME} <options>

-n | --namespace <name>                : Namespace to analyse.    Default: --all-namespaces
-o | --output <name>                   : Output file.             Default: ${OUT}
-s | --skip-usage                      : Don't get usage (kubectl top)
-q | --quite                           : Don't output to stdout.  Default: Output to stdout
-h | --help                            : Show this usage
--no-headers                           : Don't print headers line
--console-only                         : Output to stdout only (don't write to file)

Examples:
========
Get all:                                                  $ ${SCRIPT_NAME}
Get for namespace foo:                                    $ ${SCRIPT_NAME} --namespace foo
Get for namespace foo and use output file bar.csv :       $ ${SCRIPT_NAME} --namespace foo --output bar.csv

END_USAGE

    exit 1
}

# Process command line options. See usage above for supported options
processOptions () {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n | --namespace)
                NAMESPACE="--namespace $2"
                shift 2
            ;;
            -o | --output)
                OUT=$2
                shift 2
            ;;
            -s | --skip-usage)
                SKIP_USAGE=true
                shift 1
            ;;
            -q | --quite)
                QUITE=true
                shift 1
            ;;
            --no-headers)
                HEADERS=false
                shift 1
            ;;
            --console-only)
                CONSOLE_ONLY=true
                OUT=/dev/null
                shift 1
            ;;
            -h | --help)
                usage
                exit 0
            ;;
            *)
                usage
            ;;
        esac
    done
}

# Test connection to a cluster by kubectl
testConnection () {
    kubectl cluster-info > /dev/null || errorExit "Connection to cluster failed"
}

# Main function to get requests and limits
getRequestsAndLimits () {
    # Backup OUT file if already exists
    [ -f "${OUT}" ] && [ "$CONSOLE_ONLY" == "false" ] && cp -f "${OUT}" "${OUT}.$(date +"%Y-%m-%d_%H:%M:%S")"

    # Prepare header for output CSV
    if [ "${HEADERS}" == true ]; then
        echo "Namespace,Pod,Container,CPU request,Memory request,CPU limit,Memory limit" | tee "${OUT}"
    else
        echo -n "" > "${OUT}"
    fi

    # Use kubectl with custom-columns to extract the data without jq
    kubectl get pods ${NAMESPACE} -o custom-columns='NAMESPACE:.metadata.namespace,POD:.metadata.name,CONTAINER:.spec.containers[*].name,CPU_REQUEST:.spec.containers[*].resources.requests.cpu,MEM_REQUEST:.spec.containers[*].resources.requests.memory,CPU_LIMIT:.spec.containers[*].resources.limits.cpu,MEM_LIMIT:.spec.containers[*].resources.limits.memory' |
    {
        read header  # Skip the header
        while IFS= read -r line; do
            # Extracted values will be space-separated due to multiple containers
            read namespace pod containers cpu_requests mem_requests cpu_limits mem_limits <<<"$line"
            
            IFS=',' read -r -a container_array <<< "$containers"
            IFS=',' read -r -a cpu_request_array <<< "$cpu_requests"
            IFS=',' read -r -a mem_request_array <<< "$mem_requests"
            IFS=',' read -r -a cpu_limit_array <<< "$cpu_limits"
            IFS=',' read -r -a mem_limit_array <<< "$mem_limits"

            for index in "${!container_array[@]}"; do
                final_line="${namespace},${pod},${container_array[$index]},${cpu_request_array[$index]},${mem_request_array[$index]},${cpu_limit_array[$index]},${mem_limit_array[$index]}"
                if [ "${QUITE}" == true ]; then
                    echo "${final_line}" >> "${OUT}"
                else
                    echo "${final_line}" | tee -a "${OUT}"
                fi
            done
        done
    }
}

main () {
    processOptions "$@"
    [ "${QUITE}" == true ] || echo "Getting pods resource requests and limits"
    testConnection
    getRequestsAndLimits
}

######### Main #########

main "$@"
