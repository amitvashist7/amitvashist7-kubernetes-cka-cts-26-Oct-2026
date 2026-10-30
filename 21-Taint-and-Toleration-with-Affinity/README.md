# Kubernetes Taints, Tolerations & Node Affinity

## 📌 Overview

This lab demonstrates how to control Pod scheduling in Kubernetes using three important scheduling mechanisms:

1. **Node Affinity** — Controls which nodes a Pod prefers or is allowed to run on.
2. **Taints and Tolerations** — Controls which Pods can be scheduled onto specific nodes.
3. **Affinity with Tolerations** — Combines node selection rules with node access restrictions.

These mechanisms are useful for workload isolation, dedicated infrastructure, environment separation, and production Kubernetes cluster management.

## 🎯 Learning Objectives

By completing this lab, you will learn how to:

- Configure Node Affinity in Pod specifications.
- Apply taints to Kubernetes worker nodes.
- Configure tolerations to allow Pods to run on tainted nodes.
- Understand the difference between node labels, affinity, taints, and tolerations.
- Observe Pod scheduling and placement using `kubectl`.
- Troubleshoot Pods that remain in the `Pending` state.

---

## 🏗️ Lab Structure

```text
21-Taint-and-Toleration-with-Affinity/
│
├── 01-Affinity/
│   ├── 01-helloworld-affinity.yaml
│   └── 02-gray-deployment.yaml
│
├── 02-Taint-n-Toleration/
│   ├── 01-helloworld-tolerations.yaml
│   └── 02-gray-deployment.yaml
│
└── 03-Affinity-with-Toleration/
    ├── 01-helloworld-tolerations.yaml
    └── 02-gray-deployment.yaml
```

**Note:** The directory and manifest names reflect the lab structure used in the exercises. Verify that the YAML files exist before applying them.

---

# Lab 1: Node Affinity

## 1. Problem Statement

A Kubernetes cluster contains multiple worker nodes, but a workload must run only on nodes that meet specific requirements.

For example:
- Run application workloads on nodes designated for a particular team.
- Schedule memory-intensive workloads on suitable infrastructure.
- Prefer certain nodes without completely restricting scheduling to them.

Without scheduling constraints, Kubernetes may place a Pod on any eligible node.

## 2. Solution: Configure Node Affinity

Node Affinity allows you to express node-selection rules in a Pod specification.

Two primary types are available:

| Affinity Type | Behavior |
|---|---|
| `requiredDuringSchedulingIgnoredDuringExecution` | The node must satisfy the specified conditions when scheduling occurs. |
| `preferredDuringSchedulingIgnoredDuringExecution` | The scheduler prefers matching nodes but can choose another eligible node. |

The `IgnoredDuringExecution` suffix means that a change to node labels after scheduling does not, by itself, evict the existing Pod.

## 3. Navigate to the Lab

```bash
cd 21-Taint-and-Toleration-with-Affinity/01-Affinity/
ls
```

Inspect the manifest:

```bash
cat 01-helloworld-affinity.yaml
```

## 4. Deploy the Application

```bash
kubectl apply -f 01-helloworld-affinity.yaml
```

Check the Pod:

```bash
kubectl get pods
kubectl get pods -o wide
```

The `-o wide` option displays additional information, including the node hosting each Pod.

Deploy the second workload:

```bash
kubectl apply -f 02-gray-deployment.yaml
kubectl get pods -o wide
```

## 5. Validate the Result

Check the following:

- Is the Pod in the `Running` state?
- Which worker node hosts the Pod?
- Does the selected node satisfy the affinity rules?
- Does the Pod remain `Pending` because no eligible node satisfies the requirements?

Inspect scheduling events when needed:

```bash
kubectl describe pod <pod-name>
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 6. Clean Up

```bash
kubectl delete -f 01-Affinity/
```

**Expected outcome:** You understand how node affinity influences Pod placement and how to validate scheduling decisions.

---

# Lab 2: Taints and Tolerations

## 1. Problem Statement

Suppose a Kubernetes cluster contains dedicated worker nodes for production workloads.

You want to prevent ordinary applications from being scheduled on those nodes while allowing explicitly authorized workloads to use them.

Node Affinity alone does not prevent other Pods from running on a matching node.

## 2. Solution: Taints and Tolerations

Taints and tolerations provide a mechanism for restricting scheduling.

- **Taint:** Applied to a node to repel Pods that do not tolerate it.
- **Toleration:** Defined in a Pod specification to allow the Pod to tolerate a matching taint.

A toleration does not guarantee that a Pod will be scheduled on the tainted node. Other scheduling constraints still apply.

### Common Taint Effects

| Effect | Behavior |
|---|---|
| `NoSchedule` | Prevents new Pods without a matching toleration from being scheduled on the node. |
| `PreferNoSchedule` | Tells the scheduler to avoid placing Pods on the node when reasonably possible. |
| `NoExecute` | Prevents scheduling of non-tolerating Pods and can evict existing non-tolerating Pods. |

## 3. Apply a Taint

Navigate to the lab:

```bash
cd 21-Taint-and-Toleration-with-Affinity/02-Taint-n-Toleration/
```

Inspect the configuration:

```bash
cat 01-helloworld-tolerations.yaml
```

Apply a `NoSchedule` taint to a worker node:

```bash
kubectl taint node k8s-worker1 app=myapp:NoSchedule
```

The original lab also attempts to taint another node:

```bash
kubectl taint node k8s-worker app=myapp:NoSchedule
```

**Important:** Confirm the actual node names first:

```bash
kubectl get nodes
```

If `k8s-worker` does not exist, Kubernetes will return a node-not-found error. Use the correct node name from your cluster.

## 4. Deploy a Pod with Tolerations

```bash
kubectl apply -f 01-helloworld-tolerations.yaml
```

Check the scheduling result:

```bash
kubectl get pods
kubectl get pods -o wide
```

Inspect the deployment manifest:

```bash
cat 02-gray-deployment.yaml
```

Deploy the second workload:

```bash
kubectl apply -f 02-gray-deployment.yaml
kubectl get pods -o wide
```

### Example Toleration

A Pod tolerating the taint `app=myapp:NoSchedule` can use the following configuration:

```yaml
spec:
  tolerations:
    - key: "app"
      operator: "Equal"
      value: "myapp"
      effect: "NoSchedule"
```

This toleration matches the specified key, value, and effect.

A matching toleration makes the node eligible with respect to that taint, but it does not force the Pod onto that node.

## 5. Validate the Result

Inspect the taint:

```bash
kubectl describe node k8s-worker1
```

Check Pod placement:

```bash
kubectl get pods -o wide
```

Inspect a Pod that cannot be scheduled:

```bash
kubectl describe pod <pod-name>
```

Look for events such as:

```text
FailedScheduling
```

The event message usually explains whether a taint, affinity rule, resource constraint, or another scheduling condition is preventing placement.

## 6. Clean Up

```bash
kubectl delete -f 02-Taint-n-Toleration/
```

Remove the taint separately if it remains on the node:

```bash
kubectl taint node k8s-worker1 app=myapp:NoSchedule-
```

Repeat for any other node on which you successfully applied the same taint.

**Expected outcome:** You understand how taints repel non-tolerating Pods and how tolerations allow eligible Pods to use tainted nodes.

---

# Lab 3: Affinity with Tolerations

## 1. Problem Statement

In a production environment, a team may need both of the following:

1. A workload must run only on nodes designated for its team.
2. Those nodes must reject workloads that have not been explicitly authorized.

Tolerations alone do not select a node, and affinity alone does not repel unrelated Pods.

## 2. Solution: Combine Affinity and Tolerations

Use both mechanisms in the Pod specification:

- **Node Affinity:** Selects nodes that match the required labels.
- **Tolerations:** Allows the Pod to tolerate the required node taints.

For example, a workload might require a node labeled `team=platform` and tolerate the taint `app=myapp:NoSchedule`.

Both conditions must be satisfied for that node to be eligible.

## 3. Inspect Node Labels

Navigate to the lab:

```bash
cd 21-Taint-and-Toleration-with-Affinity/03-Affinity-with-Toleration/
```

List nodes and their labels:

```bash
kubectl get nodes --show-labels
```

Search for team-related labels:

```bash
kubectl get nodes --show-labels | grep -i team
```

This helps identify which nodes have the labels needed by the affinity rules.

## 4. Apply Node Taints

Apply the first taint:

```bash
kubectl taint node k8s-worker2 app=myapp:NoSchedule
```

Check the node names before continuing:

```bash
kubectl get nodes
```

## 5. Deploy the Tolerating Workload

```bash
kubectl apply -f 01-helloworld-tolerations.yaml
kubectl get pods -o wide
```

Observe where the Pod is scheduled.

## 6. Deploy the Second Workload

```bash
kubectl apply -f 02-gray-deployment.yaml
kubectl get pods -o wide
```

Delete the second deployment when you need to repeat the experiment:

```bash
kubectl delete -f 02-gray-deployment.yaml
```

## 7. Test a Different Taint

Apply a second taint to another worker node:

```bash
kubectl taint node k8s-worker3 app1=myapp:NoSchedule
```

Deploy the second workload again:

```bash
kubectl apply -f 02-gray-deployment.yaml
kubectl get pods -o wide
```

**Important:** This is a different taint from `app=myapp:NoSchedule`.

The new taint has:
- Key: `app1`
- Value: `myapp`
- Effect: `NoSchedule`

A toleration for `app=myapp:NoSchedule` will not match this new taint. The Pod must tolerate the actual taint on the node, or the scheduler will treat that taint as an unsatisfied scheduling constraint.

## 8. Validate the Result

```bash
kubectl get nodes --show-labels
kubectl get pods -o wide
kubectl describe pod <pod-name>
kubectl describe node k8s-worker2
kubectl describe node k8s-worker3
```

Verify that:

- Node labels match the affinity requirements.
- Pod tolerations match the node taints.
- Available node resources are sufficient.
- No other scheduling constraints prevent placement.

**Expected outcome:** You understand how to combine node selection and scheduling restrictions to isolate workloads.

---

# 🧠 Key Concepts: Quick Comparison

| Feature | Node Affinity | Taints | Tolerations |
|---|---|---|---|
| Primary purpose | Select suitable nodes | Repel non-matching Pods | Allow Pods to tolerate taints |
| Configured on | Pod specification | Node | Pod specification |
| Forces placement? | Required affinity restricts eligible nodes | No | No |
| Prevents unrelated Pods from scheduling? | No | Yes, with applicable effects | No |
| Supports workload isolation? | Yes | Yes | Yes, when combined with taints |
| Common use case | Select nodes by team, hardware, or environment | Reserve nodes for dedicated workloads | Allow authorized workloads onto reserved nodes |

## 🔑 Remember

**Affinity attracts; taints repel; tolerations permit.**

For strict workload isolation, use node labels, required node affinity, and matching tolerations alongside taints.

---

# 🔍 Troubleshooting Guide

## Issue 1: Pod Stuck in Pending

Check the Pod:

```bash
kubectl get pods
kubectl describe pod <pod-name>
```

**Possible causes:**
- Required node affinity matches no nodes.
- The Pod does not tolerate a node taint.
- Worker nodes lack sufficient CPU or memory.
- Other scheduling constraints prevent placement.

## Issue 2: Pod Runs on an Unexpected Node

Check placement:

```bash
kubectl get pods -o wide
```

Review the Pod configuration:

```bash
kubectl get pod <pod-name> -o yaml
```

**Possible causes:**
- Affinity is configured as a preference rather than a requirement.
- The Pod has tolerations but no node-selection constraint.
- Multiple nodes satisfy the scheduling requirements.

## Issue 3: Taint Command Fails

List the available nodes:

```bash
kubectl get nodes
```

Inspect existing taints:

```bash
kubectl describe node <node-name>
```

Use the exact node name and confirm whether the taint already exists.

## Issue 4: Pod Cannot Tolerate the Taint

Compare the node taint and the Pod toleration.

For an `Equal` toleration, the key, value, and effect must match.

For example:

```text
Node taint:       app=myapp:NoSchedule
Pod toleration:   app=myapp:NoSchedule
```

A toleration for `app1=myapp:NoSchedule` is different and will not match the taint above.

---

# 🏭 Production Readiness

When applying these concepts to production clusters, consider the following:

- **Workload isolation:** Use dedicated nodes for critical workloads, regulated environments, or specialized hardware.
- **Scheduling reliability:** Avoid overly restrictive affinity rules that leave workloads unschedulable during node failures.
- **Resource capacity:** Ensure eligible nodes have sufficient CPU, memory, and storage.
- **Security:** Do not treat taints and tolerations as security boundaries; use Kubernetes RBAC, admission controls, and appropriate workload isolation.
- **Observability:** Monitor Pods in `Pending`, scheduling failures, node capacity, and node condition changes.
- **Change management:** Validate scheduling policies in a non-production environment before applying them to production.
- **Cleanup:** Remove temporary taints and test workloads after completing the lab.

## 📊 Success Criteria

The lab is complete when you can demonstrate that:

1. A Pod is scheduled according to its node affinity.
2. A node with a `NoSchedule` taint rejects a Pod that lacks a matching toleration.
3. A Pod with a matching toleration can be scheduled on a tainted node if other scheduling requirements are satisfied.
4. Combining affinity and tolerations restricts placement to eligible nodes.
5. You can diagnose scheduling failures using `kubectl describe pod` and node details.

---

# 🧹 Final Cleanup

Remove lab resources if they are still present:

```bash
kubectl delete -f 01-Affinity/ --ignore-not-found=true
kubectl delete -f 02-Taint-n-Toleration/ --ignore-not-found=true
kubectl delete -f 03-Affinity-with-Toleration/ --ignore-not-found=true
```

Remove the test taints that were successfully created:

```bash
kubectl taint node k8s-worker1 app=myapp:NoSchedule-
kubectl taint node k8s-worker2 app=myapp:NoSchedule-
kubectl taint node k8s-worker3 app1=myapp:NoSchedule-
```

If you tainted additional nodes during the exercise, remove those taints as well.

**Warning:** Run cleanup commands only after confirming that the affected resources and taints belong to this lab. The node taints may affect other workloads.

---

## 📚 Further Learning

Continue with these Kubernetes topics:

- Pod scheduling and the Kubernetes scheduler
- Node selectors and node labels
- Pod affinity and anti-affinity
- Topology spread constraints
- Resource requests and limits
- Priority classes and preemption
- Production workload isolation

**Lab:** `21-Taint-and-Toleration-with-Affinity`

**Focus:** Understanding and controlling Kubernetes workload placement through affinity, taints, and tolerations.
