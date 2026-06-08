# Renovate Local Demo — Step by Step

This demo tests Renovate running locally via Docker against a GitHub repo.
It validates two key features:
- Digest pinning (tracking changes to an image under the same tag)
- Helm `values.yaml` tag updates

---

## Folder Structure

```
demo-repo/
├── Dockerfile          ← image reference Renovate will watch
├── renovate.json       ← Renovate config for this repo
├── run-renovate.sh     ← helper script to run Renovate via Docker
└── helm/
    └── values.yaml     ← Helm values image reference Renovate will watch
```

---

## Setup

### 1. Create a GitHub repo

- Go to GitHub and create a new public repo named `renovate-demo`
- Clone it locally and copy all files from this `demo-repo/` folder into it
- Commit and push to `main`

```bash
git init renovate-demo
cd renovate-demo
# copy files here
git add .
git commit -m "Initial demo setup"
git push origin main
```

---

### 2. Create a GitHub Personal Access Token

Go to GitHub → Settings → Developer Settings → Personal Access Tokens → Fine-grained tokens

Required permissions:
- **Contents** → Read and Write
- **Pull requests** → Read and Write
- **Metadata** → Read

---

### 3. Set Environment Variables

```bash
export GITHUB_TOKEN=<your-github-pat>
export GITHUB_REPO=<your-github-username>/renovate-demo
```

---

## Running the Demo

### Step 1 — Dry Run (Safe — No PRs Created)

See exactly what Renovate would do without touching anything:

```bash
chmod +x run-renovate.sh
./run-renovate.sh
```

Look in the output for lines like:
```
INFO: Would create branch renovate/docker-nginx-1.x
INFO: Would create PR "Update nginx:1.25.0 digest"
INFO: Would update helm/values.yaml tag field
```

This confirms Renovate detected both files.

---

### Step 2 — Live Run (Creates Real PRs)

```bash
./run-renovate.sh --live
```

On the **first run** against a new repo, Renovate opens an **onboarding PR** titled _"Configure Renovate"_.

Go to GitHub → open the onboarding PR → merge it.

---

### Step 3 — Run Again After Merging Onboarding PR

```bash
./run-renovate.sh --live
```

Renovate is now active. Expected PRs:

| PR | What it does |
|---|---|
| `Pin Docker digest nginx:1.25.0` | Updates `Dockerfile` to `nginx:1.25.0@sha256:...` |
| `helm values: Update nginx tag` | Updates `tag` field in `helm/values.yaml` |

---

### Step 4 — Test Digest Change Detection

Simulate what happens when Chainguard releases a patched image under the same tag.

After merging the digest-pin PRs from Step 3, manually edit the `Dockerfile` to roll back the digest to the old value:

```dockerfile
# Put back the tag-only reference (no digest)
FROM nginx:1.25.0
```

Commit and push, then run Renovate again:

```bash
./run-renovate.sh --live
```

Renovate should immediately open a new PR re-pinning the digest.

---

### Step 5 — Test New Tag Detection

Edit `Dockerfile` to use an older tag:

```dockerfile
FROM nginx:1.24.0
```

Edit `helm/values.yaml`:

```yaml
image:
  registry: docker.io
  repository: nginx
  tag: "1.24.0"
```

Commit, push, then run:

```bash
./run-renovate.sh --live
```

Renovate should open PRs bumping both references from `1.24.0` to the latest available tag.

---

## What a Successful Demo Looks Like

| Test | Expected Result |
|---|---|
| Dry run on fresh repo | Logs show what PRs would be created — no changes made |
| First live run | Onboarding PR opened |
| After onboarding merge | Digest pin PRs opened for Dockerfile and values.yaml |
| Tag rolled back | New PR to re-pin digest |
| Older tag set | PR to bump tag version in both files |
