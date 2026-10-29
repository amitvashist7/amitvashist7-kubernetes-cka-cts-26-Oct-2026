# Kubernetes Resource Quota, LimitRange & Object Quota

## Overview

This lab demonstrates how to manage resource consumption and object creation in a shared Kubernetes cluster using:

- **Namespaces** — Isolate resources for teams and applications.
- **ResourceQuota** — Limit aggregate CPU, memory, storage, and other supported resources within a namespace.
- **LimitRange** — Define default, minimum, and maximum resource requests and limits for containers and Pods.
- **Object Count Quota** — Restrict the number of Kubernetes objects, such as Pods, Services, Deployments, and ConfigMaps.
- **Deployment Scaling** — Observe how quotas affect replica creation.
- **Services** — Expose applications through NodePort Services and understand how Service quotas are enforced.

## Lab directory

Run the commands from the directory containing these manifest files:

```text
01-Namespace-defination.yaml
02-Helloworld-with-quota.yaml
03-Helloworld-without-quota.yaml
04-Defaults-Limits.yml
05-ResourceQuota.yaml
06-ObjectQuota.yaml
```

## Prerequisites

- A running Kubernetes cluster.
- `kubectl` configured to access the cluster.
- Access to create namespaces, Deployments, ResourceQuotas, LimitRanges, and Services.
- The YAML manifests listed above.

Check cluster connectivity:

```bash
kubectl cluster-info
kubectl get nodes
kubectl get namespaces
```

---

## 1. Create and verify a Namespace

Namespaces provide logical isolation for applications, teams, and environments. ResourceQuota and LimitRange policies can then be applied to individual namespaces.

Apply the namespace manifest:

```bash
kubectl apply -f 01-Namespace-defination.yaml
```

List the namespaces:

```bash
kubectl get ns
```

Verify that `myspace` exists:

```bash
kubectl get namespace myspace
kubectl describe namespace myspace
```

**Expected outcome:** The `myspace` namespace should be available for the remaining exercises.

## 2. Deploy an application with resource configuration

Inspect the manifest:

```bash
cat 02-Helloworld-with-quota.yaml
```

This manifest defines the Hello World application with resource configuration. Review its `resources.requests` and `resources.limits` settings before deployment.

Apply the manifest:

```bash
kubectl apply -f 02-Helloworld-with-quota.yaml -n myspace
```

Check the Pods:

```bash
kubectl get pods -n myspace
```

Inspect a Pod:

```bash
kubectl describe pod <pod-name> -n myspace
```

Replace `<pod-name>` with the actual Pod name returned by `kubectl get pods`.

Review the Pod's resource configuration and events. The `describe` output can help you identify scheduling failures, quota-related admission errors, and other Pod issues.

## 3. Deploy an application without explicit resource configuration

Inspect the second application manifest:

```bash
cat 03-Helloworld-without-quota.yaml
```

Apply it:

```bash
kubectl apply -f 03-Helloworld-without-quota.yaml -n myspace
```

Verify the Deployment and Pods:

```bash
kubectl get deployments -n myspace
kubectl get pods -n myspace
```

Inspect the Deployment's Pod:

```bash
kubectl describe pod <pod-name> -n myspace
```

### What to observe

Compare the two application manifests.

- Does the first application specify CPU and memory requests and limits?
- Does the second application omit those settings?
- Can both applications be created under the current namespace policies?
- What events appear when resource quota requirements are not satisfied?

**Important:** A ResourceQuota that tracks CPU or memory requests and limits can require new Pods to specify those values. A LimitRange can supply defaults when the Pod specification omits them.

## 4. Configure a LimitRange

A LimitRange allows administrators to define default resource settings and enforce minimum or maximum resource values within a namespace.

Inspect the manifest:

```bash
cat 04-Defaults-Limits.yml
```

Apply it:

```bash
kubectl apply -f 04-Defaults-Limits.yml
```

List LimitRanges in `myspace`:

```bash
kubectl get limitrange -n myspace
```

Inspect the `limits` object:

```bash
kubectl describe limitrange limits -n myspace
```

### What to observe

Review the LimitRange configuration for:

- Default CPU and memory requests.
- Default CPU and memory limits.
- Minimum permitted resource values.
- Maximum permitted resource values.
- Any applicable request-to-limit ratio constraints.

Defaults are applied when new Pods are admitted. They do not retroactively modify existing Pods.

### Test the behavior

Delete the earlier application workloads before recreating them if you want to compare the effect of the LimitRange.

```bash
kubectl delete -f 02-Helloworld-with-quota.yaml -n myspace
kubectl delete -f 03-Helloworld-without-quota.yaml -n myspace
```

Recreate the application without explicit resource configuration:

```bash
kubectl apply -f 03-Helloworld-without-quota.yaml -n myspace
kubectl get pods -n myspace
kubectl describe pod <pod-name> -n myspace
```

Inspect the resulting Pod to see whether the LimitRange defaults were applied.

**Key takeaway:** A LimitRange defines per-container or per-Pod defaults and boundaries; a ResourceQuota controls aggregate namespace consumption.

## 5. Configure a ResourceQuota

A ResourceQuota controls the aggregate resources that workloads can request or consume within a namespace.

Inspect the manifest:

```bash
cat 05-ResourceQuota.yaml
```

Edit it if required:

```bash
vim 05-ResourceQuota.yaml
```

Apply the quota:

```bash
kubectl apply -f 05-ResourceQuota.yaml
```

Inspect the `compute-quota` object:

```bash
kubectl describe resourcequota/compute-quota -n myspace
```

Review the configured `Hard` limits and current `Used` values.

### Important concepts

A ResourceQuota can limit:

- Total CPU requests: `requests.cpu`
- Total memory requests: `requests.memory`
- Total CPU limits: `limits.cpu`
- Total memory limits: `limits.memory`
- Aggregate storage requests: `requests.storage`
- Supported object counts and other resource types.

The exact limits for this lab are defined in `05-ResourceQuota.yaml`.

### Observe quota usage

Create the application without explicit resource settings:

```bash
kubectl apply -f 03-Helloworld-without-quota.yaml -n myspace
```

Check the quota:

```bash
kubectl describe resourcequota/compute-quota -n myspace
kubectl get pods -n myspace
```

If required CPU or memory requests or limits are missing, Pod creation can be rejected when the quota tracks those resources. If a LimitRange supplies defaults, the Pod may be admitted if the resulting values fit within the quota.

## 6. Understand Deployment scaling under ResourceQuota

Find the Deployment and its ReplicaSet:

```bash
kubectl get deployments -n myspace
kubectl get rs -n myspace
kubectl get pods -n myspace
```

Inspect the Deployment:

```bash
kubectl describe deployment helloworld-deployment -n myspace
```

Inspect its ReplicaSet:

```bash
kubectl describe rs <replicaset-name> -n myspace
```

Scale the Deployment to six replicas:

```bash
kubectl scale --replicas=6 deployment/helloworld-deployment -n myspace
```

Verify the results:

```bash
kubectl get pods -n myspace
kubectl describe resourcequota/compute-quota -n myspace
kubectl describe deployment helloworld-deployment -n myspace
kubectl describe rs <replicaset-name> -n myspace
```

Try increasing the replica count:

```bash
kubectl scale --replicas=10 deployment/helloworld-deployment -n myspace
kubectl get pods -n myspace
kubectl describe resourcequota/compute-quota -n myspace
```

Then reduce the replica count:

```bash
kubectl scale --replicas=4 deployment/helloworld-deployment -n myspace
kubectl scale --replicas=5 deployment/helloworld-deployment -n myspace
kubectl scale --replicas=6 deployment/helloworld-deployment -n myspace
kubectl scale --replicas=7 deployment/helloworld-deployment -n myspace
```

After each change, inspect the Pods, ReplicaSet events, and quota usage.

### What to observe

- The Deployment's desired replica count can increase even when the quota prevents all desired Pods from being created.
- Pod creation can fail when the additional Pods would exceed a ResourceQuota.
- If Pods are admitted but nodes lack sufficient capacity, Pods may remain Pending for scheduling reasons instead.
- Reducing replicas can free quota capacity as Pods are deleted.
- Existing workloads are not necessarily evicted just because a quota is lowered.

Use `kubectl describe rs` and `kubectl get events -n myspace --sort-by=.metadata.creationTimestamp` to investigate the actual cause.

## 7. Modify ResourceQuota limits

Edit the quota directly:

```bash
kubectl edit resourcequota/compute-quota -n myspace
```

Inspect the updated values:

```bash
kubectl describe resourcequota/compute-quota -n myspace
```

You can also edit the YAML manifest and reapply it:

```bash
vim 05-ResourceQuota.yaml
kubectl apply -f 05-ResourceQuota.yaml
kubectl describe resourcequota/compute-quota -n myspace
```

**Best practice:** Keep quota configuration in version-controlled YAML and use `kubectl apply` to make repeatable changes. If you edit the live object, remember to update the manifest to avoid configuration drift.

## 8. Configure Object Count Quota

Object Count Quota limits the number of supported Kubernetes API objects within a namespace. It uses the same `ResourceQuota` API kind but specifies object-count limits rather than CPU and memory budgets.

Inspect the manifest:

```bash
cat 06-ObjectQuota.yaml
```

Edit the manifest if required:

```bash
vim 06-ObjectQuota.yaml
```

Check the Services already present:

```bash
kubectl get svc -n myspace
```

Apply the object quota:

```bash
kubectl apply -f 06-ObjectQuota.yaml
```

Inspect the quota:

```bash
kubectl describe resourcequota/object-quota -n myspace
```

### Common object-count quota examples

| Object | Quota key | Purpose |
|---|---|---|
| ConfigMaps | `configmaps` | Limit configuration objects |
| Secrets | `secrets` | Limit secret objects |
| Pods | `pods` | Limit non-terminal Pods counted by the quota |
| PersistentVolumeClaims | `persistentvolumeclaims` | Limit storage claims |
| ReplicationControllers | `replicationcontrollers` | Limit legacy controller objects |
| Services | `services` | Limit all Services |
| LoadBalancer Services | `services.loadbalancers` | Limit LoadBalancer-type Services |
| Deployments | `count/deployments.apps` | Limit Deployment objects |
| Jobs | `count/jobs.batch` | Limit Job objects |
| CronJobs | `count/cronjobs.batch` | Limit CronJob objects |

The exact object types and limits enforced in this lab depend on the contents of `06-ObjectQuota.yaml`.

### Observe object quota enforcement

Check existing Deployments:

```bash
kubectl get deployments -n myspace
```

Apply the application manifests:

```bash
kubectl apply -f 03-Helloworld-without-quota.yaml -n myspace
kubectl apply -f 02-Helloworld-with-quota.yaml -n myspace
```

Inspect the results:

```bash
kubectl get deployments -n myspace
kubectl get pods -n myspace
kubectl describe resourcequota/object-quota -n myspace
```

If the Deployment count or Pod count reaches the configured limit, further object creation can be rejected.

**Important:** A Deployment, ReplicaSet, and Pod are different objects. A quota on Deployments does not automatically limit the number of Pods, and a Pod quota does not directly set the desired replica count of a Deployment.

## 9. Expose the applications through NodePort Services

Expose the first Deployment:

```bash
kubectl expose deployment helloworld-deployment \
  --type=NodePort \
  -n myspace
```

Inspect the Services:

```bash
kubectl get svc -n myspace
```

Expose the second Deployment:

```bash
kubectl expose deployment helloworld-deployment-with-quota \
  --type=NodePort \
  -n myspace
```

Check the Services and object quota usage:

```bash
kubectl get svc -n myspace
kubectl describe resourcequota/object-quota -n myspace
```

### What to observe

- Each successful `kubectl expose` command creates a Service.
- A Service quota can reject creation when the maximum number of Services has been reached.
- A quota on `services.loadbalancers` specifically limits LoadBalancer-type Services, not NodePort Services.
- NodePort Services do not automatically create cloud LoadBalancers.

If a Service already exists, `kubectl expose` may return an `AlreadyExists` error. Inspect the existing Service before trying again.

## 10. Troubleshooting

### Pod creation rejected by ResourceQuota

```bash
kubectl describe resourcequota/compute-quota -n myspace
kubectl describe pod <pod-name> -n myspace
kubectl get events -n myspace --sort-by=.metadata.creationTimestamp
```

Check whether CPU or memory requests and limits are missing or whether the aggregate quota is exhausted.

### Pods remain Pending

```bash
kubectl get pods -n myspace
kubectl describe pod <pod-name> -n myspace
```

Look for scheduling events indicating insufficient node capacity, quota admission issues, or other constraints.

### Object creation rejected by Object Count Quota

```bash
kubectl describe resourcequota/object-quota -n myspace
kubectl get deployments,rs,pods,svc,configmaps,secrets,pvc -n myspace
```

Check which quota key has reached its hard limit.

### LimitRange defaults are not visible

```bash
kubectl get limitrange -n myspace
kubectl describe limitrange limits -n myspace
kubectl describe pod <pod-name> -n myspace
```

Confirm that the LimitRange exists in the same namespace as the Pod and that the Pod was created after the LimitRange was applied.

## 11. Cleanup

Delete the application resources:

```bash
kubectl delete -f 02-Helloworld-with-quota.yaml -n myspace
kubectl delete -f 03-Helloworld-without-quota.yaml -n myspace
```

Delete the quota objects:

```bash
kubectl delete -f 05-ResourceQuota.yaml
kubectl delete -f 06-ObjectQuota.yaml
```

Delete the LimitRange:

```bash
kubectl delete -f 04-Defaults-Limits.yml
```

Verify remaining resources:

```bash
kubectl get all -n myspace
kubectl get resourcequota,limitrange -n myspace
```

If this is a dedicated lab namespace and you want to remove everything inside it, you can delete the namespace:

```bash
kubectl delete namespace myspace
```

**Warning:** Deleting the namespace deletes its namespaced resources, including workloads, Services, Secrets, ConfigMaps, and PVC objects. Depending on the StorageClass reclaim policy, deleting PVCs can also result in underlying storage being deleted. Do not delete a shared or production namespace.

## Key Takeaways

1. **Namespace** provides logical isolation for workloads.
2. **ResourceQuota** controls aggregate resource budgets and supported object counts.
3. **LimitRange** provides default resource values and per-container or per-Pod boundaries.
4. **Deployment scaling** can be constrained by quota even when the desired replica count is higher.
5. **Object Count Quota** limits objects such as Pods, ConfigMaps, PVCs, and Services.
6. **NodePort and LoadBalancer Services** have different infrastructure and quota implications.
7. **Observability matters:** Use `kubectl describe`, `kubectl get`, and namespace events to identify quota and scheduling problems.

## Useful References

- Kubernetes Resource Quotas: https://kubernetes.io/docs/concepts/policy/resource-quotas/
- Configure Quotas for API Objects: https://kubernetes.io/docs/tasks/administer-cluster/quota-api-object/
- LimitRange: https://kubernetes.io/docs/concepts/policy/limit-range/
- Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Services: https://kubernetes.io/docs/concepts/services-networking/service/
