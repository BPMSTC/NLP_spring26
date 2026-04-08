# Notebook Environment Setup

This project uses a dedicated Python virtual environment named `nlp_env` for the notebook.

## What This Setup Does

The PowerShell bootstrap script:

- Creates the `nlp_env` virtual environment.
- Detects Python using `py -3` first, then falls back to `python`.
- Checks that `pip` exists and repairs it with `ensurepip` if needed.
- Installs the notebook dependencies from `requirements.txt`.
- Falls back to package-by-package installation if the bulk install fails.
- Registers a Jupyter kernel named `Python (nlp_env)`.
- Verifies that the required imports succeed.

## Prerequisites

- Windows with PowerShell.
- Python 3.10 or newer.
- Internet access for first-time package installation.

## Create The Environment

From the project root, run:

```powershell
.\setup_nlp_env.ps1 -CreateOnly
```

If PowerShell blocks script execution, run this in the same terminal first:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

## Activate The Environment Manually

```powershell
.\nlp_env\Scripts\Activate.ps1
```

After activation, your terminal prompt should show `(nlp_env)`.

## Run The Notebook

You have two options.

### Option 1: Launch Jupyter from the script

```powershell
.\setup_nlp_env.ps1
```

That command creates or refreshes the environment and then opens the notebook server.

### Option 2: Activate and run manually

```powershell
.\nlp_env\Scripts\Activate.ps1
python -m notebook NLP_Classroom_Demo_From_BoW_to_Contextual_Embeddings.ipynb
```

## Use In VS Code

Open the notebook and choose the kernel named `Python (nlp_env)`.

If the kernel list does not update right away:

1. Close and reopen the notebook.
2. Run the setup script again.
3. Confirm the environment exists at `./nlp_env`.

## Common Fallbacks

### Python not found

Install Python from the official installer and make sure the launcher is available. The script checks `py -3` first and `python` second.

### `pip` not found inside the venv

The script automatically runs:

```powershell
python -m ensurepip --upgrade
```

### Bulk dependency install fails

The script retries each package one at a time so students can see which package failed.

### Jupyter kernel does not appear

Run:

```powershell
.\setup_nlp_env.ps1 -CreateOnly
```

Then reopen VS Code or reload the notebook window.