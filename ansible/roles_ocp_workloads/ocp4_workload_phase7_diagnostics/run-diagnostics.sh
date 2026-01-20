#!/bin/bash
# Standalone diagnostics script - run manually on bastion after deployment failure
# Usage: ./run-diagnostics.sh
#
# This script runs the same diagnostics as the Ansible workload, but can be
# executed manually via SSH when Ansible fails before the diagnostics workload runs.

echo "============================================================"
echo "MANUAL DIAGNOSTICS - Run after deployment failure"
echo "============================================================"
echo ""

echo "=== CLUSTER VERSION ==="
oc get clusterversion
echo ""

echo "=== CLUSTER OPERATORS (problematic) ==="
oc get co | grep -E "NAME|False|Unknown|Degraded" || echo "All operators healthy"
echo ""

echo "=== ALL SUBSCRIPTIONS ==="
oc get subscriptions.operators.coreos.com -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,PACKAGE:.spec.name,CHANNEL:.spec.channel,SOURCE:.spec.source,STATE:.status.state
echo ""

echo "=== SUBSCRIPTIONS WITH ISSUES ==="
oc get subscriptions.operators.coreos.com -A -o json | jq -r '.items[] | select(.status.conditions[]? | select(.type=="ResolutionFailed" and .status=="True")) | "\(.metadata.namespace)/\(.metadata.name): \(.status.conditions[] | select(.type=="ResolutionFailed") | .message)"' 2>/dev/null | head -20 || echo "No subscription issues found"
echo ""

echo "=== ALL CSVs (non-Succeeded) ==="
oc get csv -A --no-headers | grep -v Succeeded || echo "All CSVs Succeeded"
echo ""

echo "=== PENDING INSTALL PLANS ==="
oc get installplan -A | grep -v "Complete" | head -30 || echo "All InstallPlans complete"
echo ""

echo "=== CATALOG SOURCES ==="
oc get catalogsource -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,TYPE:.spec.sourceType,STATUS:.status.connectionState.lastObservedState
echo ""

echo "=== UNHEALTHY CATALOG SOURCES ==="
oc get catalogsource -A -o json | jq -r '.items[] | select(.status.connectionState.lastObservedState != "READY") | "\(.metadata.namespace)/\(.metadata.name): \(.status.connectionState.lastObservedState // "UNKNOWN")"' 2>/dev/null || echo "All healthy"
echo ""

echo "=== PODS NOT RUNNING (excluding Completed) ==="
oc get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded 2>/dev/null | head -40 || echo "All pods running"
echo ""

echo "=== RECENT WARNING EVENTS ==="
oc get events -A --field-selector type!=Normal --sort-by='.lastTimestamp' 2>/dev/null | tail -30 || echo "No warning events"
echo ""

echo "=== PENDING PVCs ==="
oc get pvc -A --field-selector=status.phase!=Bound | head -20 || echo "All PVCs bound"
echo ""

echo "=== STORAGE CLASSES ==="
oc get sc
echo ""

echo "=== ODF STATUS ==="
oc get storagecluster -n openshift-storage -o wide 2>/dev/null || echo "No StorageCluster"
echo ""

echo "=== LOKI OPERATOR STATUS ==="
echo "Namespace:"
oc get ns openshift-operators-redhat 2>/dev/null || echo "Namespace not found"
echo ""
echo "Subscription:"
oc get subscriptions.operators.coreos.com -n openshift-operators-redhat loki-operator -o yaml 2>/dev/null | grep -A20 "status:" || echo "No subscription"
echo ""
echo "CSV:"
oc get csv -n openshift-operators-redhat 2>/dev/null | grep loki || echo "No Loki CSV"
echo ""

echo "=== PERFORMANCE MONITORING COMPONENTS ==="
echo "Logging namespace:"
oc get pods -n openshift-logging 2>/dev/null | head -20 || echo "openshift-logging not found"
echo ""

echo "=== MINIO STATUS ==="
oc get all -n ic-shared-minio 2>/dev/null | head -15 || echo "ic-shared-minio not found"
echo ""

echo "=== GITOPS/ARGOCD STATUS ==="
oc get argocd -A -o wide 2>/dev/null || echo "No ArgoCD"
echo ""

echo "=== GITLAB STATUS ==="
oc get pods -A | grep -i gitlab | head -10 || echo "No GitLab pods"
echo ""

echo "=== BACKSTAGE/RHDH STATUS ==="
oc get all -n backstage 2>/dev/null | head -15 || echo "backstage namespace not found"
echo ""

echo "=== QUAY STATUS ==="
oc get quayregistry -A 2>/dev/null || echo "No QuayRegistry"
echo ""

echo "============================================================"
echo "DIAGNOSTICS COMPLETE"
echo "============================================================"
