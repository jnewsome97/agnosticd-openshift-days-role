# Debugging Changes Log

This document tracks all debugging-related changes made for troubleshooting the OCP 4.20 workshop deployment.

## Summary

A new diagnostic workload was created to provide comprehensive debug output for Phase 7 (Developer Experience) workloads. This workload is designed to be temporary and can be easily removed after troubleshooting.

---

## Changes Made

### 1. New Diagnostic Workload Role Created

**Location:** `ansible/roles_ocp_workloads/ocp4_workload_phase7_diagnostics/`

**Files Created:**
- `defaults/main.yml` - Default variables and feature flags
- `meta/main.yml` - Role metadata
- `tasks/main.yml` - Entry point
- `tasks/workload.yml` - Comprehensive diagnostic tasks

**What it diagnoses:**
- Minio S3 storage (namespace, pods, routes, PVCs)
- GitOps/ArgoCD (operator, instances, applications)
- GitLab (pods, routes, deployments, statefulsets)
- RHDH Orchestrator (Serverless, Knative, SonataFlow)
- Quay Registry (operator, instances, pods)
- Vault (pods, statefulsets, helm releases)
- External Secrets Operator (pods, CRs)
- Red Hat Developer Hub/Backstage (pods, routes, configs)
- GitLab Runner operator (subscription, CSV, pods)
- All Phase 7 operators summary
- Catalog sources status
- Pod errors and warning events
- PVC status

**To Remove:**
```bash
rm -rf ansible/roles_ocp_workloads/ocp4_workload_phase7_diagnostics/
```

---

### 2. Added Workload to infra_workloads (BEFORE Phase 7)

**File Modified:** `agnosticv/sandboxes-gpte/OCP4_ACM_ACS_OPS_WKSP/dev-ops-101.yaml`

**Change Made:**
Added BEFORE Phase 7 workloads (lines 49-52) to capture state after Phases 1-6 complete:
```yaml
  # DIAGNOSTICS CHECKPOINT (TEMPORARY - remove after troubleshooting)
  # Runs BEFORE Phase 7 to capture state after Phases 1-6 complete
  # If Phase 7 fails, we'll have visibility into what was deployed up to this point
  - ocp4_workload_phase7_diagnostics               # Comprehensive cluster state debugging
```

**Why Before Phase 7?**
If the diagnostics workload ran at the END, it would never execute if any earlier phase fails.
By running BEFORE Phase 7, we capture the state after Phases 1-6 complete, giving visibility
into the cluster state at that checkpoint.

**To Remove:**
Delete lines 49-52 from dev-ops-101.yaml (the 4-line block shown above)

---

### 3. Standalone Diagnostics Script (for manual use after failure)

**File Created:** `ansible/roles_ocp_workloads/ocp4_workload_phase7_diagnostics/run-diagnostics.sh`

**Purpose:**
When Ansible fails BEFORE the diagnostics workload runs, you can SSH to the bastion
and run this script manually to get the same diagnostic output.

**Usage:**
```bash
# SSH to bastion
ssh ec2-user@bastion.<guid>.<domain>

# Run diagnostics
/path/to/run-diagnostics.sh
# OR copy the script and run it
```

**To Remove:**
```bash
rm ansible/roles_ocp_workloads/ocp4_workload_phase7_diagnostics/run-diagnostics.sh
```

---

## Previous Fixes Applied (Not Debug-Related)

These are fixes that were applied earlier to resolve actual deployment issues. **Do NOT remove these:**

### Fix 1: Loki Operator Channel Mismatch

**File:** `dev-ops-101.yaml`
**Lines:** 231-243
```yaml
# FIXED: Use LIVE catalog (not snapshot) - loki-operator in snapshot uses stable-6.4 channel
# but role hardcodes channel: "stable" which only exists in live catalog
ocp4_workload_performance_monitoring_catalogsource_setup: false
```
**Reason:** Snapshot has `stable-6.4` channel but role requests `stable` channel.

### Fix 2: Quay Operator Outdated Channel

**File:** `dev-ops-101.yaml`
**Lines:** 424-426
```yaml
# FIXED: Update channel from stable-3.6 to stable-3.10 for OCP 4.20 compatibility
ocp4_workload_quay_operator_channel: stable-3.10
```
**Reason:** Default `stable-3.6` is outdated for OCP 4.20.

### Fix 3: GitLab Runner Old Catalog

**File:** `dev-ops-101.yaml`
**Lines:** 429-432
```yaml
# FIXED: Use certified-operators catalog instead of old GitLab registry catalog
ocp4_workload_redhat_developer_hub_gitlab_runner_catalog_setup: false
```
**Reason:** Role defaults to old GitLab registry catalog v1.18.2; certified-operators has v1.43.x.

---

## Complete Removal Instructions

To completely remove all debugging changes:

1. **Remove the diagnostic workload from infra_workloads:**
   Edit `agnosticv/sandboxes-gpte/OCP4_ACM_ACS_OPS_WKSP/dev-ops-101.yaml`
   Delete lines 49-52 (the 4-line block before Phase 7):
   ```yaml
     # DIAGNOSTICS CHECKPOINT (TEMPORARY - remove after troubleshooting)
     # Runs BEFORE Phase 7 to capture state after Phases 1-6 complete
     # If Phase 7 fails, we'll have visibility into what was deployed up to this point
     - ocp4_workload_phase7_diagnostics               # Comprehensive cluster state debugging
   ```

2. **Delete the diagnostic role directory:**
   ```bash
   rm -rf ansible/roles_ocp_workloads/ocp4_workload_phase7_diagnostics/
   ```

3. **Delete this documentation file (optional):**
   ```bash
   rm DEBUGGING_CHANGES.md
   ```

---

## Diagnostic Output Sections

The diagnostic workload outputs the following sections (can be disabled via variables):

| Section | Variable | Default |
|---------|----------|---------|
| Minio S3 | `phase7_diag_minio` | true |
| GitOps/ArgoCD | `phase7_diag_gitops` | true |
| GitLab | `phase7_diag_gitlab` | true |
| ArgoCD | `phase7_diag_argocd` | true |
| Orchestrator | `phase7_diag_orchestrator` | true |
| Serverless | `phase7_diag_serverless` | true |
| Quay | `phase7_diag_quay` | true |
| Vault | `phase7_diag_vault` | true |
| External Secrets | `phase7_diag_external_secrets` | true |
| Backstage | `phase7_diag_backstage` | true |
| GitLab Runner | `phase7_diag_gitlab_runner` | true |
| Operators Summary | `phase7_diag_operators` | true |
| Subscriptions | `phase7_diag_subscriptions` | true |
| Pods/Errors | `phase7_diag_pods` | true |
| Events | `phase7_diag_events` | true |

To disable a section, add to dev-ops-101.yaml:
```yaml
phase7_diag_minio: false  # Example: disable minio diagnostics
```

---

## Phase 7 Workload Debug Additions

Debug sections were added directly to each Phase 7 workload for inline troubleshooting.
Each workload now has START and COMPLETE debug sections.

### 4. ocp4_workload_minio

**File:** `ansible/roles_ocp_workloads/ocp4_workload_minio/tasks/workload.yml`

**Debug Added:**
- START: Storage classes, namespace pre-check
- COMPLETE: Namespace status, pods, PVCs, routes, pod logs

**To Remove:**
Delete the two debug sections marked with:
```
# ==============================================================================
# DEBUG SECTION - Added for troubleshooting (TEMPORARY)
# ==============================================================================
```

---

### 5. ocp4_workload_gitops_gitlab

**File:** `ansible/roles_ocp_workloads/ocp4_workload_gitops_gitlab/tasks/workload.yml`

**Debug Added:**
- START: GitOps namespace, ArgoCD instances, applications, CSVs
- COMPLETE: GitLab ArgoCD application, application health/sync, namespace, pods, routes

**To Remove:**
Delete the two debug sections marked with the DEBUG SECTION comments.

---

### 6. ocp4_workload_rhdh_orchestrator

**File:** `ansible/roles_ocp_workloads/ocp4_workload_rhdh_orchestrator/tasks/workload.yml`

**Debug Added:**
- START: Serverless CSVs, Knative Serving/Eventing, Orchestrator operator, SonataFlow namespace
- COMPLETE: Orchestrator CSV, SonataFlow namespace/pods/platform/workflows, PostgreSQL, Helm releases, Knative status

**To Remove:**
Delete the two debug sections marked with the DEBUG SECTION comments.

---

### 7. ocp4_workload_redhat_developer_hub_bootstrap

**File:** `ansible/roles_ocp_workloads/ocp4_workload_redhat_developer_hub_bootstrap/tasks/workload.yml`

**Debug Added:**
- START: ArgoCD instances, Quay operator/subscription, External Secrets, Vault, Catalog sources
- COMPLETE: janus-argocd namespace, ArgoCD instances/applications, Vault status/helm, External Secrets, ClusterSecretStores, Quay operator/subscription/registry/pods

**To Remove:**
Delete the two debug sections marked with the DEBUG SECTION comments.

---

### 8. ocp4_workload_redhat_developer_hub

**File:** `ansible/roles_ocp_workloads/ocp4_workload_redhat_developer_hub/tasks/workload.yml`

**Debug Added:**
- START: GitLab pods/routes, ArgoCD status, Backstage namespace, GitLab Runner operator/subscription, certified-operators catalog, DevSpaces
- COMPLETE: Backstage namespace/pods/routes/helm, GitLab Runner operator/subscription/CRs/pods, DevSpaces/CheCluster, GitLab status, all RHDH routes

**To Remove:**
Delete the two debug sections marked with the DEBUG SECTION comments.

---

## Quick Reference: All Debug Locations

| Workload | File | Debug Sections |
|----------|------|----------------|
| Diagnostic checkpoint | `ocp4_workload_phase7_diagnostics/tasks/workload.yml` | Full diagnostic role |
| Minio | `ocp4_workload_minio/tasks/workload.yml` | Lines 2-39, 125-151 |
| GitOps GitLab | `ocp4_workload_gitops_gitlab/tasks/workload.yml` | Lines 2-32, 67-96 |
| RHDH Orchestrator | `ocp4_workload_rhdh_orchestrator/tasks/workload.yml` | Lines 2-36, 123-158 |
| RHDH Bootstrap | `ocp4_workload_redhat_developer_hub_bootstrap/tasks/workload.yml` | Lines 2-39, 91-135 |
| RHDH | `ocp4_workload_redhat_developer_hub/tasks/workload.yml` | Lines 2-47, 202-249 |

---

## Complete Removal of ALL Debug Changes

To remove all debugging (both diagnostic workload AND inline debug sections):

```bash
# 1. Remove diagnostic workload from infra_workloads
# Edit dev-ops-101.yaml and delete lines 49-52

# 2. Delete diagnostic role
rm -rf ansible/roles_ocp_workloads/ocp4_workload_phase7_diagnostics/

# 3. Remove inline debug from each workload (use git)
git checkout -- ansible/roles_ocp_workloads/ocp4_workload_minio/tasks/workload.yml
git checkout -- ansible/roles_ocp_workloads/ocp4_workload_gitops_gitlab/tasks/workload.yml
git checkout -- ansible/roles_ocp_workloads/ocp4_workload_rhdh_orchestrator/tasks/workload.yml
git checkout -- ansible/roles_ocp_workloads/ocp4_workload_redhat_developer_hub_bootstrap/tasks/workload.yml
git checkout -- ansible/roles_ocp_workloads/ocp4_workload_redhat_developer_hub/tasks/workload.yml

# 4. Delete this file (optional)
rm DEBUGGING_CHANGES.md
```
