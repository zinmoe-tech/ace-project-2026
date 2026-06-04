Step 1 — Create the kind cluster
# Make sure you're inside the repo root
cd k8s-idp

# Create the cluster
kind create cluster --config kind-config.yaml

kubectl get nodes

You'll see this — NotReady is expected because there's no CNI yet:

NAME                        STATUS     ROLES           AGE
idp-cluster-control-plane   NotReady   control-plane   30s
idp-cluster-worker          NotReady   <none>          28s
idp-cluster-worker2         NotReady   <none>          28s
idp-cluster-worker3         NotReady   <none>          28s

Step 2 — Install the Cilium CLI
This is a standalone tool on your laptop — separate from the cluster:

# macOS
brew install cilium-cli

# Verify
cilium version --client

Expected output:

cilium-cli: v0.16.10

Step 3 — Add the Cilium Helm repo

# Add Cilium's official Helm repo
helm repo add cilium https://helm.cilium.io/

# Fetch latest chart index
helm repo update

# Confirm it's there
helm search repo cilium/cilium

ZMZin MoePro planKubernetes Project/Kubernetes project for interview preparationShareClaude finished the responseYou said: I want to implement impressive kubernetes full project for interview purpose.I want to implement impressive kubernetes full project for interview purpose.
Guide meJun 1You said: Q: What's your current Kubernetes experience level?Q: What's your current Kubernetes experience level?
A: Advanced (familiar with operators, RBAC, etc.)Q: What role are you targeting?
A: DevOps / Platform EngineerQ: Which areas do you want to showcase? (Select all that apply)
A: Security (RBAC, secrets), Auto-scaling & HA, Observability (monitoring/logging)Jun 1Claude responded: Great choices!Great choices! Here's a comprehensive project plan tailored for a Senior DevOps / Platform Engineer interview.

🏗️ Project: "Production-Grade Internal Developer Platform (IDP)"
The concept: a multi-tenant Kubernetes platform where teams self-serve app deployments, with full observability, security hardening, and auto-scaling — exactly what a Platform Engineer owns in the real world.

📐 Architecture OverviewVConnecting to visualize...
Click any component in the diagram to deep-dive into that topic.


🗂️ Project Structure
k8s-idp/
├── clusters/
│   └── prod/
│       ├── namespaces/          # Namespace manifests + quotas
│       ├── cluster-wide/        # RBAC ClusterRoles, PSA labels
│       └── argocd/              # App of Apps root
├── platform/
│   ├── ingress-nginx/           # Helm values
│   ├── cert-manager/            # ClusterIssuer, Lets Encrypt
│   ├── external-secrets/        # SecretStore → Vault/SSM
│   ├── opa-gatekeeper/          # ConstraintTemplates + Constraints
│   ├── karpenter/               # NodePool + EC2NodeClass
│   └── observability/
│       ├── prometheus-stack/    # kube-prometheus-stack values
│       ├── loki-stack/
│       ├── tempo/
│       └── slo-alerts/          # PrometheusRule for burn rates
└── apps/
    ├── team-a/
    │   ├── deployment.yaml
    │   ├── hpa.yaml
    │   ├── networkpolicy.yaml
    │   └── externalsecret.yaml
    └── team-b/
        └── ...

🔑 Key Technical Decisions to Articulate in Interviews
Security

Why External Secrets over native Secrets (encryption at rest, audit trail, rotation)
NetworkPolicy deny-all default + explicit allow rules between namespaces
OPA ConstraintTemplate enforcing: no latest tag, required resource limits, required labels

Auto-scaling & HA

HPA on CPU + custom Prometheus metrics via the custom metrics API adapter
KEDA for event-driven scaling (e.g. Kafka consumer lag, SQS queue depth)
Karpenter over Cluster Autoscaler — faster node provisioning, topology-aware bin-packing
PodDisruptionBudgets on every Deployment, topologySpreadConstraints across AZs

Observability

The "3 pillars" — metrics (Prometheus), logs (Loki), traces (Tempo) with correlation IDs tying all three
SLO-based alerting using multi-window burn-rate rules (Google SRE style)
ServiceMonitor CRDs for automatic scrape config per team


🚀 Recommended Build Order

Week 1 — Cluster bootstrap (kind/k3d locally or EKS), ArgoCD, ingress + cert-manager
Week 2 — Multi-tenant namespaces, RBAC, NetworkPolicies, OPA policies
Week 3 — Observability stack (Prometheus, Grafana, Loki), SLO alerts
Week 4 — External Secrets, HPA + KEDA, Karpenter, chaos testing with Chaos Mesh


💬 Strong Interview Talking Points

"I designed the platform around GitOps-first — no kubectl apply in production, everything through ArgoCD sync waves."
"We used OPA Gatekeeper admission webhooks so teams can't accidentally deploy without resource limits or security contexts."
"For observability, I correlated logs, metrics, and traces using a shared trace_id header propagated by the ingress controller."
"We chose Karpenter because it cuts node provisioning time from 4+ minutes to under 60 seconds and supports spot interruption handling natively."


Want me to generate actual YAML manifests for any of these components, or walk through a specific layer in depth?You said: Can you elaborate HPA and KEDA as I don't know it?Can you elaborate HPA and KEDA as I don't know it?Jun 1Claude responded: Let me break both down visually so the difference is crystal clear.Let me break both down visually so the difference is crystal clear.
HPA — Horizontal Pod Autoscaler
HPA is Kubernetes-native. It watches a metric and adjusts replica count on your Deployment.HPA works on a simple feedback loop: it reads a metric, compares it to a target, and adjusts pod count. Here's how that loop flows:VConnecting to visualize...The formula is literally: desiredReplicas = ceil(currentMetricValue / targetValue × currentReplicas). If CPU target is 50% and your 4 pods are at 80% average, HPA calculates ceil(80/50 × 4) = 7 replicas and patches the Deployment. A 15-second scrape loop does this continuously.

KEDA — Kubernetes Event-Driven Autoscaler
KEDA does something HPA cannot: it scales based on external event sources, not just pod-internal metrics. It also allows scaling down to zero — crucial for cost savings.
Think of it this way: HPA asks "how busy are my pods right now?", while KEDA asks "how much work is waiting to be done?"VConnecting to visualize...KEDA installs a ScaledObject CRD. Under the hood it creates and manages a standard HPA on your behalf — but it feeds that HPA metrics pulled from external sources like Kafka lag, SQS queue depth, or a Prometheus query. When the queue empties, KEDA can scale the Deployment all the way to zero pods, which plain HPA can never do (minimum is 1).

Side-by-side comparison
HPAKEDAMetric sourcePod CPU/memory, custom metrics APIAny external source (Kafka, SQS, Redis, Prometheus, cron...)Scale to zeroNo (min 1 pod)YesBuilt-in to K8sYesNo — installed as an operatorConfig objectHorizontalPodAutoscalerScaledObject / ScaledJobBest forWeb services, latency-sensitive APIsWorkers, queue consumers, batch jobs

Sample manifests
HPA — scale on CPU:
yamlapiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  minReplicas: 2
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
KEDA ScaledObject — scale on Kafka consumer lag:
yamlapiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: worker-scaledobject
spec:
  scaleTargetRef:
    name: queue-worker
  minReplicaCount: 0      # scale to zero!
  maxReplicaCount: 30
  triggers:
  - type: kafka
    metadata:
      bootstrapServers: kafka:9092
      consumerGroup: my-group
      topic: orders
      lagThreshold: "50"   # 1 pod per 50 messages of lag

Interview-ready talking points

"I use HPA for my stateless API pods and KEDA for my queue consumers — they solve different problems."
"KEDA's scale-to-zero saved us significant cost for overnight batch jobs that otherwise kept idle pods running."
"KEDA actually manages an HPA internally — it doesn't replace the HPA reconciler, it drives it with external metrics."
"One gotcha: the first scale-up from zero has cold-start latency. For latency-sensitive paths, I keep minReplicaCount: 1."

Want me to show how to add a custom Prometheus metric to HPA using the custom.metrics.k8s.io API adapter?You said: Should I start from where?Should I start from where?Jun 2Claude responded: Great question — given you're advanced, you don't need to start from scratch on basics.Great question — given you're advanced, you don't need to start from scratch on basics. Here's the recommended path:

Start here: local cluster in Day 1
bash# Option A — kind (simplest, runs in Docker)
kind create cluster --config kind-config.yaml

# Option B — k3d (lighter, faster)
k3d cluster create idp-cluster --agents 3
Use kind or k3d locally to avoid cloud costs while building. Switch to EKS/GKE only when you want to demo Karpenter (which needs real EC2 nodes).

Recommended build sequence
Phase 1 — Foundation (Day 1–2)
Bootstrap the cluster and GitOps layer first. Everything else deploys through it.

Create the kind/k3d cluster
Install ArgoCD (helm install argocd)
Create your Git repo with the folder structure from earlier
Set up the App of Apps pattern — one root ArgoCD Application that watches your clusters/prod/argocd/ folder and auto-syncs everything else

Once this is working, you never kubectl apply manually again — you push to Git and ArgoCD syncs. That alone is a strong interview talking point.
Phase 2 — Multi-tenancy (Day 3)

Create team-a and team-b namespaces with ResourceQuotas and LimitRanges
Write ClusterRole + RoleBinding for dev/viewer roles
Add NetworkPolicy deny-all defaults + explicit allow rules

Phase 3 — Security (Day 4)

Install OPA Gatekeeper and write 2–3 ConstraintTemplates:

Reject images with latest tag
Require resources.limits on all containers
Require specific labels (team, app)


Install External Secrets Operator + connect to a secret store (Vault works locally via Docker, or use AWS SSM if you have an account)

Phase 4 — Observability (Day 5–6)

Install kube-prometheus-stack (Prometheus + Grafana + Alertmanager in one Helm chart)
Install Loki + Promtail for logs
Write a custom PrometheusRule for a burn-rate SLO alert
Import a Kubernetes dashboard in Grafana

Phase 5 — Autoscaling (Day 7)

Deploy a sample app with HPA on CPU
Install KEDA and write a ScaledObject using the Prometheus scaler (so it works locally without Kafka)
Simulate load with kubectl run -it load --image=busybox and watch it scale


The single most important first command
bashmkdir k8s-idp && cd k8s-idp
git init
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd -n argocd --create-namespace
Get ArgoCD running first — then everything else you build gets committed to Git and deployed through it, which makes the whole project feel production-grade from day one.

What to have ready for the interview

A running cluster you can kubectl into live
ArgoCD UI you can screen-share showing synced apps
A Grafana dashboard with real metrics
One OPA policy that actively blocks a bad deployment (kubectl apply a pod with latest tag and show it being rejected)
The GitHub repo with clean folder structure as a portfolio piece

Want me to generate the ArgoCD App of Apps manifests and the kind cluster config to get you started right now?You said: Let me start from phase-1 and I want to kind cluster locally.Let me start from phase-1 and I want to kind cluster locally.Jun 2Claude responded: Let's get your local cluster running.Let's get your local cluster running. Here's everything you need for Phase 1.
Step 1 — Prerequisites
bash# Install kind
brew install kind        # macOS
# or
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
chmod +x ./kind && mv ./kind /usr/local/bin/kind

# Install kubectl
brew install kubectl

# Install helm
brew install helm

# Verify
kind version && kubectl version --client && helm version

Step 2 — kind cluster config
This config gives you 1 control-plane + 3 worker nodes, with port mappings for the ingress controller so you can hit services from your browser.kind-config.yamlCode kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: idp-cluster
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingrbashkind create cluster --config kind-config.yaml
kubectl cluster-info --context kind-idp-cluster
kubectl get nodes
You should see 4 nodes — 1 control-plane, 3 workers — all Ready.

Step 3 — Git repo structure
Set this up before ArgoCD so your first commit is already structured:bootstrap.sh — repo scaffoldingCode #!/bin/bash
set -e

mkdir -p k8s-idp && cd k8s-idp
git init

# Platform tooling (ArgoCD manages these)
mkdir -p platform/argocd
mkdir -p platform/ingress-nginx
mkdir -p platform/cert-manager
mkdir -p platform/observability/prometheus-stack
mkdir -p pbashchmod +x bootstrap.sh && ./bootstrap.sh
# Then push to GitHub
gh repo create k8s-idp --public --source=. --push

Step 4 — Install ArgoCDinstall-argocd.shCode #!/bin/bash
set -e

# Add Helm repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD into its own namespace
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --version 7.3.6 \bashchmod +x install-argocd.sh && ./install-argocd.sh

# In a separate terminal — keep this running
kubectl port-forward svc/argocd-server -n argocd 8080:443
Open https://localhost:8080 → login with admin + the printed password.

Step 5 — App of Apps pattern
This is the key GitOps pattern. One root Application in ArgoCD watches a folder in your repo. Any manifest you add to that folder automatically becomes a managed app.clusters/prod/argocd/root-app.yamlCode apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/k8s-idp   # Apply this once manually — after that, everything is GitOps:
bash# Update the repoURL in root-app.yaml first, then:
kubectl apply -f clusters/prod/argocd/root-app.yaml
Now add child app manifests to clusters/prod/argocd/ and ArgoCD auto-discovers and syncs them. For example, to add ingress-nginx in Phase 2, you just create clusters/prod/argocd/ingress-nginx-app.yaml, commit, and push — ArgoCD does the rest.

Verify everything is healthy
bash# All nodes ready
kubectl get nodes

# ArgoCD pods running
kubectl get pods -n argocd

# ArgoCD CLI login (optional but useful)
brew install argocd
argocd login localhost:8080 --username admin --insecure

# Check root-app synced
argocd app get root-app

Phase 1 done — what you now have

4-node kind cluster with proper labels and ingress port mappings
ArgoCD running and accessible via browser
App of Apps pattern bootstrapped — your GitOps foundation
Clean repo structure ready for Phase 2 additions

Once you confirm your nodes are Ready and ArgoCD UI loads, let me know and we'll move to Phase 2 — namespaces, RBAC, and NetworkPolicies.You said: Actually, I have 10% knowledge ArgoCD.Actually, I have 10% knowledge ArgoCD.Jun 2Claude responded: No problem — let me build your ArgoCD mental model from scratch before we touch any manifests.No problem — let me build your ArgoCD mental model from scratch before we touch any manifests.
What problem does ArgoCD solve?
Without ArgoCD, your deployment workflow looks like this:
you write YAML → kubectl apply -f → cluster changes
The problem: the cluster state lives in someone's terminal. No history, no audit trail, no way to know if someone manually changed something, no automatic recovery if a pod config drifts.
ArgoCD flips this model — Git becomes the single source of truth, and ArgoCD's job is to make the cluster match Git. Always.

The core idea in one sentence

ArgoCD watches a folder in your Git repo and continuously syncs whatever is there into your cluster.


Three concepts you must knowHere are the three concepts you must understand before writing a single ArgoCD manifest:VConnecting to visualize...Now let's look at how the sync loop actually works moment by moment — this is what makes ArgoCD feel like magic when you first see it:VConnecting to visualize...Step through all 5 states — especially step 5, which is the most impressive thing to demo in an interview.

Now the App of Apps pattern — demystified
This is just a clever trick using ArgoCD's own Application resource. Instead of registering every app manually in ArgoCD, you create one "root" Application that points to a folder. ArgoCD syncs that folder — and finds more Application manifests inside it — and syncs those too. It's recursive bootstrapping.
Root Application
  watches → clusters/prod/argocd/
    finds → ingress-app.yaml      → deploys ingress-nginx
    finds → prometheus-app.yaml   → deploys prometheus
    finds → team-a-app.yaml       → deploys team-a workloads
Adding a new platform tool = drop one file in that folder and push. ArgoCD picks it up automatically. No clicking in the UI, no running Helm manually.

The one manifest you need to understand deeply
yamlapiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ingress-nginx          # name shown in ArgoCD UI
  namespace: argocd            # always argocd namespace

spec:
  project: default             # which ArgoCD Project this belongs to

  source:
    repoURL: https://github.com/you/k8s-idp
    targetRevision: HEAD       # branch/tag/commit to watch
    path: platform/ingress-nginx   # folder to sync from

  destination:
    server: https://kubernetes.default.svc   # this cluster
    namespace: ingress-nginx   # deploy into this namespace

  syncPolicy:
    automated:
      prune: true      # delete k8s resources if removed from Git
      selfHeal: true   # revert manual kubectl changes
    syncOptions:
      - CreateNamespace=true   # create namespace if missing
Every app you add to the project will look exactly like this — only name, path, and namespace change. That's the beauty of the pattern.

What to do right now

Run ./install-argocd.sh from earlier
Open https://localhost:8080 and log in
Look at the UI — notice the Applications screen (empty for now) and the Settings → Repositories screen
Apply the root-app.yaml manifest — you'll see it appear in the UI as your first app

Once you see that first green "Synced" badge, the mental model clicks. Tell me when you're at that point and we'll move forward.You said: What is an ArgoCD Project and why do you need it for multi-tenancy?What is an ArgoCD Project and why do you need it for multi-tenancy?Jun 2Claude responded: Great question — this is something most people skip and then regret when they try to give teams isolated access.Great question — this is something most people skip and then regret when they try to give teams isolated access.
The problem without Projects
When you install ArgoCD, everything lands in default project. Any Application can deploy to any namespace, pull from any repo, and any ArgoCD user can see and sync everything. That's fine for a personal cluster — it's a disaster for multi-tenant platforms.
Imagine team-a can accidentally (or intentionally) deploy an Application that targets the argocd namespace itself and overwrites platform config. No bueno.

What an ArgoCD Project actually is
A Project is a security boundary inside ArgoCD. It answers three questions:

Which Git repos is this team allowed to pull from?
Which cluster namespaces is this team allowed to deploy into?
Which Kubernetes resources are allowed or denied?
VConnecting to visualize...The enforcement happens at sync time — ArgoCD refuses to apply a manifest if the destination namespace isn't in the Project's allowlist, even if the Git commit is valid YAML.

The actual manifest — AppProject
The resource kind is AppProject. Here's what it looks like for our IDP:clusters/prod/argocd/project-team-a.yamlCode apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: team-a
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io  # block deletion if apps exist

spec:

  # Human-readable description (shown in UI)
  descripti
The three layers of protection this gives you
What an attacker/accident could tryHow the Project blocks itDeploy into argocd namespace and overwrite platform configdestinations only allows team-a namespaceCreate a ClusterRole to escalate privilegesclusterResourceBlacklist blocks it at syncDeploy from a rogue fork of the reposourceRepos allowlist rejects itteam-a developer syncs team-b's appArgoCD RBAC policies deny cross-project actions

Platform project — the one you own
You also need a platform project for your own tooling (ArgoCD, Prometheus, ingress, etc.) with broader permissions since platform components need cluster-wide access:clusters/prod/argocd/project-platform.yamlCode apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: platform
  namespace: argocd
spec:
  description: "Platform engineering — infra and tooling"

  sourceRepos:
    - https://github.com/YOUR_ORG/k8s-idp

  # Platform tools can deploy 
How it all connects — the full picture
Every Application must declare which Project it belongs to. That's the spec.project field you saw in the earlier manifests:
yaml# This Application is locked inside the team-a project
# ArgoCD will enforce ALL team-a project restrictions on it
spec:
  project: team-a          # <-- links to AppProject
  source:
    path: apps/team-a
  destination:
    namespace: team-a      # must be in project's destinations list
If someone tries to create an Application in project team-a that deploys to namespace team-b, ArgoCD rejects the sync with a clear error:
ComparisonError: application destination {server namespace:team-b}
is not permitted in project 'team-a'

Interview talking point

"I created separate AppProject resources per team with namespace destination allowlists and a clusterResourceBlacklist that prevents teams from creating ClusterRoles or new Namespaces. This means even if a developer pushes a malicious or mistaken manifest, ArgoCD refuses to apply it — the blast radius is contained to their own namespace."

That answer demonstrates you understand the why, not just the how.

Ready to write these manifests into your repo and commit them? Once you do, the root ArgoCD app will auto-discover and sync them — and you'll see the Projects appear in the ArgoCD UI under Settings → Projects.You said: What is an ArgoCD Application resource and what fields does it have?What is an ArgoCD Application resource and what fields does it have?Jun 2Claude responded: The Application resource — the heart of ArgoCDThe Application resource — the heart of ArgoCD
Think of it as a contract written in YAML that tells ArgoCD three things:

Where is the desired state? (Git)
Where should it be applied? (cluster + namespace)
How should it behave? (sync policy)

That's it. Everything else is detail around those three questions.
VConnecting to visualize...Now let's go through every field with a full annotated manifest — the kind you'd actually write for this project:ArgoCD Application — fully annotatedCode apiVersion: argoproj.io/v1alpha1
kind: Application          # always this — not Deployment, not Pod
metadata:
  name: ingress-nginx      # shown in the ArgoCD UI — keep it descriptive
  namespace: argocd        # ALWAYS argocd namespace, not the app 
The fields you'll actually use 90% of the time
Most Applications in the real world use just these:
yamlspec:
  project: platform
  source:
    repoURL: https://github.com/org/repo
    targetRevision: HEAD
    path: platform/some-tool
  destination:
    server: https://kubernetes.default.svc
    namespace: some-namespace
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
The rest — helm, ignoreDifferences, retry — you add only when you need them.

The two flags that trip everyone up
prune: true — without this, if you remove a Deployment from Git, it keeps running in the cluster silently. ArgoCD will show the app as "Synced" but the old pods are still there consuming resources. Always enable this.
selfHeal: true — without this, ArgoCD is just a one-time deploy tool. Someone runs kubectl scale deploy/api --replicas=1 at 2am during an incident, forgets to revert it, and now your cluster state is lying to you. With selfHeal, Git wins every time within 3 minutes.

ignoreDifferences — the hidden gotcha
This one catches everyone. Some controllers legitimately mutate your resources after ArgoCD applies them:

HPA changes spec.replicas on your Deployment
External Secrets Operator fills in Secret.data
Cert-manager adds annotations to Ingress

Without ignoreDifferences, ArgoCD sees these mutations as drift and keeps trying to revert them — causing a fight between ArgoCD and the other controller. The app flaps between Synced and OutOfSync forever.
The fix: tell ArgoCD to ignore those specific JSON paths.

For your IDP project — four Applications to create now
Once you understand the structure, all four follow the same pattern:
Application namepathnamespaceprojectargocd-appsclusters/prod/argocdargocdplatformingress-nginxplatform/ingress-nginxingress-nginxplatformteam-a-appsapps/team-ateam-ateam-ateam-b-appsapps/team-bteam-bteam-b
Want me to generate all four ready-to-commit Application manifests for your repo?You said: k8s-idp/k8s-idp/
├── clusters/
│   └── prod/
│       ├── namespaces/          # Namespace manifests + quotas
│       ├── cluster-wide/        # RBAC ClusterRoles, PSA labels
│       └── argocd/              # App of Apps root
├── platform/
│   ├── ingress-nginx/           # Helm values
│   ├── cert-manager/            # ClusterIssuer, Lets Encrypt
│   ├── external-secrets/        # SecretStore → Vault/SSM
│   ├── opa-gatekeeper/          # ConstraintTemplates + Constraints
│   ├── karpenter/               # NodePool + EC2NodeClass
│   └── observability/
│       ├── prometheus-stack/    # kube-prometheus-stack values
│       ├── loki-stack/
│       ├── tempo/
│       └── slo-alerts/          # PrometheusRule for burn rates
└── apps/
    ├── team-a/
    │   ├── deployment.yaml
    │   ├── hpa.yaml
    │   ├── networkpolicy.yaml
    │   └── externalsecret.yaml
    └── team-b/
        └── ...
can you give me single command to create it?Show moreJun 3Claude responded: That's it.bashmkdir -p k8s-idp/{clusters/prod/{namespaces,cluster-wide,argocd},platform/{ingress-nginx,cert-manager,external-secrets,opa-gatekeeper,karpenter,observability/{prometheus-stack,loki-stack,tempo,slo-alerts}},apps/{team-a,team-b}} && touch k8s-idp/apps/team-a/{deployment.yaml,hpa.yaml,networkpolicy.yaml,externalsecret.yaml}
That's it. One line — brace expansion does all the heavy lifting.
Verify it looks right:
bashfind k8s-idp -type d | sort
Or visually with the tree command:
bashtree k8s-idp
# brew install tree   (if you don't have it)
Then initialize the git repo:
bashcd k8s-idp && git init && git add . && git commit -m "chore: initial repo scaffold"You said: DoneDoneJun 3Claude responded: Perfect.Perfect. Now let's put real content into the repo — starting with the ArgoCD App of Apps.
Step 1 — Add the 4 Application manifests
Run this to create all 4 files at once:
bashcd k8s-idp
1. Root app — watches the argocd folder itself (App of Apps):
bashcat > clusters/prod/argocd/root-app.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/k8s-idp
    targetRevision: HEAD
    path: clusters/prod/argocd
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
2. Platform app — syncs all platform tooling:
bashcat > clusters/prod/argocd/platform-app.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: platform-namespaces
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/k8s-idp
    targetRevision: HEAD
    path: clusters/prod/namespaces
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
3. Team-a app:
bashcat > clusters/prod/argocd/team-a-app.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: team-a-apps
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/k8s-idp
    targetRevision: HEAD
    path: apps/team-a
  destination:
    server: https://kubernetes.default.svc
    namespace: team-a
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
4. Team-b app:
bashcat > clusters/prod/argocd/team-b-app.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: team-b-apps
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/k8s-idp
    targetRevision: HEAD
    path: apps/team-b
  destination:
    server: https://kubernetes.default.svc
    namespace: team-b
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

Step 2 — Add namespace manifests
bashcat > clusters/prod/namespaces/team-a.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: team-a
  labels:
    team: team-a
    pod-security.kubernetes.io/enforce: restricted
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-a-quota
  namespace: team-a
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    pods: "20"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: team-a-limitrange
  namespace: team-a
spec:
  limits:
    - type: Container
      default:
        cpu: 500m
        memory: 256Mi
      defaultRequest:
        cpu: 100m
        memory: 128Mi
EOF
bash# Same for team-b
sed 's/team-a/team-b/g' clusters/prod/namespaces/team-a.yaml \
  > clusters/prod/namespaces/team-b.yaml

Step 3 — Push to GitHub
bash# Replace YOUR_USERNAME first
git remote add origin https://github.com/YOUR_USERNAME/k8s-idp.git

git add .
git commit -m "feat: add App of Apps manifests and namespace quotas"
git push -u origin main

Step 4 — Bootstrap ArgoCD
First install ArgoCD if not done yet:
bashhelm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --set configs.params."server\.insecure"=true \
  --wait

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
Then apply the root app — this one and only manual kubectl apply:
bash# Update YOUR_USERNAME in root-app.yaml first, then:
kubectl apply -f clusters/prod/argocd/root-app.yaml

# Port-forward to see the UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

What you should see in the UI
Open https://localhost:8080 and within 60 seconds you should see:VConnecting to visualize...root-app and platform-namespaces green is the goal right now. The team apps being OutOfSync is expected — the deployment YAML files are empty placeholders.

Quick verify from terminal
bash# Namespaces created by ArgoCD
kubectl get namespaces | grep team

# ResourceQuotas applied
kubectl get resourcequota -n team-a
kubectl get limitrange -n team-a

# All ArgoCD apps
kubectl get applications -n argocd

Once you see the namespaces created and root-app synced green, Phase 1 is complete. Tell me what you see and we'll move to Phase 2 — RBAC, NetworkPolicies, and OPA Gatekeeper.You said: can I add  as yaml file?can I add  as yaml file?Jun 3Claude responded: Yes!Yes! In fact that's the correct GitOps way — never run cat > file.yaml in production. Everything should be a committed YAML file.
Here are all the files for Phase 1, ready to copy into your repo:clusters/prod/argocd/root-app.yamlCode apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/k8s-idp
    clusters/prod/argocd/platform-app.yamlCode apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: platform-namespaces
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/kclusters/prod/argocd/team-a-app.yamlCode apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: team-a-apps
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/k8s-idp
 clusters/prod/argocd/team-b-app.yamlCode apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: team-b-apps
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/k8s-idp
 clusters/prod/namespaces/teams.yamlCode # ── team-a ────────────────────────────────────────────────────────────
apiVersion: v1
kind: Namespace
metadata:
  name: team-a
  labels:
    team: team-a
    pod-security.kubernetes.io/enforce: restricted
---
apiVersion: v1
kind: ResourceQuota
meta
Your folder should look like this now
clusters/prod/
├── argocd/
│   ├── root-app.yaml         ← App of Apps root
│   ├── platform-app.yaml     ← watches clusters/prod/namespaces
│   ├── team-a-app.yaml       ← watches apps/team-a
│   └── team-b-app.yaml       ← watches apps/team-b
└── namespaces/
    └── teams.yaml            ← Namespace + ResourceQuota + LimitRange

Two things to do before committing
1. Replace YOUR_USERNAME in all 4 app files:
bash# Do it in one shot
sed -i 's/YOUR_USERNAME/your-actual-github-username/g' \
  clusters/prod/argocd/*.yaml
2. Commit and push:
bashgit add .
git commit -m "feat: add App of Apps and namespace manifests"
git push origin main
3. Apply root-app once (only ever manually applied file):
bashkubectl apply -f clusters/prod/argocd/root-app.yaml
From this point on — every change is just git push. ArgoCD handles the rest. Ready to move to Phase 2?You said: Can you express the purpose for each file and add description in every line in each yaml file?Can you express the purpose for each file and add description in every line in each yaml file?Jun 3Claude responded: Every file now has a full header explaining its purpose and an inline comment on every single line.clusters/prod/argocd/root-app.yamlCode ∙ Version 2 # ═══════════════════════════════════════════════════════════════════════
# FILE: clusters/prod/argocd/root-app.yaml
#
# PURPOSE:
#   This is the single entry point for the entire GitOps setup.
#   It is the ONLY file you ever apply manually with kubclusters/prod/argocd/platform-app.yamlCode ∙ Version 2 # ═══════════════════════════════════════════════════════════════════════
# FILE: clusters/prod/argocd/platform-app.yaml
#
# PURPOSE:
#   Manages cluster-wide platform infrastructure — specifically the
#   Namespace definitions, ResourceQuotas, and Lclusters/prod/argocd/team-a-app.yamlCode ∙ Version 2 # ═══════════════════════════════════════════════════════════════════════
# FILE: clusters/prod/argocd/team-a-app.yaml
#
# PURPOSE:
#   Manages all Kubernetes workloads owned by team-a.
#   ArgoCD watches the apps/team-a/ folder and syncs whatever
# clusters/prod/argocd/team-b-app.yamlCode ∙ Version 2 # ═══════════════════════════════════════════════════════════════════════
# FILE: clusters/prod/argocd/team-b-app.yaml
#
# PURPOSE:
#   Identical in structure to team-a-app.yaml but scoped to team-b.
#   Each tenant gets their own Application resourcclusters/prod/namespaces/teams.yamlCode ∙ Version 2 # ═══════════════════════════════════════════════════════════════════════
# FILE: clusters/prod/namespaces/teams.yaml
#
# PURPOSE:
#   Defines the Kubernetes namespaces for all tenant teams along with
#   their resource budgets and default container Every file now has a full header explaining its purpose and an inline comment on every single line. Here's a quick summary of what each file does:
FilePurposeroot-app.yamlThe one file you kubectl apply manually. Bootstraps everything else via App of Apps patternplatform-app.yamlPlatform-owned app. Syncs namespace definitions, quotas, limits for all teamsteam-a-app.yamlTenant app for team-a. Watches apps/team-a/ — team owns the contents, platform owns this fileteam-b-app.yamlSame as above but for team-b. Isolated sync history and blast radiusteams.yamlDefines Namespace + ResourceQuota + LimitRange for each team. Central resource governance
Now just:
bash# Replace YOUR_USERNAME in all files
sed -i 's/YOUR_USERNAME/your-github-username/g' clusters/prod/argocd/*.yaml

git add .
git commit -m "feat: add fully annotated App of Apps and namespace manifests"
git push origin main
Ready to install ArgoCD and apply the root app?You said: donedoneJun 3Claude responded: Perfect.Perfect. Now let's get ArgoCD installed and running on your kind cluster.
Step 1 — Install ArgoCD
bash# Add the ArgoCD Helm repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --set configs.params."server\.insecure"=true \
  --wait

# Confirm all pods are running
kubectl get pods -n argocd
You should see 6 pods all in Running state:
argocd-application-controller-0
argocd-applicationset-controller-xxx
argocd-dex-server-xxx
argocd-notifications-controller-xxx
argocd-redis-xxx
argocd-server-xxx

Step 2 — Get the admin password
bashkubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
Copy that password — you'll need it to log in.

Step 3 — Access the UI
bash# Run this in a dedicated terminal — keep it open
kubectl port-forward svc/argocd-server -n argocd 8080:443
Open your browser → https://localhost:8080

Username: admin
Password: from Step 2

Accept the self-signed certificate warning — that's expected locally.

Step 4 — Connect your GitHub repo to ArgoCD
Before applying root-app, ArgoCD needs access to your repo. Run this:
bash# Install ArgoCD CLI
brew install argocd

# Login via CLI
argocd login localhost:8080 \
  --username admin \
  --insecure

# Add your repo (public repo — no credentials needed)
argocd repo add https://github.com/YOUR_USERNAME/k8s-idp

# If your repo is private, add credentials
argocd repo add https://github.com/YOUR_USERNAME/k8s-idp \
  --username YOUR_USERNAME \
  --password YOUR_GITHUB_PAT   # Personal Access Token from github.com/settings/tokens
Verify it shows Successful connection status:
bashargocd repo list

Step 5 — Apply the root app
This is the one and only manual kubectl apply in this entire project:
bashkubectl apply -f clusters/prod/argocd/root-app.yaml

Step 6 — Watch ArgoCD sync
bash# Watch apps appear and sync in real time
watch kubectl get applications -n argocd
Within 30–60 seconds you should see:
NAME                   SYNC STATUS   HEALTH STATUS
root-app               Synced        Healthy
platform-namespaces    Synced        Healthy
team-a-apps            OutOfSync     Missing
team-b-apps            OutOfSync     Missing
team-a-apps and team-b-apps show OutOfSync because the yaml files inside apps/team-a/ and apps/team-b/ are still empty — that's completely expected at this stage.

Step 7 — Verify namespaces were created
bash# Namespaces should exist
kubectl get namespaces | grep team

# ResourceQuotas applied
kubectl get resourcequota -A | grep team

# LimitRanges applied
kubectl get limitrange -A | grep team
Expected output:
team-a   Active
team-b   Active

team-a   team-a-quota   ...
team-b   team-b-quota   ...

team-a   team-a-limitrange
team-b   team-b-limitrange

What to check in the UI
Open https://localhost:8080 and verify:

Applications screen — you see all 4 apps listed
Click root-app — you see it managing the 3 child apps as a tree
Click platform-namespaces — you see the Namespace, ResourceQuota, LimitRange resources listed with green health
Settings → Repositories — your GitHub repo shows Successful


Tell me what output you get from Step 6 and 7 — and share any errors if they appear. Once everything is green we move straight to Phase 2.You said: why we need to install argocd twice from helm and blew?why we need to install argocd twice from helm and blew?Jun 3Claude responded: Great catch — you don't.Great catch — you don't. That was my mistake in the explanation. Let me clarify exactly what each tool is:

Helm vs ArgoCD CLI — completely different things
HelmArgoCD CLIWhat it isPackage manager for KubernetesCommand-line client for ArgoCDWhat it doesInstalls ArgoCD into the clusterTalks to ArgoCD after it's installedEquivalent toapt install argocdargocd <commands>Run once?Yes — installs ArgoCD serverYes — but optional, UI does the same thingRequired?YesNo — purely optional convenience

The correct sequence
1. helm install argocd        → installs ArgoCD server INTO your cluster
                                  (creates pods, services, CRDs)

2. kubectl port-forward       → opens a tunnel so you can reach ArgoCD UI

3. brew install argocd        → installs the CLI tool on YOUR LAPTOP
                                  so you can run "argocd repo add" etc.

4. argocd login               → CLI connects to the ArgoCD server running in step 1
Think of it like this — Helm installs the restaurant, the ArgoCD CLI is just your phone to call the restaurant. You only build the restaurant once.

Can you skip the ArgoCD CLI entirely?
Yes. Everything the CLI does, the UI does too:
bash# Instead of:
argocd repo add https://github.com/YOUR_USERNAME/k8s-idp

# Just go to:
# ArgoCD UI → Settings → Repositories → Connect Repo
So the minimum you need is just:
bash# 1. Install ArgoCD into cluster (one time)
helm install argocd argo/argo-cd ...

# 2. Access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# 3. Apply root app (one time)
kubectl apply -f clusters/prod/argocd/root-app.yaml
That's it. brew install argocd is optional convenience. Sorry for the confusion in the earlier steps — does that clear it up?You said: Can you prepare kind cluster setup to align this project and I want to use cilium for networking?Can you prepare kind cluster setup to align this project and I want to use cilium for networking?7:48 AMClaude responded: Great choice — Cilium is production-grade CNI with built-in NetworkPolicy, eBPF-based observability, and Hubble for network visibility.Great choice — Cilium is production-grade CNI with built-in NetworkPolicy, eBPF-based observability, and Hubble for network visibility. Perfect for this project.
Since we're using Cilium, we need to disable kind's default CNI and let Cilium take over completely.kind-config.yamlCode ∙ Version 2 # ═══════════════════════════════════════════════════════════════════════
# FILE: kind-config.yaml
#
# PURPOSE:
#   Defines the local Kubernetes cluster topology using kind (Kubernetes
#   IN Docker). This config creates a 4-node cluster that mirrorsNow the Cilium install script — this must run right after cluster creation, before any pods are scheduled:scripts/install-cilium.shCode #!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
# FILE: scripts/install-cilium.sh
#
# PURPOSE:
#   Installs Cilium as the CNI (Container Network Interface) for the
#   kind cluster. Must be run IMMEDIATELAnd a single bootstrap script that ties everything together — cluster creation + Cilium + ArgoCD in the right order:scripts/bootstrap.shCode ∙ Version 2 #!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
# FILE: scripts/bootstrap.sh
#
# PURPOSE:
#   Single entrypoint to bring up the entire local IDP platform from
#   scratch. Run this on a fresh machine or a
Updated folder structure
Add the scripts folder to your repo:
bashmkdir -p k8s-idp/scripts
# copy kind-config.yaml to root of repo
mv kind-config.yaml k8s-idp/
Your repo root should now look like:
k8s-idp/
├── kind-config.yaml          ← cluster topology + Cilium settings
├── scripts/
│   ├── bootstrap.sh          ← one command to rule them all
│   └── install-cilium.sh     ← Cilium CNI installer
├── clusters/
├── platform/
└── apps/

Run it
bashcd k8s-idp

# Set your GitHub repo URL
export GITHUB_REPO=https://github.com/YOUR_USERNAME/k8s-idp

# Run the full bootstrap
bash scripts/bootstrap.sh

Why Cilium over kindnet
kindnet (default)CiliumNetworkPolicy supportBasicFull + extended policieskube-proxyUses iptablesReplaced by eBPFObservabilityNoneHubble — live network flow UIPerformanceiptables-basedeBPF — faster at scaleInterview valueLowHigh — production CNI
The Hubble UI alone is a great interview demo — you can show live traffic flows between namespaces visually, which ties directly into your NetworkPolicy work in Phase 2.

Commit everything, then run the bootstrap. Tell me what you see after kubectl get nodes and cilium status.You said: I want to install cilium step by step manually instead of scrip as this is my first time.I want to install cilium step by step manually instead of scrip as this is my first time.7:50 AMClaude responded: Perfect mindset — understanding each command before automating it is the right approach.Perfect mindset — understanding each command before automating it is the right approach. Let's go step by step.

Step 1 — Create the kind cluster
bash# Make sure you're inside the repo root
cd k8s-idp

# Create the cluster
kind create cluster --config kind-config.yaml
Wait ~1 minute. Then check nodes:
bashkubectl get nodes
You'll see this — NotReady is expected because there's no CNI yet:
NAME                        STATUS     ROLES           AGE
idp-cluster-control-plane   NotReady   control-plane   30s
idp-cluster-worker          NotReady   <none>          28s
idp-cluster-worker2         NotReady   <none>          28s
idp-cluster-worker3         NotReady   <none>          28s
Tell me when you see this output and we move to Step 2.

Step 2 — Install the Cilium CLI
This is a standalone tool on your laptop — separate from the cluster:
bash# macOS
brew install cilium-cli

# Verify
cilium version --client
Expected output:
cilium-cli: v0.16.10

Step 3 — Add the Cilium Helm repo
bash# Add Cilium's official Helm repo
helm repo add cilium https://helm.cilium.io/

# Fetch latest chart index
helm repo update

# Confirm it's there
helm search repo cilium/cilium
Expected output:

NAME            CHART VERSION   APP VERSION
cilium/cilium   1.15.5          1.15.5

Step 4 — Pre-load the Cilium image into kind nodes
Kind nodes are Docker containers. Without this step, each node would pull the Cilium image from the internet at startup — slow and fragile. Pre-loading puts the image directly inside the kind nodes:

# Pull image to your local Docker first
docker pull quay.io/cilium/cilium:v1.15.5

# Push it into all kind cluster nodes
kind load docker-image quay.io/cilium/cilium:v1.15.5 \
  --name idp-cluster

Expected output:
Image: "quay.io/cilium/cilium:v1.15.5" with ID "sha256:..." not yet present on node...
Loading image: quay.io/cilium/cilium:v1.15.5
Image loaded successfully

Step 5 — Get the control plane IP
Cilium needs to know where the API server is because it's replacing kube-proxy:

kubectl get node idp-cluster-control-plane \
  -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'

Step 6 — Install Cilium via Helm
Now paste your control plane IP into this command where it says PASTE_IP_HERE:

helm install cilium cilium/cilium \
  --version 1.15.5 \
  --namespace kube-system \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=PASTE_IP_HERE \
  --set k8sServicePort=6443 \
  --set routingMode=tunnel \
  --set tunnelProtocol=vxlan \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set image.pullPolicy=IfNotPresent

FlagWhykubeProxyReplacement=true  >>  Cilium handles all service routing via eBPF — no iptables
k8sServiceHost    >>    API server IP — needed since kube-proxy is disabled
k8sServicePort=6443  >>  API server port — always 6443
routingMode=tunnel    >>    VXLAN overlay — works inside Docker (kind)
hubble.relay.enabled=true    >>    Enables Hubble backend for network flows
hubble.ui.enabled=true    >>    Enables Hubble browser UI
image.pullPolicy=IfNotPresent    >>    Use the pre-loaded image — don't re-pull

Step 7 — Watch Cilium pods start

# Watch Cilium pods come up in real time
kubectl get pods -n kube-system -w | grep cilium

Wait until you see all pods Running:
cilium-xxxxx   1/1   Running   0   60s
cilium-xxxxx   1/1   Running   0   60s
cilium-xxxxx   1/1   Running   0   60s
cilium-xxxxx   1/1   Running   0   60s
cilium-operator-xxxxx   1/1   Running   0   60s

Step 8 — Check nodes are now Ready
kubectl get nodes

All nodes should now show Ready:
NAME                        STATUS   ROLES           AGE
idp-cluster-control-plane   Ready    control-plane   5m
idp-cluster-worker          Ready    <none>          5m
idp-cluster-worker2         Ready    <none>          5m
idp-cluster-worker3         Ready    <none>          5m

Step 9 — Verify Cilium is healthy
cilium status

Expected output — everything should be green:

/¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    disabled
 \__/¯¯\__/    Hubble Relay:       OK
    \__/        ClusterMesh:        disabled

Deployment             cilium-operator    Desired: 1, Ready: 1/1
DaemonSet              cilium             Desired: 4, Ready: 4/4

Step 10 — Open Hubble UI

cilium hubble ui

This automatically opens your browser with a live network flow map. Right now it'll be mostly empty — but once we deploy workloads in Phase 2 you'll see traffic flowing between namespaces in real time. Great interview demo.
