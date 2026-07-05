# Kubernetes Cheatsheet

> A practical `kubectl` reference for everyday cluster work — inspecting pods, debugging networking, cleaning up messes, and more. Commands are cross-platform (macOS,
> Windows, Linux), with OS-specific notes called out where useful.

---

## Setup & Context

```bash
kubectl config get-contexts                 # list contexts
kubectl config current-context              # show active context
kubectl config use-context <ctx>            # switch context
kubectl config set-context --current --namespace=<ns>   # set default namespace
kubectl cluster-info                         # cluster endpoints
kubectl version --short                      # client + server versions
kubectl api-resources                        # list all resource types (+ short names)
```

> **Tip:** **Alias `k=kubectl`** and enable completion (see Tips). [`kubectx`/`kubens`](https://github.com/ahmetb/kubectx) also make context and namespace switching faster.

---

## Inspecting Resources

```bash
kubectl get pods                            # pods in current namespace
kubectl get pods -A                         # all namespaces
kubectl get pods -o wide                    # + node & IP
kubectl get pods -w                         # watch live
kubectl get all                             # common resources at once
kubectl describe pod <pod>                  # events + full spec
kubectl get pod <pod> -o yaml               # raw manifest
kubectl get events --sort-by=.lastTimestamp # recent events, newest last
```

### Handy selectors & filters

```bash
kubectl get pods -l app=api                       # by label
kubectl get pods --field-selector=status.phase=Running
kubectl get pods --show-labels
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
kubectl get pods --sort-by=.status.startTime
```

> **Tip:** This repo's `scripts/ops/k8s/` has ready-made tools for namespace audits, image tags, HTTPRoute maps, pod cleanup, Kafka tests, smart restarts, fast exec, port forwarding, and secret extraction.

---

## Logs & Exec

```bash
kubectl logs <pod>                          # logs
kubectl logs <pod> -f                       # follow (tail -f)
kubectl logs <pod> -c <container>           # a specific container
kubectl logs <pod> --previous               # logs from the crashed instance
kubectl logs -l app=api --tail=100 --all-containers  # by label
kubectl exec -it <pod> -- bash              # shell into pod (fallback: sh)
kubectl exec <pod> -- env                   # run a one-off command
kubectl attach -it <pod>                    # attach to main process
```

> **Tip:** `kubectl logs --since=1h` or `--since-time=<RFC3339>` scopes logs by time. Add `--timestamps` to prefix each line.

---

## Creating & Applying

```bash
kubectl apply -f manifest.yaml              # declarative create/update
kubectl apply -f ./dir/                     # apply a whole directory
kubectl apply -k ./overlays/prod            # apply a Kustomize overlay
kubectl delete -f manifest.yaml             # delete what a manifest defines
kubectl create deployment web --image=nginx # quick imperative create
kubectl run tmp --rm -it --image=busybox -- sh   # ephemeral throwaway pod
kubectl diff -f manifest.yaml               # preview changes before apply
```

> **Tip:** Prefer `apply` (declarative) over `create` in real workflows because it's idempotent and versionable.

---

## Editing & Scaling

```bash
kubectl edit deployment <name>              # live-edit in $EDITOR
kubectl scale deployment <name> --replicas=3
kubectl set image deployment/<name> <container>=<image>:<tag>
kubectl rollout restart deployment/<name>   # zero-downtime restart
kubectl rollout status deployment/<name>    # follow a rollout
kubectl rollout history deployment/<name>   # revisions
kubectl rollout undo deployment/<name>      # roll back to previous
kubectl rollout undo deployment/<name> --to-revision=2
kubectl annotate / kubectl label ...        # add metadata
```

---

## Networking & Access

```bash
kubectl get svc                             # services
kubectl get ingress                         # ingresses
kubectl get endpoints <svc>                 # backing pod IPs
kubectl port-forward deployment/<name> 8080:8080   # forward to localhost
kubectl port-forward svc/<name> 8080:80
kubectl get httproutes.gateway.networking.k8s.io   # Gateway API routes
```

### Debug connectivity from inside the cluster

```bash
# HTTP check against an internal service
kubectl run curl --rm -it --image=curlimages/curl -- \
  curl -ivs http://my-svc:8080/health

# Raw TCP port check
kubectl run nettest --rm -it --image=busybox -- \
  nc -zv -w 5 my-host 5432
```

> **Tip:** DNS inside the cluster uses `<service>.<namespace>.svc.cluster.local`. Test it with `nslookup` from a busybox pod.

---

## Secrets & ConfigMaps

```bash
kubectl get secret <name> -o jsonpath='{.data.PASSWORD}' | base64 -d   # decode one key
kubectl get secret <name> -o go-template='{{range $k,$v := .data}}{{$k}}={{$v | base64decode}}{{"\n"}}{{end}}'
kubectl create secret generic app --from-literal=KEY=value
kubectl create secret generic app --from-env-file=.env
kubectl get configmap <name> -o yaml
kubectl create configmap app --from-file=config.properties
```

> **Warning:** Secret `data` values are **base64-encoded, not encrypted**. Anyone with `get secret` RBAC can read them. Handle decoded output with care and never commit it.

---

## Resource Usage & Health

```bash
kubectl top nodes                           # node CPU/memory (needs metrics-server)
kubectl top pods                            # pod CPU/memory
kubectl top pods --containers               # per-container
kubectl get pods --field-selector=status.phase!=Running   # non-running pods
kubectl describe node <node>                # capacity, allocations, taints
kubectl get pods -o wide | grep -v Running  # quick anomaly scan
```

---

## Cleaning Up

```bash
kubectl delete pod <pod>                              # delete a pod
kubectl delete pod <pod> --grace-period=0 --force     # force delete (stuck pods)
kubectl delete pods --field-selector=status.phase=Succeeded   # finished pods
kubectl delete all -l app=old-app                     # everything with a label
kubectl get pods | grep Evicted | awk '{print $1}' | xargs kubectl delete pod
```

> **Tip:** This repo's `scripts/ops/k8s/k8s-pod-cleaner/` can purge `Evicted`, `Completed`, `Error`, and `OOMKilled` pods for you.

---

## Debugging Workflow

| Symptom               | Investigate with                                    |
|-----------------------|-----------------------------------------------------|
| Pod won't start       | `kubectl describe pod <pod>` (check Events)         |
| CrashLoopBackOff      | `kubectl logs <pod> --previous`                     |
| Pending forever       | `describe pod` → scheduling/resource/taint issues   |
| ImagePullBackOff      | `describe pod` → image name/registry auth           |
| Can't reach a service | check `endpoints`, selector labels, NetworkPolicies |
| OOMKilled             | `describe pod` → Last State + memory limits         |
| Node issues           | `kubectl describe node`, `kubectl top nodes`        |

```bash
# Ephemeral debug container attached to a running pod (K8s 1.23+)
kubectl debug -it <pod> --image=busybox --target=<container>

# Debug a node by launching a privileged pod on it
kubectl debug node/<node> -it --image=busybox
```

---

## Common Short Names

| Short | Full       | Short    | Full                   |
|-------|------------|----------|------------------------|
| `po`  | pods       | `deploy` | deployments            |
| `svc` | services   | `rs`     | replicasets            |
| `ns`  | namespaces | `sts`    | statefulsets           |
| `cm`  | configmaps | `ds`     | daemonsets             |
| `ing` | ingresses  | `pvc`    | persistentvolumeclaims |
| `no`  | nodes      | `sa`     | serviceaccounts        |

Run `kubectl api-resources` for the complete list.

---

## Tips & Tricks

* **Alias + completion** — huge quality-of-life boost:
  ```bash
  # ~/.bashrc or ~/.zshrc
  alias k=kubectl
  source <(kubectl completion bash)      # or: zsh
  complete -o default -F __start_kubectl k
  ```
* **Namespace once**: `kubectl config set-context --current --namespace=<ns>` beats typing `-n` every time.
* **Explain any field**: `kubectl explain pod.spec.containers.resources` — inline schema docs.
* **Dry run a manifest**: `kubectl apply -f x.yaml --dry-run=server` validates without applying.
* **Generate YAML fast**: `kubectl create deployment web --image=nginx --dry-run=client -o yaml > deploy.yaml`.
* **Custom columns**: `kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase`.
* **Watch with context**: `watch kubectl get pods` (or `kubectl get pods -w`).
* **JSONPath** for scripting: `kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'`.
* **Copy files**: `kubectl cp <ns>/<pod>:/path/file ./file` (needs `tar` in the container).
* **Tooling**: [`k9s`](https://k9scli.io/) (terminal UI), [`stern`](https://github.com/stern/stern) (multi-pod logs), [`kubectx`/`kubens`](https://github.com/ahmetb/kubectx), and [
  `kubecolor`](https://github.com/kubecolor/kubecolor) are all worth installing.

---

## Cross-Platform Notes

* **Install kubectl**:
    * macOS: `brew install kubectl`
    * Windows: `choco install kubernetes-cli` or `winget install Kubernetes.kubectl`
    * Linux: `sudo apt-get install -y kubectl` (or the official binary/curl method)
* **`base64 -d`** works on macOS/Linux; on Windows use PowerShell:
  `[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("..."))`.
* **kubeconfig location**: `~/.kube/config` (macOS/Linux) or `%USERPROFILE%\.kube\config` (Windows). Merge multiple with `KUBECONFIG=a:b kubectl config view --flatten`.
* **Line endings**: keep manifest YAML as LF; some tools choke on CRLF (`git config core.autocrlf` helps on Windows).

---

## Quick Reference: "How Do I…?"

| I want to…                         | Do this                                                         |
|------------------------------------|-----------------------------------------------------------------|
| See why a pod is broken            | `kubectl describe pod <pod>`                                    |
| Read logs of a crashed pod         | `kubectl logs <pod> --previous`                                 |
| Get a shell in a pod               | `kubectl exec -it <pod> -- bash`                                |
| Restart a deployment (no downtime) | `kubectl rollout restart deployment/<name>`                     |
| Roll back a bad deploy             | `kubectl rollout undo deployment/<name>`                        |
| Reach a service locally            | `kubectl port-forward svc/<name> 8080:80`                       |
| Decode a secret                    | `kubectl get secret <n> -o jsonpath='{.data.KEY}' \| base64 -d` |
| Delete stuck pods                  | `kubectl delete pod <pod> --grace-period=0 --force`             |
| Test in-cluster connectivity       | `kubectl run tmp --rm -it --image=busybox -- sh`                |

---

Crafted with ☕ and a healthy dose of laziness by Anthony Lewandowski.
