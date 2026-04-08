[CmdletBinding()]
param(
    [switch]$CreateOnly,
    [switch]$LaunchNotebook,
    [string]$NotebookPath = "NLP_Classroom_Demo_From_BoW_to_Contextual_Embeddings.ipynb",
    [string]$VenvName = "nlp_env"
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$venvPath = Join-Path $scriptRoot $VenvName
$requirementsPath = Join-Path $scriptRoot "requirements.txt"

function Write-Step {
    param([string]$Message)

    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Get-PythonCommand {
    $candidates = @(
        @{ Command = "py"; Arguments = @("-3", "--version") },
        @{ Command = "python"; Arguments = @("--version") }
    )

    foreach ($candidate in $candidates) {
        try {
            & $candidate.Command @($candidate.Arguments) *> $null
            if ($LASTEXITCODE -eq 0) {
                return $candidate.Command
            }
        }
        catch {
        }
    }

    throw "Python 3 was not found. Install Python 3.10+ from https://www.python.org/downloads/ and rerun this script."
}

function New-Venv {
    param(
        [string]$PythonCommand,
        [string]$TargetPath
    )

    if (Test-Path $TargetPath) {
        Write-Host "Virtual environment already exists at $TargetPath" -ForegroundColor Yellow
        return
    }

    Write-Step "Creating virtual environment at $TargetPath"

    try {
        if ($PythonCommand -eq "py") {
            & py -3 -m venv $TargetPath
        }
        else {
            & python -m venv $TargetPath
        }
    }
    catch {
        throw "Failed to create the virtual environment. Confirm that Python includes venv support and try again."
    }
}

function Get-VenvPythonPath {
    param([string]$TargetPath)

    $venvPython = Join-Path $TargetPath "Scripts\python.exe"
    if (-not (Test-Path $venvPython)) {
        throw "Expected virtual environment interpreter was not found at $venvPython"
    }

    return $venvPython
}

function Ensure-Pip {
    param([string]$PythonExe)

    Write-Step "Checking pip in the virtual environment"

    try {
        & $PythonExe -m pip --version *> $null
        if ($LASTEXITCODE -eq 0) {
            return
        }
    }
    catch {
    }

    Write-Host "pip was not available. Attempting ensurepip fallback." -ForegroundColor Yellow
    & $PythonExe -m ensurepip --upgrade
    & $PythonExe -m pip --version *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "pip could not be initialized in the virtual environment."
    }
}

function Install-Requirements {
    param(
        [string]$PythonExe,
        [string]$RequirementsFile
    )

    if (-not (Test-Path $RequirementsFile)) {
        throw "requirements.txt was not found at $RequirementsFile"
    }

    Write-Step "Upgrading packaging tools"
    & $PythonExe -m pip install --upgrade pip setuptools wheel

    Write-Step "Installing notebook dependencies from requirements.txt"
    & $PythonExe -m pip install -r $RequirementsFile

    if ($LASTEXITCODE -eq 0) {
        return
    }

    Write-Host "Bulk dependency install failed. Trying package-by-package fallback." -ForegroundColor Yellow

    $packages = Get-Content $RequirementsFile | Where-Object {
        $_.Trim() -and -not $_.Trim().StartsWith("#")
    }

    $failedPackages = @()

    foreach ($package in $packages) {
        Write-Host "Installing $package ..." -ForegroundColor DarkCyan
        & $PythonExe -m pip install $package
        if ($LASTEXITCODE -ne 0) {
            $failedPackages += $package
        }
    }

    if ($failedPackages.Count -gt 0) {
        $failedList = $failedPackages -join ", "
        throw "Some packages still failed to install: $failedList"
    }
}

function Register-Kernel {
    param(
        [string]$PythonExe,
        [string]$KernelName
    )

    Write-Step "Registering Jupyter kernel '$KernelName'"
    & $PythonExe -m ipykernel install --user --name $KernelName --display-name "Python ($KernelName)"
}

function Test-ImportSet {
    param([string]$PythonExe)

    Write-Step "Validating core imports"

    $importCheck = @'
import importlib
modules = [
    "numpy",
    "pandas",
    "matplotlib",
    "seaborn",
    "wordcloud",
    "sklearn",
    "nltk",
    "datasets",
    "sentence_transformers",
    "transformers",
    "torch",
    "ipykernel",
    "notebook"
]
missing = []
for module_name in modules:
    try:
        importlib.import_module(module_name)
    except Exception as exc:
        missing.append(f"{module_name}: {exc}")
if missing:
    raise SystemExit("\n".join(missing))
print("Dependency validation passed.")
'@

    & $PythonExe -c $importCheck
}

function Open-Notebook {
    param(
        [string]$PythonExe,
        [string]$NotebookFile,
        [string]$RootPath
    )

    $resolvedNotebook = Join-Path $RootPath $NotebookFile
    if (-not (Test-Path $resolvedNotebook)) {
        throw "Notebook file not found at $resolvedNotebook"
    }

    Write-Step "Launching Jupyter Notebook"
    & $PythonExe -m notebook $resolvedNotebook
}

Write-Step "Starting environment setup"

$pythonCommand = Get-PythonCommand
Write-Host "Using Python launcher: $pythonCommand" -ForegroundColor Green

New-Venv -PythonCommand $pythonCommand -TargetPath $venvPath
$venvPython = Get-VenvPythonPath -TargetPath $venvPath

Ensure-Pip -PythonExe $venvPython
Install-Requirements -PythonExe $venvPython -RequirementsFile $requirementsPath
Register-Kernel -PythonExe $venvPython -KernelName $VenvName
Test-ImportSet -PythonExe $venvPython

Write-Host "`nEnvironment '$VenvName' is ready." -ForegroundColor Green
Write-Host "Activate it with: .\\$VenvName\\Scripts\\Activate.ps1"
Write-Host "Select the 'Python ($VenvName)' kernel in Jupyter or VS Code when opening the notebook."

if (-not $CreateOnly -or $LaunchNotebook) {
    Open-Notebook -PythonExe $venvPython -NotebookFile $NotebookPath -RootPath $scriptRoot
}