#!/bin/bash

# Set variables for the job
REGION="europe-west8"
CLUSTER_NAME="cpacluster"
JAR_PATHS=("gs://copurchasebucket/copurchaseanalysis_v1_2.jar" "gs://copurchasebucket/copurchaseanalysis_v1_1.jar" "gs://copurchasebucket/copurchaseanalysis_v1.0.jar")
INPUT_FILES=("gs://copurchasebucket/order_products_small.csv" "gs://copurchasebucket/order_products_medium.csv" "gs://copurchasebucket/order_products.csv")
OUTPUT_BUCKET="gs://copurchasebucket"
RESULT_FILE="test_results.csv"
PROJECT_ID="copurchaseanalysis"

# Initialize result file
echo "Cluster Type,Workers Count,Input File,Output Directory,Start Time,End Time,Execution Time (s),CPU Utilization (%),Memory Utilization (GB),JAR Name,Job URL" > $RESULT_FILE

# Function to delete cluster
delete_cluster() {
    gcloud dataproc clusters delete $CLUSTER_NAME --region=$REGION --quiet
}

# Function to fetch metrics
fetch_metrics() {
    echo "Fetching metrics for cluster $CLUSTER_NAME..."

    # Fetch CPU and memory utilization metrics using gcloud
    cpu_utilization=$(gcloud dataproc clusters describe $CLUSTER_NAME --region=$REGION \
        --format="value(metrics.cpu.utilization)" || echo "N/A")
    memory_utilization=$(gcloud dataproc clusters describe $CLUSTER_NAME --region=$REGION \
        --format="value(metrics.memory.utilization)" || echo "N/A")

    # Handle missing metrics gracefully
    cpu_utilization=${cpu_utilization:-N/A}
    memory_utilization=${memory_utilization:-N/A}
}

# Function to extract filename from a path
get_filename() {
    echo "$(basename $1)"
}

submit_jobs() {
    local workers=$1
    local cluster_type=$2

    for jar_path in "${JAR_PATHS[@]}"; do
        local jar_filename=$(get_filename $jar_path)

        for input_file in "${INPUT_FILES[@]}"; do
            local input_filename=$(get_filename $input_file)
            local output_path="$OUTPUT_BUCKET/output_$(date +%s)"

            echo "Submitting job for input file: $input_file, output path: $output_path"

            start_time=$(date +"%Y-%m-%d %H:%M:%S")
            job_start_epoch=$(date +%s)

            # Submit the Spark job
            gcloud dataproc jobs submit spark \
                --cluster=$CLUSTER_NAME \
                --region=$REGION \
                --jar=$jar_path \
                -- "$input_file" "$output_path" > /dev/null 2>&1

            # Fetch the job ID using `gcloud dataproc jobs list`
            job_id=$(gcloud dataproc jobs list \
                --region=$REGION \
                --filter="placement.clusterName=$CLUSTER_NAME" \
                --limit=1 \
                --sort-by="~status.stateStartTime" \
                --format="value(reference.jobId)")

            if [ -n "$job_id" ]; then
                # Construct the job URL
                job_url="https://console.cloud.google.com/dataproc/jobs/$job_id?region=$REGION&hl=en&inv=1&project=$PROJECT_ID"
            else
                job_url="N/A"
                echo "WARNING: Unable to extract job ID from job list."
            fi

            end_time=$(date +"%Y-%m-%d %H:%M:%S")
            job_end_epoch=$(date +%s)
            execution_time=$((job_end_epoch - job_start_epoch))

            # Fetch cluster metrics
            fetch_metrics

            # Log results to file
            echo "$cluster_type,$workers,$input_filename,output_$(date +%s),$start_time,$end_time,$execution_time,$cpu_utilization,$memory_utilization,$jar_filename,$job_url" >> $RESULT_FILE
        done
    done
}


# Test case 1: 3-worker cluster
echo "Creating 3-worker cluster..."
gcloud dataproc clusters create $CLUSTER_NAME \
    --region=$REGION \
    --num-workers=3 \
    --master-boot-disk-size=200 \
    --worker-boot-disk-size=66 \
    --worker-machine-type=n2-standard-2 \
    --master-machine-type=n2-standard-2
submit_jobs 3 "Worker-based"
delete_cluster

# Test case 2: 2-worker cluster
echo "Creating 2-worker cluster..."
gcloud dataproc clusters create $CLUSTER_NAME \
    --region=$REGION \
    --num-workers=2 \
    --master-boot-disk-size=200 \
    --worker-boot-disk-size=100 \
    --worker-machine-type=n2-standard-2 \
    --master-machine-type=n2-standard-2
submit_jobs 2 "Worker-based"
delete_cluster

# Test case 3: Single-node cluster
echo "Creating single-node cluster..."
gcloud dataproc clusters create $CLUSTER_NAME \
    --region=$REGION \
    --single-node \
    --master-boot-disk-size=400 \
    --master-machine-type=n2-standard-2
submit_jobs 1 "Single-node"
delete_cluster

echo "All tests completed. Results saved to $RESULT_FILE."