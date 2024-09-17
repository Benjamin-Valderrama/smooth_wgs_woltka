#!/bin/bash

# Initialize empty arrays to store elements and positional arguments
modules=()
positional_args=()

# Parse command line options and positional arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -m)
            shift
            IFS=',' read -ra modules <<< "$1"
            ;;
        *)
            positional_args+=("$1")
            ;;
    esac
    shift
done


# Extract the input and output positional arguments
input="${positional_args[0]}"
output="${positional_args[1]}"


eval "$(micromamba shell hook --shell bash)"
micromamba activate rbase44


# Iterate through the elements using a for loop and echo each element
for module in "${modules[@]}"; do

    # Calculate stratified modules
    if [ -e "$input/stratified_functional_profile.tsv" ]; then
        echo "PROGRESS -- RUN STRATIFIED ANALYSIS"
        Rscript /home/bvalderrama/scripts/woltka_wgs/stratified_omixer.R $input $output $module
    fi

    # Calculate unstratified modules
    if [ -e "$input/unstratified_functional_profile.tsv" ]; then
        echo "PROGRESS -- RUN UNSTRATIFIED ANALYSIS"
        Rscript /home/bvalderrama/scripts/woltka_wgs/unstratified_omixer.R $input $output $module
    fi

done

micromamba deactivate
