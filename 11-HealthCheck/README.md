# Kubernetes Health Checks: Liveness and Readiness Probes

## Overview

This lab demonstrates how Kubernetes health checks help monitor application health and manage container lifecycle.

Kubernetes provides different probe types to determine whether an application is running correctly and ready to receive traffic.

### What You Will Learn

- Configure health checks in Kubernetes Deployments.
- Understand liveness and readiness probes.
- Configure custom health-check values.
- Execute commands inside running containers.
- Inspect Pod health and troubleshoot probe failures.
- Understand how Kubernetes responds when a probe fails.

## Prerequisites

- A running Kubernetes cluster.
- `kubectl` installed and configured.
- Basic knowledge of Pods and Deployments.
- Access to the `11-HealthCheck` directory.

Navigate to the lab directory:

```bash
cd 11-HealthCheck/
```

List the available manifests:

```bash
ls
```

---

## 1. Deploy an Application with Health Checks

Inspect the Deployment manifest:

```bash
cat 01-helloworld-deploy-hc.yaml
```

Apply the configuration:

```bash
kubectl apply -f 01-helloworld-deploy-hc.yaml
```

Verify the Pods:

```bash
kubectl get pods
```

Inspect the Deployment:

```bash
kubectl get deployments
kubectl describe deployment helloworld-deployment
```

Inspect an individual Pod:

```bash
kubectl describe pod <pod-name>
```

Replace `<pod-name>` with an actual Pod name returned by `kubectl get pods`.

### What to Observe

- Pod status and readiness.
- Restart count.
- Configured liveness and readiness probes.
- Probe-related events.
- Whether the container is receiving traffic as expected.

**Note:** The exact behavior depends on the probe configuration defined in the YAML manifest.

---

## 2. Inspect and Edit a Deployment

List the Pods:

```bash
kubectl get pods
```

Inspect a specific Pod:

```bash
kubectl describe pod <pod-name>
```

Edit the Deployment interactively:

```bash
kubectl edit deployment helloworld-deployment
```

Kubernetes opens the live Deployment specification in your configured editor.

You can inspect or modify the container's probe configuration, including:

- `initialDelaySeconds`
- `periodSeconds`
- `timeoutSeconds`
- `failureThreshold`
- `successThreshold`
- `httpGet`, `tcpSocket`, or `exec` probe handlers

After saving the changes, inspect the Deployment and Pods:

```bash
kubectl get deployment helloworld-deployment
kubectl get pods
kubectl rollout status deployment/helloworld-deployment
```

To inspect the updated Pod:

```bash
kubectl describe pod <pod-name>
```

**Important:** Changes to a Pod template can trigger a Deployment rollout and create replacement Pods.

---

## 3. Configure Custom Health-Check Values

Inspect the custom configuration:

```bash
cat 02-helloworld-deploy-custom-values.yaml
```

Apply the manifest:

```bash
kubectl apply -f 02-helloworld-deploy-custom-values.yaml
```

Verify the Pods:

```bash
kubectl get pods
```

Inspect a Pod:

```bash
kubectl describe pod <pod-name>
```

### Why Custom Values Matter

Health-check parameters determine how quickly Kubernetes detects failures and how frequently it checks the application.

| Parameter | Description |
|---|---|
| `initialDelaySeconds` | Number of seconds to wait before starting probe checks |
| `periodSeconds` | Interval between probe checks |
| `timeoutSeconds` | Maximum time allowed for a probe to complete |
| `failureThreshold` | Consecutive failures required before a probe is considered failed |
| `successThreshold` | Consecutive successes required to consider a previously failing probe successful |

Choose values based on the application's startup time, response characteristics, and recovery requirements.

---

## 4. Liveness Probe Using an Exec Command

Inspect the manifest:

```bash
cat 03-pod-prob-exec.yaml
```

Apply the configuration:

```bash
kubectl apply -f 03-pod-prob-exec.yaml
```

List the Pods:

```bash
kubectl get pods
```

The manifest in this lab uses a Pod named `liveness-exec`.

### 4.1 Check the Health File

Execute a command inside the container:

```bash
kubectl exec -it liveness-exec -- cat /tmp/healthy
```

This reads the contents of `/tmp/healthy`.

Check whether the file exists:

```bash
kubectl exec -it liveness-exec -- ls -l /tmp/healthy
```

The file is commonly used in an exec-based liveness-probe demonstration.

For example, a probe might run:

```yaml
livenessProbe:
  exec:
    command:
      - cat
      - /tmp/healthy
  initialDelaySeconds: 5
  periodSeconds: 5
```

With this configuration, Kubernetes runs `cat /tmp/healthy` periodically. If the command repeatedly fails and reaches the configured failure threshold, Kubernetes treats the container as unhealthy and restarts it.

**Note:** The example above is illustrative. The actual behavior of your lab depends on the contents of `03-pod-prob-exec.yaml`.

### 4.2 Inspect Probe Status

```bash
kubectl describe pod liveness-exec
```

Check the output for:

- Liveness probe configuration.
- Container state and restart count.
- Recent events.
- Probe failure messages.

### 4.3 Understand Liveness Probe Behavior

A liveness probe determines whether a container should be restarted.

For example, if the application becomes stuck and the liveness check repeatedly fails, Kubernetes can restart the container.

A liveness probe should detect a condition that requires restarting the application, rather than simply checking whether a dependent service is temporarily unavailable.

---

## 5. Configure a Readiness Probe

Inspect the readiness-check manifest:

```bash
cat 04-helloworld-deploy-readiness-healthcheck.yaml
```

Apply the configuration:

```bash
kubectl apply -f 04-helloworld-deploy-readiness-healthcheck.yaml
```

Verify the Pods:

```bash
kubectl get pods
```

Inspect a Pod:

```bash
kubectl describe pod <pod-name>
```

### What Is a Readiness Probe?

A readiness probe determines whether a container is ready to serve requests.

If the readiness probe fails:

- The container is not necessarily restarted.
- The Pod is marked as not ready.
- The Pod is normally excluded from the ready endpoints of Services that select it.

When the readiness probe succeeds again, the Pod can become ready to receive traffic.

### Liveness vs. Readiness

| Feature | Liveness Probe | Readiness Probe |
|---|---|---|
| Purpose | Determines whether the container should be restarted | Determines whether the application can serve requests |
| On failure | Container may be restarted after the failure threshold is reached | Pod is marked not ready |
| Controls Service traffic | Not directly | Yes, through endpoint readiness |
| Typical use case | Detecting a stuck application | Checking whether startup or initialization is complete |

---

## 6. Delete and Reapply the Readiness Manifest

Delete the resources defined in the readiness manifest:

```bash
kubectl delete -f 04-helloworld-deploy-readiness-healthcheck.yaml
```

Recreate them:

```bash
kubectl apply -f 04-helloworld-deploy-readiness-healthcheck.yaml
```

Verify the status:

```bash
kubectl get pods
kubectl get deployments
```

Inspect the relevant Pod:

```bash
kubectl describe pod <pod-name>
```

**Important:** Deleting a manifest can delete the resources defined in it. Review the YAML before running the delete command, particularly if it contains resources shared with other labs.

---

## 7. Troubleshooting

### Pod Is Not Ready

Check Pod status:

```bash
kubectl get pods
kubectl describe pod <pod-name>
```

Look for readiness-probe failures in the Events section.

Check the Pod's readiness condition:

```bash
kubectl get pod <pod-name> -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}{"\n"}'
```

### Container Keeps Restarting

Check the restart count and Pod events:

```bash
kubectl get pods
kubectl describe pod <pod-name>
```

Inspect the current container logs:

```bash
kubectl logs <pod-name>
```

If the container has restarted, inspect the previous container's logs:

```bash
kubectl logs <pod-name> --previous
```

### Health File Does Not Exist

For the exec-based probe:

```bash
kubectl exec -it liveness-exec -- ls -l /tmp/healthy
```

If the file does not exist, inspect the manifest and determine whether the file is created by the container command or another process.

### Inspect Events

```bash
kubectl get events --sort-by=.metadata.creationTimestamp
```

Events can help identify probe failures, scheduling problems, image-pull errors, and container restarts.

---

## 8. Quick Command Reference

| Command | Purpose |
|---|---|
| `kubectl apply -f 01-helloworld-deploy-hc.yaml` | Deploy the application with health checks |
| `kubectl get pods` | List Pods and their status |
| `kubectl describe pod <pod-name>` | Inspect Pod details and events |
| `kubectl edit deployment helloworld-deployment` | Edit the live Deployment |
| `kubectl apply -f 02-helloworld-deploy-custom-values.yaml` | Apply custom probe settings |
| `kubectl apply -f 03-pod-prob-exec.yaml` | Deploy the exec-probe example |
| `kubectl exec -it liveness-exec -- cat /tmp/healthy` | Read the health-check file inside the container |
| `kubectl describe pod liveness-exec` | Inspect the exec-based liveness probe |
| `kubectl apply -f 04-helloworld-deploy-readiness-healthcheck.yaml` | Apply the readiness-probe example |
| `kubectl rollout status deployment/helloworld-deployment` | Check Deployment rollout progress |
| `kubectl logs <pod-name> --previous` | Read logs from the previous container instance |
| `kubectl get events --sort-by=.metadata.creationTimestamp` | Review recent cluster events |

---

## 10. Key Takeaways

1. **Liveness probes** help Kubernetes detect containers that need restarting.
2. **Readiness probes** help Kubernetes determine when an application can receive traffic.
3. **Custom probe values** control the timing and failure sensitivity of health checks.
4. **Exec probes** execute commands inside the container to determine health.
5. **`kubectl describe pod`** is one of the most useful commands for troubleshooting probe failures.
6. Readiness and liveness probes serve different purposes and should be configured independently according to application requirements.
7. A startup probe can be useful for applications that require a long initialization period.

### Recommended Next Step

After completing this lab, explore **startup probes**, HTTP-based probes, and TCP socket probes. These are useful for designing reliable production workloads.
