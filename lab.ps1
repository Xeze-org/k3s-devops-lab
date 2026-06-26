<#
.SYNOPSIS
  Windows PowerShell wrapper for the k3s DevOps lab (mirrors the Makefile).
  Usage:  .\lab.ps1 <up|apply|sync|status|plan|down|clean-cf>
  Requires: Vagrant, VMware Workstation Pro, and Git Bash (for the shell scripts).
#>
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('up','apply','sync','status','plan','down','clean-cf','preflight')]
  [string]$Target
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
Set-Location $root

function Find-Bash {
  $candidates = @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
  )
  foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
  $cmd = Get-Command bash.exe -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  throw "Git Bash not found. Install Git for Windows so the shell scripts can run."
}
$bash = Find-Bash

function Invoke-Bash([string]$script) { & $bash -lc "cd '$($root -replace '\\','/')' && $script" }

function Test-Preflight {
  if (-not (Test-Path "$root\.env")) { throw ".env missing. Run: Copy-Item .env.example .env" }
  Invoke-Bash ". ./scripts/_lib.sh && require_env DOMAIN CF_API_TOKEN CF_ACCOUNT_ID GITHUB_TOKEN"
  if (-not (Get-Command vagrant -ErrorAction SilentlyContinue)) { throw "vagrant not on PATH" }
  Write-Host "preflight OK" -ForegroundColor Green
}

switch ($Target) {
  'preflight' { Test-Preflight }
  'up' {
    Test-Preflight
    Invoke-Bash "bash scripts/render.sh"
    git add gitops/root/values.yaml
    git commit -m "chore: render values from .env" --quiet 2>$null
    try { git push } catch { Write-Warning "git push failed — ArgoCD reads GitHub; push manually." }
    vagrant up
  }
  'apply' {
    Test-Preflight
    Invoke-Bash "bash scripts/render.sh"
    git add gitops/root/values.yaml
    git commit -m "chore: toggle tools via .env" --quiet 2>$null
    git push
    Write-Host "Pushed. ArgoCD reconciles within ~3 min (or run: .\lab.ps1 sync)."
  }
  'sync'     { vagrant ssh -c "sudo kubectl -n argocd patch app root --type merge -p '{\""operation\"":{\""sync\"":{}}}' || true" }
  'status'   { Invoke-Bash "bash scripts/status.sh" }
  'plan'     { vagrant ssh -c "cd /vagrant && sudo ansible-playbook ansible/playbook.yml --check" }
  'down'     { vagrant destroy -f }
  'clean-cf' { Invoke-Bash "bash scripts/clean-cf.sh" }
}
