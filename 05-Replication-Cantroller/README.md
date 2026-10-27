# Kubernetes ReplicationController

## Overview

This lab demonstrates how to use a Kubernetes **ReplicationController (RC)** to manage Pod replicas and maintain the desired number of running Pods.

You will learn how to:

- Deploy an application using a ReplicationController.
- Inspect ReplicationControllers and Pods.
- Scale replicas up and down.
- Understand self-healing when Pods are deleted.
- View Pod placement across cluster nodes.
- Update and delete Kubernetes resources.

> **Note:** ReplicationController is a legacy Kubernetes workload resource. For new deployments, Kubernetes recommends using a Deployment, which provides declarative updates and easier rollout management.

---

## Prerequisites

Ensure that:

- A Kubernetes cluster is running.
- `kubectl` is installed and configured.
- You have access to the target cluster.
- The file `helloworld-rc.yaml` exists in the working directory.

Navigate to the lab directory:

```bash
cd 05-Replication-Cantroller/
```

Inspect the available files:

```bash
ls
cat README.md
cat helloworld-rc.yaml
```

---

## 1. Create the ReplicationController

Apply the YAML manifest to create the ReplicationController:

```bash
kubectl apply -f helloworld-rc.yaml
```

**Purpose:** Creates or updates the Kubernetes resource defined in the YAML file.

Verify the ReplicationController:

```bash
kubectl get rc
```

List the Pods:

```bash
kubectl get pods
```

Inspect the ReplicationController configuration and status:

```bash
kubectl describe rc helloworld-controller
```

### Key concepts

- **Desired replicas:** The number of Pods Kubernetes should maintain.
- **Current replicas:** The number of Pods currently recognized by the controller.
- **Ready replicas:** The number of Pods ready to serve requests.
- **Selector:** Identifies the Pods managed by the controller.
- **Pod template:** Defines how new Pods are created.

The ReplicationController uses its selector to identify the Pods it manages.

---

## 2. Scale Replicas Up

Increase the desired number of replicas to five:

```bash
kubectl scale --replicas=5 rc helloworld-controller
```

Verify the number of Pods:

```bash
kubectl get pods
```

Inspect the controller:

```bash
kubectl describe rc helloworld-controller
```

Check the replica count:

```bash
kubectl get rc
```

**Expected result:** The ReplicationController attempts to maintain five Pods matching its selector.

Wait for the Pods to become ready if necessary:

```bash
kubectl get pods -w
```

Press `Ctrl+C` to stop watching.

---

## 3. Scale Replicas Down

Reduce the desired number of replicas to one:

```bash
kubectl scale --replicas=1 rc helloworld-controller
```

Verify the result:

```bash
kubectl get pods
kubectl get rc
kubectl describe rc helloworld-controller
```

**Expected result:** The controller reduces the managed Pod count toward one.

Kubernetes decides which Pods to terminate; do not assume a particular Pod name will be retained.

---

## 4. Test Self-Healing

A key feature of a ReplicationController is maintaining the desired number of Pods.

First, list the Pods:

```bash
kubectl get pods
```

Delete a specific Pod by using its actual name:

```bash
kubectl delete pod <pod-name>
```

Replace `<pod-name>` with a name returned by `kubectl get pods`.

For example:

```bash
kubectl delete pod helloworld-controller-mk97p
```

Check the Pods again:

```bash
kubectl get pods
```

**Expected result:** If the deleted Pod was managed by the ReplicationController and the desired replica count remains one, the controller attempts to create a replacement Pod.

Watch the process:

```bash
kubectl get pods -w
```

This demonstrates Kubernetes' **self-healing behavior**.

> Deleting a Pod does not delete the ReplicationController. The controller continues to reconcile the actual state with the desired state.

---

## 5. Delete All Pods

List all Pods in the current namespace:

```bash
kubectl get pods
```

Delete all Pods in the current namespace:

```bash
kubectl delete pod --all
```

Check the result:

```bash
kubectl get pods
kubectl get rc
```

**Important:** This is a destructive operation for running Pods in the current namespace. Pods managed by the ReplicationController will generally be recreated to satisfy the desired replica count.

Therefore, deleting all Pods does not necessarily leave the cluster without Pods.

Only run this command in a lab namespace where you understand the impact.

---

## 6. Inspect Pod Placement

Display Pods with additional details, including their assigned nodes and IP addresses:

```bash
kubectl get pods -o wide
```

Example output:

```text
NAME                          READY   STATUS    RESTARTS   AGE   IP           NODE
helloworld-controller-abc12   1/1     Running   0          30s   10.244.0.5   worker1
```

The exact output depends on the cluster and Pod configuration.

The `-o wide` option helps you identify:

- Pod IP addresses.
- Worker nodes hosting Pods.
- Pod status and readiness.
- Distribution of workloads across nodes.

---

## 7. Reapply the Manifest

Reapply the YAML manifest:

```bash
kubectl apply -f helloworld-rc.yaml
```

Verify the ReplicationController and Pods:

```bash
kubectl get rc
kubectl get pods -o wide
```

Applying the manifest again is useful when the YAML file has been modified or when you want to ensure that the declared configuration is applied.

Inspect the YAML file:

```bash
vim helloworld-rc.yaml
```

After making changes, apply them:

```bash
kubectl apply -f helloworld-rc.yaml
```

**Note:** Editing a ReplicationController's Pod template does not automatically replace existing Pods to roll out the new template. For application rollouts, use a Deployment.

---

## 8. Delete the ReplicationController

Delete the resource defined in the manifest:

```bash
kubectl delete -f helloworld-rc.yaml
```

Verify that the ReplicationController and its managed Pods have been removed:

```bash
kubectl get rc
kubectl get pods -o wide
```

When a ReplicationController is deleted, Kubernetes normally deletes the Pods it manages as well.

If the manifest contains multiple resources, the delete command can affect all resources defined in that file. Review the YAML before running it.

---

## 9. Command Reference

| Command | Purpose |
|---|---|
| `kubectl apply -f helloworld-rc.yaml` | Create or update resources defined in the manifest |
| `kubectl get rc` | List ReplicationControllers |
| `kubectl describe rc helloworld-controller` | Inspect controller configuration, events, and replica status |
| `kubectl get pods` | List Pods in the current namespace |
| `kubectl scale --replicas=5 rc helloworld-controller` | Scale the controller to five replicas |
| `kubectl scale --replicas=1 rc helloworld-controller` | Scale the controller to one replica |
| `kubectl delete pod <pod-name>` | Delete a specific Pod |
| `kubectl delete pod --all` | Delete all Pods in the current namespace |
| `kubectl get pods -o wide` | Show additional Pod details, including node placement |
| `kubectl delete -f helloworld-rc.yaml` | Delete resources defined in the manifest |
| `kubectl get pods -w` | Watch Pod status changes |

---

## 10. Troubleshooting

### Pods Are Not Starting

Check Pod status:

```bash
kubectl get pods
kubectl describe pod <pod-name>
```

Review the Events section for scheduling errors, image-pull failures, or other problems.

### Replica Count Does Not Match the Desired Count

Inspect the controller:

```bash
kubectl describe rc helloworld-controller
```

Check:

- Whether the Pod selector matches the Pod template labels.
- Whether worker nodes are available.
- Whether Pods are failing to start.
- Whether sufficient CPU and memory are available.

### No Pods Are Listed

Check the ReplicationController:

```bash
kubectl get rc
kubectl describe rc helloworld-controller
```

If the controller exists, inspect its selector and events to determine why Pods are not being created.

---

## 11. ReplicationController vs. Deployment

| Feature | ReplicationController | Deployment |
|---|---|---|
| Maintains desired replica count | Yes | Yes, through ReplicaSets |
| Recreates failed or deleted Pods | Yes | Yes |
| Declarative application updates | Limited | Yes |
| Rolling updates and rollbacks | Not built in | Supported |
| Recommended for new applications | No; legacy resource | Yes |

For modern Kubernetes applications, prefer a Deployment:

```bash
kubectl create deployment helloworld --image=nginx
kubectl scale deployment helloworld --replicas=3
kubectl get deployments
kubectl get replicasets
kubectl get pods
```

This example uses NGINX to demonstrate a Deployment independently of the `helloworld-rc.yaml` manifest.

---

## Key Takeaways

1. A ReplicationController maintains the desired number of matching Pods.
2. `kubectl scale` changes the desired replica count.
3. Deleting a managed Pod usually causes the controller to create a replacement when necessary.
4. `kubectl describe` provides useful resource details and troubleshooting events.
5. `kubectl get pods -o wide` displays Pod placement and network information.
6. `kubectl delete pod --all` does not necessarily remove controller-managed workloads permanently.
7. Deployments are preferred over ReplicationControllers for new Kubernetes workloads.
