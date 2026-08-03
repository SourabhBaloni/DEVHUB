# Salesforce DX → GitHub Actions CI/CD — Step-by-Step Guide

Follow this guide **top to bottom, in order**. Each step has a checkbox — tick it before
moving on. By the end you will have automated deployments to your Sandbox.

**What this pipeline does**

- Open a PR into `main` → runs quality gates (Prettier, ESLint, Jest) + a **check-only**
  validation of the changed metadata. Nothing is deployed.
- Merge / push into `main` → **deploys only the changed metadata** (delta) to the Sandbox.

**Authentication:** JWT Bearer flow (no passwords stored).
**Deploy scope:** Delta only (via `sfdx-git-delta`).

---

## Prerequisites (install these first)

- [ ] **Git** — https://git-scm.com/downloads
- [ ] **Node.js 20+** — https://nodejs.org
- [ ] **Salesforce CLI** — `npm install --global @salesforce/cli`
- [ ] **OpenSSL** — usually preinstalled on Git Bash (Windows) / macOS / Linux
- [ ] A **GitHub account** and permission to create a repository
- [ ] Admin access to your **Sandbox** org

Verify:

```bash
git --version
node --version
sf version
openssl version
```

---

## PART A — Put the project on GitHub

> Skip Part A if the project is already a GitHub repo. Just confirm the branch is `main`.

### Step 1 — Initialize git (run from the project root)

```bash
cd "a:/VS CODE REPS/DEV+ORG_SB"
git init
git branch -M main
git add .
git commit -m "Initial commit: Salesforce app + CI/CD pipeline"
```

- [ ] Done

### Step 2 — Create the GitHub repository

1. Go to https://github.com/new
2. Name it (e.g. `DEV-ORG-SB`), keep it **Private**, do **not** add a README/gitignore
   (you already have them).
3. Create the repository.

- [ ] Done

### Step 3 — Push your code

Copy the commands GitHub shows you, or use:

```bash
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```

- [ ] Code is visible on GitHub, including the `.github/workflows/` folder

---

## PART B — Create the JWT certificate & key (one time)

The private key proves the pipeline's identity to Salesforce. You generate it once.

### Step 4 — Generate the key pair

Run in **Git Bash** (Windows) or a terminal, in a **temporary folder outside the repo**
(so it never gets committed):

```bash
openssl req -x509 -sha256 -nodes -days 3650 -newkey rsa:2048 \
  -keyout server.key -out server.crt \
  -subj "/CN=SalesforceCI"
```

This creates two files:

| File | What it is | Where it goes |
|---|---|---|
| `server.key` | **Private key** (secret) | GitHub secret (Step 9) |
| `server.crt` | Certificate (public) | Uploaded to Salesforce (Step 5) |

> ⚠️ **Never commit `server.key`.** `.gitignore` already blocks `*.key`, but keep it out
> of the repo folder entirely to be safe.

- [ ] Both files created

---

## PART C — Configure the Sandbox org

### Step 5 — Create a Connected App

In your **Sandbox** org:

1. **Setup** → search **App Manager** → **New Connected App**.
2. Fill in:
   - Connected App Name: `GitHub Actions CI`
   - API Name: auto-fills
   - Contact Email: your email
3. Check **Enable OAuth Settings**.
4. Callback URL: `http://localhost:1717/OauthRedirect`
   *(required by the form; unused for JWT)*
5. Check **Use digital signatures** → **Choose File** → upload **`server.crt`**.
6. Under **Selected OAuth Scopes**, add:
   - `Manage user data via APIs (api)`
   - `Perform requests at any time (refresh_token, offline_access)`
   - `Full access (full)` *(optional, convenient)*
7. Click **Save**, then **Continue**.

⏳ **Wait ~10 minutes** for the Connected App to propagate before testing.

- [ ] Connected App created

### Step 6 — Copy the Consumer Key

1. **Setup** → **App Manager** → find `GitHub Actions CI` → dropdown → **View**.
2. Under **API (Enable OAuth Settings)** → **Manage Consumer Details** (may prompt for a
   verification code) → copy the **Consumer Key**.
3. Save it somewhere temporary — you'll paste it into a GitHub secret in Step 9.

- [ ] Consumer Key copied

### Step 7 — Pre-authorize the integration user

1. **Setup** → **App Manager** → `GitHub Actions CI` → dropdown → **Manage**.
2. Click **Edit Policies**.
3. Set **Permitted Users** = **Admin approved users are pre-authorized** → **Save**.
4. Back on the Manage page, scroll to **Profiles** or **Permission Sets** → click
   **Manage Profiles / Manage Permission Sets** → add the profile/permission set that
   your integration user has (e.g. `System Administrator`).

> The **integration user** is whichever Sandbox user the pipeline logs in as. You can use
> your admin user or, better, a dedicated deployment user. Note its **full username**
> (e.g. `deployer@company.com.mysandbox`) — you'll need it in Step 9.

- [ ] Integration user is pre-authorized

---

## PART D — Verify auth locally (before touching CI)

### Step 8 — Test the JWT login

From the folder containing `server.key`:

```bash
sf org login jwt \
  --client-id <CONSUMER_KEY> \
  --jwt-key-file server.key \
  --username <INTEGRATION_USERNAME> \
  --instance-url https://test.salesforce.com \
  --alias sandbox
```

- ✅ **Success** → CI will work with the same values. Continue.
- ❌ **Error** → common causes:
  - Waited < 10 min after creating the Connected App.
  - User not pre-authorized (Step 7).
  - Wrong username (must be the full sandbox username).
  - Sandbox URL must be `https://test.salesforce.com`.

- [ ] Local JWT login succeeded

---

## PART E — Wire up GitHub

### Step 9 — Add the environment and secrets

1. On GitHub: repo → **Settings** → **Environments** → **New environment** →
   name it exactly **`sandbox`** → **Configure environment**.
   *(Optional: add yourself under **Required reviewers** to require manual approval
   before each deploy.)*
2. In that environment, under **Environment secrets** → **Add secret**, create all four:

| Secret name | Value |
|---|---|
| `SF_CONSUMER_KEY` | The Consumer Key from Step 6 |
| `SF_JWT_SERVER_KEY` | The **entire contents** of `server.key` — open it in a text editor and paste everything, including the `-----BEGIN...` and `-----END...` lines |
| `SF_USERNAME` | The integration user's full username |
| `SF_INSTANCE_URL` | `https://test.salesforce.com` |

- [ ] All four secrets added under the `sandbox` environment

---

## PART F — Run the pipeline

### Step 10 — Trigger a PR validation

```bash
git checkout -b test/ci-pipeline
# make any small change, e.g. edit a comment in an Apex class
git add .
git commit -m "test: trigger CI"
git push -u origin test/ci-pipeline
```

Then on GitHub open a **Pull Request** into `main`.

- Go to the **Actions** tab (or the PR's **Checks**) and watch **PR Validation (Sandbox)**.
- It runs quality gates + a **check-only** validation. Nothing is deployed yet.

- [ ] PR Validation passes green

### Step 11 — Deploy

Merge the PR into `main`.

- The **Deploy to Sandbox** workflow runs automatically.
- It deploys only the changed metadata (delta) to the Sandbox.
- (If you enabled required reviewers, approve the run when prompted.)

- [ ] Deploy to Sandbox succeeds — check the org to confirm your change

🎉 **You now have working CI/CD.** From here, every PR is validated and every merge deploys.

---

## Reference

### The files in this repo

| File | Purpose |
|---|---|
| `.github/actions/setup-sfdx/action.yml` | Shared setup: Node, npm, Salesforce CLI, `sfdx-git-delta`, JWT auth |
| `.github/workflows/pr-validation.yml` | PR → check-only validation + quality gates |
| `.github/workflows/deploy.yml` | Push to `main` → delta deploy to Sandbox |
| `docs/CICD-SETUP.md` | This guide |

### How the delta is calculated

- `sfdx-git-delta` diffs git history and builds a minimal `package/package.xml` (plus
  `destructiveChanges.xml` for deletions).
- PR runs: compare `HEAD` vs the PR base branch (`origin/main`).
- Deploy runs: compare `HEAD` vs `HEAD~1`.
- Empty delta → the deploy/validate step is skipped, not failed.

### Changing the test level

Both workflows use `--test-level RunLocalTests`. To change, edit the `sf project deploy`
lines in the workflow files:
- `RunSpecifiedTests` — fastest, requires `--tests ClassA ClassB`.
- `NoTestRun` — no tests (Sandbox only; not allowed for production).

### Common failures

| Symptom | Fix |
|---|---|
| `We couldn't validate the JWT...` | Re-check Steps 5–8; wait 10 min after Connected App creation |
| `INVALID_LOGIN` | Wrong username or user not pre-authorized (Step 7) |
| Deploy fails on tests / coverage | Fix failing Apex tests; org requires ≥75% coverage |
| Delta is empty but you expected changes | Ensure the workflow checks out full history (`fetch-depth: 0`) — already configured |

### Adding Production later

Create a `production` environment + secrets (with `SF_INSTANCE_URL =
https://login.salesforce.com`), add required reviewers, and add a `deploy-prod.yml`
triggered on a release tag or `main`. Ask and I'll generate it.
