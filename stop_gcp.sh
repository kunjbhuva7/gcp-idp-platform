#!/bin/bash

# Harmonious visual styling
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}====================================================${NC}"
echo -e "${YELLOW}      GOOGLE CLOUD RESOURCES SHUTDOWN SCRIPT        ${NC}"
echo -e "${BLUE}====================================================${NC}"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null
then
    echo -e "${RED}Error: gcloud CLI is not installed or not in PATH!${NC}"
    exit 1
fi

PROJECT_ID="developer-platform-kubernetes"
ZONE="us-central1-a"

echo -e "\n${BLUE}[1/3] Setting Google Cloud Project to: ${YELLOW}${PROJECT_ID}${NC}"
gcloud config set project "${PROJECT_ID}"

# Scaling down GKE Node Pools to 0
echo -e "\n${BLUE}[2/3] Scaling down GKE Cluster Node Pools to 0...${NC}"

echo -e "${YELLOW}Scaling 'idp-node-pool' to 0...${NC}"
gcloud container node-pools update idp-node-pool \
    --cluster idp-gke-cluster \
    --zone "${ZONE}" \
    --enable-autoscaling \
    --min-nodes 0 \
    --max-nodes 0 \
    --quiet

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Successfully scaled down idp-node-pool to 0!${NC}"
else
    echo -e "${RED}✗ Failed to scale down idp-node-pool.${NC}"
fi

echo -e "\n${YELLOW}Scaling 'spot-node-pool' to 0...${NC}"
gcloud container node-pools update spot-node-pool \
    --cluster idp-gke-cluster \
    --zone "${ZONE}" \
    --enable-autoscaling \
    --min-nodes 0 \
    --max-nodes 0 \
    --quiet

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Successfully scaled down spot-node-pool to 0!${NC}"
else
    echo -e "${RED}✗ Failed to scale down spot-node-pool.${NC}"
fi

# Stop GCE VM Instances
echo -e "\n${BLUE}[3/3] Checking for running VM instances in zone ${YELLOW}${ZONE}${BLUE}...${NC}"
RUNNING_VMS=$(gcloud compute instances list --filter="status=RUNNING" --format="value(name)")

if [ -n "${RUNNING_VMS}" ]; then
    echo -e "${YELLOW}Found running VMs: ${RUNNING_VMS}${NC}"
    for vm in ${RUNNING_VMS}; do
        echo -e "Stopping VM instance: ${vm}..."
        gcloud compute instances stop "${vm}" --zone "${ZONE}" --quiet
    done
    echo -e "${GREEN}✓ All active VM instances have been stopped!${NC}"
else
    echo -e "${GREEN}✓ No running VM instances found.${NC}"
fi

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}      SHUTDOWN COMPLETED SUCCESSFULLY (0 NODES)     ${NC}"
echo -e "${BLUE}====================================================${NC}"
