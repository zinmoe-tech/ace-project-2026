# Full Implementation — Amazon EKS with Okta OIDC

## Concept Overview

This project separates **authentication** from **authorization**.

- **Authentication** answers: *Who are you?*  
  Okta handles this by authenticating the user and issuing an OIDC token.

- **Authorization** answers: *What are you allowed to do?*  
  Kubernetes RBAC handles this by checking the groups contained in the OIDC token.

The overall flow is:

```text
User
  ↓
kubectl
  ↓
kubelogin / oidc-login
  ↓
Okta login
  ↓
OIDC token
  ├── email
  └── eks_groups
  ↓
Amazon EKS API server
  ↓
Kubernetes identity
  ↓
Kubernetes RBAC
```

### Why use OIDC with EKS?

Without OIDC, Kubernetes users are often tied directly to AWS IAM identities. That works well for AWS-native access, but it is less convenient when an organization already manages users and groups in an enterprise identity provider such as Okta.

Using Okta OIDC provides:

- centralized user authentication;
- browser-based sign-in;
- MFA support through the identity provider;
- group-based access control;
- easier user onboarding/offboarding;
- no need to create a dedicated AWS IAM user for every Kubernetes user;
- clearer separation between identity management and Kubernetes permissions.

### Important Concept: Authentication vs Authorization

A user may successfully authenticate through Okta and still receive `Forbidden` from Kubernetes. That does not mean OIDC is broken. It means authentication succeeded, but Kubernetes RBAC did not authorize the requested action.

That distinction is central to this project.

## Step-1 — Create the Okta OIDC Application

### Concept

The Okta OIDC application represents `kubectl`/`kubelogin` as a client that is allowed to request identity tokens from Okta.

### Why we need it

Okta needs to know **which application is requesting authentication**. The application supplies a Client ID that later becomes part of the trust relationship between Okta and EKS.

### Why PKCE is used

The CLI is a public client and cannot safely store a client secret. PKCE protects the Authorization Code flow without requiring a stored secret.

Open `Okta Admin Console → Applications → Applications → Create App Integration`.

Create an OIDC application named `EKS-OIDC-APP`. Record the Client ID. In this lab, client authentication was **None** and PKCE was enabled.

![Step-1](../images/step-01-okta-oidc-app.png)

## Step-2 — Create an Okta Authorization Server

### Concept

An Authorization Server is the Okta component that issues OAuth/OIDC tokens and defines the issuer URL, audience, claims, policies, and token behavior.

### Why we need to create it

EKS must trust a specific token issuer. A dedicated authorization server gives us a stable issuer URL and lets us define EKS-specific claims and policies independently from other applications.

Open `Security → API → Authorization Servers`.

Create a dedicated server, for example:

- Name: `EKS-OIDC`
- Audience: `api://eks`

Record the exact Issuer URL:

`https://<OKTA_DOMAIN>/oauth2/<AUTHORIZATION_SERVER_ID>`

![Step-2](../images/step-02-authorization-server.png)

## Step-3 — Create the Okta Access Policy

### Concept

An Access Policy defines **which OIDC clients are allowed to obtain tokens** from the Authorization Server.

### Why we need to create it

Creating the authorization server alone does not automatically permit our EKS client to use it. The policy explicitly links the EKS OIDC application to the server.

Open `Security → API → Authorization Servers → EKS-OIDC → Access Policies`.

Create:

- Name: `EKS-OIDC-Policy`
- Description: `Access policy for Amazon EKS OIDC authentication`
- Assigned client: `EKS-OIDC-APP`

![Step-3](../images/step-03-access-policy.png)

## Step-4 — Create the Authorization Rule

### Concept

An Authorization Rule defines the conditions under which Okta issues a token.

### Why we need to create it

The policy defines *who may use the server*; the rule defines *how they may authenticate*. In this lab we use the Authorization Code flow and request the standard OIDC scopes required to identify the user.

Inside the policy, add a rule:

- Rule Name: `EKS-OIDC-Authentication-Rule`
- Grant Type: `Authorization Code`
- User: `Any user assigned the app`
- Scopes: `openid`, `profile`, `email`
- Access token lifetime: `1 hour`

![Step-4](../images/step-04-authorization-rule.png)

## Step-5 — Create Okta Groups

### Concept

Okta groups become the logical source of Kubernetes access roles.

### Why we need to create them

Managing permissions user-by-user does not scale. By using groups, administrators can grant or remove Kubernetes access simply by changing Okta group membership.

Create:

- `eks-admins`
- `eks-developers`

Assign users to the appropriate group.

![Step-5](../images/step-05-okta-groups.png)

## Step-6 — Create the `eks_groups` Claim

### Concept

OIDC claims are key/value attributes placed inside the token. The custom `eks_groups` claim carries Okta group membership to EKS.

### Why we need to create it

Kubernetes RBAC cannot see Okta groups automatically. EKS only receives the claims present in the token. The `eks_groups` claim is the bridge between Okta group membership and Kubernetes RBAC.

Open `Security → API → Authorization Servers → EKS-OIDC → Claims`.

Create:

- Name: `eks_groups`
- Token: `ID Token`
- Value type: `Groups`
- Filter: `Starts with`
- Value: `eks-`
- Include in: `Any scope`

Expected token claim:

```json
"eks_groups": ["eks-admins"]
```

![Step-6](../images/step-06-eks-groups-claim.png)

## Step-7 — Create the EKS Cluster IAM Role

### Concept

The EKS cluster IAM role is an AWS service role used by the EKS control plane.

### Why we need to create it

The Kubernetes control plane needs permission to interact with AWS resources on behalf of the cluster. This role is for the EKS service itself, not for human users.

Create `EKS-Cluster-Role_UDR` with trust for `eks.amazonaws.com`.

Attach the policies required by your EKS cluster mode. In this lab, screenshots showed:

- `AmazonEKSClusterPolicy`
- `AmazonEKSBlockStoragePolicyV2`
- `AmazonEKSComputePolicy`
- `AmazonEKSLoadBalancingPolicy`
- `AmazonEKSNetworkingPolicy`

![Step-7](../images/step-07-eks-cluster-role.png)

## Step-8 — Create the EKS Node Role

### Concept

The node role is the AWS identity used by worker nodes or EKS Auto Mode compute.

### Why we need to create it

Worker nodes must pull container images and interact with EKS/AWS services. The node role is intentionally separate from the control-plane role because the two components have different responsibilities.

Create `EKS-Auto-Node-Role_UDR`.

Typical trust principal: `ec2.amazonaws.com`.

The lab used node policies including:

- `AmazonEC2ContainerRegistryPullOnly`
- `AmazonEKSWorkerNodeMinimalPolicy`

![Step-8](../images/step-08-eks-node-role.png)

## Step-9 — Create the EKS Cluster

### Concept

The EKS cluster is the managed Kubernetes control plane where OIDC authentication will be enabled.

### Why we need it

All of the Okta and RBAC work ultimately protects access to this Kubernetes API server. The cluster must exist before an OIDC identity provider can be associated with it.

Open `AWS Console → Amazon EKS → Clusters → Create cluster`.

Example:

- Cluster: `eks-oidc-project`
- Region: `us-east-1`
- Cluster role: `EKS-Cluster-Role_UDR`
- Select VPC and subnets
- Select the required compute/node role

Wait until status becomes `Active`.

![Step-9](../images/step-09-eks-cluster.png)

## Step-10 — Configure Bootstrap Administrative Access

### Concept

The bootstrap administrative access entry gives an AWS administrator initial access to configure the cluster.

### Why we need it

OIDC users cannot receive useful Kubernetes permissions until someone with existing administrative access creates the RBAC objects. This is the bootstrap path used to configure the cluster safely.

Open `EKS → eks-oidc-project → Access`.

Create an access entry for the bootstrap IAM administrator:

- Type: `Standard`
- Access policy: `AmazonEKSClusterAdminPolicy`
- Access scope: `Cluster`

![Step-10](../images/step-10-eks-access-entry.png)

## Step-11 — Update Administrator kubeconfig

### Concept

`kubeconfig` tells `kubectl` which cluster to contact and which authentication method to use.

### Why we need it

Before testing Okta, the administrator needs a working management context for the cluster so that RBAC resources and OIDC-related configuration can be verified.

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name eks-oidc-project \
  --profile eks-admin

kubectl get nodes
```

![Step-11](../images/step-11-admin-kubeconfig.png)

## Step-12 — Associate Okta with Amazon EKS

### Concept

Associating the Okta issuer with EKS tells the Kubernetes API server to trust tokens signed by that OIDC provider.

### Why we need to create this association

Okta may issue a perfectly valid token, but EKS will reject it unless the cluster is explicitly configured to trust the correct issuer, Client ID, username claim, and groups claim.

Open `EKS → eks-oidc-project → Access → OIDC identity providers → Associate identity provider`.

Configure:

- Name: `okta-eks`
- Issuer URL: `https://<OKTA_DOMAIN>/oauth2/<AUTHORIZATION_SERVER_ID>`
- Client ID: `<OKTA_CLIENT_ID>`
- Username claim: `email`
- Groups claim: `eks_groups`

![Step-12](../images/step-12-associate-oidc.png)

## Step-13 — Verify OIDC Provider Status

### Concept

OIDC provider status confirms whether EKS has accepted and activated the external identity-provider configuration.

### Why we verify it

Testing user login before the provider reaches `ACTIVE` can produce misleading authentication errors. This step confirms the trust configuration is ready.

```bash
aws eks describe-identity-provider-config \
  --cluster-name eks-oidc-project \
  --identity-provider-config type=oidc,name=okta-eks \
  --region us-east-1 \
  --profile eks-admin
```

Expected:

- Status: `ACTIVE`
- Username claim: `email`
- Groups claim: `eks_groups`

![Step-13](../images/step-13-oidc-active.png)

## Step-14 — Create RBAC for Okta Administrators

### Concept

A `ClusterRoleBinding` associates a Kubernetes group with a cluster-wide role.

### Why we need to create it

Okta proves that the user belongs to `eks-admins`; Kubernetes still needs an authorization rule that says what `eks-admins` is allowed to do. Binding it to `cluster-admin` provides that authorization.

```bash
kubectl create clusterrolebinding okta-eks-admins \
  --clusterrole=cluster-admin \
  --group=eks-admins
```

Verify:

```bash
kubectl describe clusterrolebinding okta-eks-admins
```

![Step-14](../images/step-14-admin-rbac.png)

## Step-15 — Create Developer Namespace

### Concept

A Kubernetes namespace is a logical boundary used to isolate resources and permissions.

### Why we need to create it

The developer group should not receive cluster-wide access. A dedicated namespace gives us a clean scope in which developer permissions can be granted.

```bash
kubectl create namespace developers-team
```

## Step-16 — Create Developer Role

### Concept

A Kubernetes `Role` is a set of permissions scoped to a namespace.

### Why we need to create it

The Role defines exactly which resources and operations developers can use inside `developers-team`. It implements least privilege.

Use `kubernetes/developer-role.yaml`.

```bash
kubectl apply -f kubernetes/developer-role.yaml
```

## Step-17 — Bind the Okta Developer Group

### Concept

A `RoleBinding` connects a user or group to a Role within one namespace.

### Why we need to create it

The Role by itself grants permission to nobody. The RoleBinding connects the Okta group `eks-developers` to `developer-role`.

Use `kubernetes/developer-rolebinding.yaml`.

```bash
kubectl apply -f kubernetes/developer-rolebinding.yaml
```

![Step-17](../images/step-17-developer-group.png)

## Step-18 — Install kubelogin

### Concept

`kubelogin` is a kubectl authentication plugin that performs the OIDC browser login and obtains tokens.

### Why we need it

`kubectl` cannot by itself perform the entire interactive Okta Authorization Code flow. `kubelogin` handles the browser redirect, token acquisition, and token refresh/caching behavior.

Verify architecture:

```bash
uname -m
```

Install kubelogin and verify:

```bash
kubectl oidc-login --version
```

![Step-18](../images/step-18-kubelogin.png)

## Step-19 — Test Okta Authentication

### Concept

This step validates the identity-provider flow independently before relying on normal kubectl commands.

### Why we test it

A successful token proves that the issuer URL, Client ID, scopes, browser login, and Okta policy are working. It also lets us inspect claims before troubleshooting EKS or RBAC.

```bash
kubectl oidc-login setup \
  --oidc-issuer-url="https://<OKTA_DOMAIN>/oauth2/<AUTHORIZATION_SERVER_ID>" \
  --oidc-client-id="<OKTA_CLIENT_ID>" \
  --oidc-extra-scope="profile" \
  --oidc-extra-scope="email" \
  --grant-type=authcode \
  --listen-address=127.0.0.1:8000
```

A browser opens for Okta authentication.

Expected token content includes email plus `eks_groups`.

![Step-19](../images/step-19-token-claims.png)

## Step-20 — Configure the OIDC User in kubeconfig

### Concept

The kubeconfig exec section tells kubectl to call `kubectl oidc-login get-token` whenever authentication is required.

### Why we need to configure it

Without the exec credential configuration, kubectl does not know how to obtain a fresh Okta token for API requests.

```bash
kubectl config set-credentials okta-user-login \
  --exec-api-version=client.authentication.k8s.io/v1beta1 \
  --exec-command=kubectl \
  --exec-arg=oidc-login \
  --exec-arg=get-token \
  --exec-arg="--oidc-issuer-url=https://<OKTA_DOMAIN>/oauth2/<AUTHORIZATION_SERVER_ID>" \
  --exec-arg="--oidc-client-id=<OKTA_CLIENT_ID>" \
  --exec-arg="--oidc-extra-scope=profile" \
  --exec-arg="--oidc-extra-scope=email" \
  --exec-arg="--grant-type=authcode" \
  --exec-arg="--listen-address=127.0.0.1:8000"
```

![Step-20](../images/step-20-oidc-kubeconfig.png)

## Step-21 — Create the Okta Context

### Concept

A Kubernetes context combines a cluster, a user/authentication method, and optionally a namespace.

### Why we need to create a separate context

Keeping an Okta context separate from the AWS-admin context makes testing safer and clearer. It also prevents accidental testing with administrator AWS credentials when we intend to test an OIDC user.

```bash
kubectl config set-context eks-okta-context \
  --cluster="<EKS_CLUSTER_ENTRY>" \
  --user=okta-user-login

kubectl config use-context eks-okta-context
kubectl config get-contexts
```

![Step-21](../images/step-21-context.png)

## Step-22 — Verify Administrator Authorization

### Concept

`kubectl auth can-i` asks the Kubernetes authorization layer whether the current identity is allowed to perform an action.

### Why we test the administrator

This proves that the full chain works: Okta login → group claim → EKS authentication → Kubernetes RBAC.

Authenticate with a member of `eks-admins`.

```bash
kubectl auth can-i '*' '*' --all-namespaces
```

Expected:

```text
yes
```

![Step-22](../images/step-22-admin-test.png)

## Step-23 — Verify Developer Identity

### Concept

`SelfSubjectReview` shows how Kubernetes sees the currently authenticated identity.

### Why we use it

It is one of the best troubleshooting tools for OIDC because it confirms the exact username and groups received by Kubernetes. If `eks-developers` is missing here, the problem is in identity/claims rather than the RoleBinding.

Authenticate with a member of `eks-developers`.

Run a SelfSubjectReview:

```bash
kubectl create -f - -o yaml --validate=false <<'EOF'
apiVersion: authentication.k8s.io/v1
kind: SelfSubjectReview
EOF
```

Expected:

- username = user email
- groups include `eks-developers`
- groups include `system:authenticated`

![Step-23](../images/step-23-self-subject-review.png)

## Step-24 — Verify Restricted Developer RBAC

### Concept

Authorization testing should verify both **allowed** and **denied** actions.

### Why we test both

A successful least-privilege design is not proven only by what the developer can do. We must also prove that the developer cannot access unrelated namespaces or cluster-scoped resources.

```bash
kubectl auth can-i get pods -n developers-team
# yes

kubectl auth can-i create pods -n developers-team
# yes

kubectl auth can-i get pods -n default
# no

kubectl auth can-i get nodes
# no
```

![Step-24](../images/step-24-developer-rbac-test.png)

## Step-25 — Final Result

### Concept

The final validation confirms the separation of responsibilities:

- Okta manages identity and group membership.
- EKS validates OIDC tokens.
- Kubernetes RBAC manages permissions.

### Why this design matters

This architecture is easier to operate at scale because identity lifecycle is centralized while Kubernetes keeps native control of authorization.

```text
Okta
  ↓
OIDC token
  ↓
email + eks_groups
  ↓
Amazon EKS
  ↓
Kubernetes RBAC
  ├── eks-admins → cluster-admin
  └── eks-developers → developers-team only
```

The PoC demonstrates successful external authentication, group propagation, and least-privilege Kubernetes authorization.
