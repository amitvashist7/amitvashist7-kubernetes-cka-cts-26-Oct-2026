# Kubernetes API Exploration

## Overview

This guide covers basic Kubernetes cluster discovery, API resource inspection, and direct interaction with the Kubernetes API server using `kubectl` and `curl`.

## Prerequisites

Before running these commands, ensure that:

- A Kubernetes cluster is running.
- `kubectl` is installed.
- Your `kubectl` configuration is available and points to the correct cluster.
- You have the required permissions to access cluster resources.

Verify cluster connectivity:

```bash
kubectl get nodes
```

---

## 1. Cluster Information

### 1.1 Display Cluster Information

```bash
kubectl cluster-info
```

**Purpose:** Displays the addresses of the Kubernetes control plane and other cluster services when available.

**Example output:**

```text
Kubernetes control plane is running at https://192.168.56.10:6443
CoreDNS is running at https://192.168.56.10:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

*Note: The addresses and output depend on your cluster configuration.*

### 1.2 List Supported API Versions

```bash
kubectl api-versions
```

**Purpose:** Lists the API groups and versions supported by the Kubernetes API server.

**Example output:**

```text
v1
apps/v1
batch/v1
autoscaling/v2
networking.k8s.io/v1
rbac.authorization.k8s.io/v1
storage.k8s.io/v1
```

**Why it matters:**
- Identifies available Kubernetes APIs.
- Helps determine which API versions can be used in manifests and automation.
- Assists with troubleshooting API compatibility.

### 1.3 List Available API Resources

```bash
kubectl api-resources
```

**Purpose:** Lists the resource types exposed by the Kubernetes API server.

**Example output:**

```text
NAME          SHORTNAMES   APIVERSION   NAMESPACED   KIND
pods          po           v1           true         Pod
services      svc          v1           true         Service
nodes         no           v1           false        Node
namespaces    ns           v1           false        Namespace
deployments   deploy       apps/v1      true         Deployment
```

**Key columns:**

| Column | Description |
|---|---|
| NAME | Resource name used with `kubectl` |
| SHORTNAMES | Optional aliases for the resource |
| APIVERSION | API group and version |
| NAMESPACED | Whether the resource belongs to a namespace |
| KIND | Kubernetes object type |

**Examples:**

```bash
kubectl get pods
kubectl get deployments
kubectl get nodes
kubectl get namespaces
```

---

## 2. Start the Kubernetes API Proxy

### 2.1 Launch the Proxy

```bash
kubectl proxy \
  --address='127.0.0.1' \
  --port=8001 \
  --accept-hosts='.' \
  --accept-paths='.' &
```

**Purpose:** Starts a local HTTP proxy that forwards requests to the Kubernetes API server using the credentials and configuration available to `kubectl`.

**Parameters explained:**

| Parameter | Description |
|---|---|
| `kubectl proxy` | Starts a local proxy to the Kubernetes API server |
| `--address='127.0.0.1'` | Listens only on the local loopback interface |
| `--port=8001` | Uses port `8001` for the local proxy |
| `--accept-hosts='.'` | Accepts host headers matching the supplied regular expression |
| `--accept-paths='.'` | Accepts paths matching the supplied regular expression |
| `&` | Runs the process in the background |

**Important security note:** The `--accept-hosts='.'` and `--accept-paths='.'` settings are permissive. For a local lab, binding to `127.0.0.1` limits access to the local machine, but you should still use restrictive settings where possible. Do not expose this proxy to untrusted networks.

### 2.2 Verify the Proxy

```bash
curl http://127.0.0.1:8001
```

This sends an HTTP request to the local proxy's root endpoint. A successful response typically contains Kubernetes API discovery information.

If the connection fails, check whether the proxy is running:

```bash
ps aux | grep '[k]ubectl proxy'
```

To stop the proxy, identify its process ID and terminate that specific process:

```bash
kill <PID>
```

Replace `<PID>` with the actual process ID.

---

## 3. Access the Kubernetes API Server Directly

### 3.1 Test the API Server Endpoint

```bash
curl -k https://127.0.0.1:6443
```

**Purpose:** Sends an HTTPS request directly to the Kubernetes API server.

**Parameter:**

- `-k`: Disables TLS certificate verification.

**Important:** Use `-k` only for troubleshooting in a controlled lab. It does not authenticate you to the API server. A `401 Unauthorized` or `403 Forbidden` response can indicate that the server is reachable but the request lacks the necessary authentication or authorization.

Also, `127.0.0.1` refers to the machine running the command. If the API server runs on another machine, replace this address with the correct API server endpoint.

### 3.2 Access the API Through the Proxy

Once `kubectl proxy` is running, use the following commands to explore the Kubernetes API.

#### A. Access the API Root

```bash
curl http://127.0.0.1:8001
```

**Purpose:** Retrieves API discovery information from the proxy's root endpoint.

#### B. List API Groups

```bash
curl http://127.0.0.1:8001/apis
```

**Purpose:** Lists the available named API groups and their versions.

Examples of API groups include:

- `apps`
- `batch`
- `networking.k8s.io`
- `rbac.authorization.k8s.io`

The core API group is exposed separately under `/api`.

#### C. Explore the Core API

```bash
curl http://127.0.0.1:8001/api/v1
```

**Purpose:** Retrieves discovery information for the Kubernetes core API version `v1`.

This API includes resources such as:

- Pods
- Services
- Nodes
- Namespaces
- ConfigMaps
- Secrets

The response is JSON and describes the resources and operations exposed by this API version.

#### D. List Pods Across Namespaces

```bash
curl http://127.0.0.1:8001/api/v1/pods
```

**Purpose:** Requests the Pod collection across all namespaces.

The response contains a JSON object with an `items` array representing the Pods the authenticated identity is authorized to list.

**Alternative using kubectl:**

```bash
kubectl get pods --all-namespaces
```

To list Pods in a specific namespace through the proxy:

```bash
curl http://127.0.0.1:8001/api/v1/namespaces/default/pods
```

---

## 4. Command Reference

| Command | Purpose |
|---|---|
| `kubectl cluster-info` | Displays cluster endpoint information |
| `kubectl api-versions` | Lists supported API groups and versions |
| `kubectl api-resources` | Lists available API resource types |
| `kubectl proxy --address='127.0.0.1' --port=8001 --accept-hosts='.' --accept-paths='.' &` | Starts the local Kubernetes API proxy |
| `curl -k https://127.0.0.1:6443` | Tests direct HTTPS connectivity to the API server |
| `curl http://127.0.0.1:8001` | Requests the proxy's API root |
| `curl http://127.0.0.1:8001/apis` | Lists named API groups |
| `curl http://127.0.0.1:8001/api/v1` | Retrieves core API v1 discovery information |
| `curl http://127.0.0.1:8001/api/v1/pods` | Lists Pods across namespaces, subject to authorization |

---


## 5. Key Takeaways

1. `kubectl cluster-info` helps identify cluster endpoints.
2. `kubectl api-versions` and `kubectl api-resources` help you discover available APIs and resources.
3. `kubectl proxy` provides a local HTTP interface to the Kubernetes API using your configured credentials.
4. `curl` lets you inspect API discovery documents and request Kubernetes resources.
5. A successful HTTP connection does not necessarily mean that a request is authorized.
6. Direct API access and proxy access are different: the proxy uses `kubectl`'s configured credentials, whereas a direct `curl` request does not automatically inherit them.
7. Keep the proxy local and avoid permissive access settings outside a controlled lab.
