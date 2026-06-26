# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Single-VM k3s DevOps lab.
#   - Reads .env for flags + sizing.
#   - Auto-computes RAM/CPU from which heavy tools are enabled (clamped 4-8GB / 2-4 CPU).
#   - Provisions with ansible_local (Ansible runs INSIDE the guest -> works on Windows hosts).

require "pathname"

# ── Minimal .env parser (KEY=VALUE, ignores comments/blank lines) ──────────────
def load_env(path)
  env = {}
  return env unless File.exist?(path)
  File.foreach(path) do |line|
    line = line.strip
    next if line.empty? || line.start_with?("#")
    key, _, val = line.partition("=")
    env[key.strip] = val.strip.gsub(/\A["']|["']\z/, "")
  end
  env
end

ENV_FILE = File.join(__dir__, ".env")
unless File.exist?(ENV_FILE)
  abort("\n[Vagrant] .env not found. Run:  cp .env.example .env  and fill it in.\n\n")
end
cfg = load_env(ENV_FILE)

def truthy?(v)
  %w[true 1 yes on].include?(v.to_s.strip.downcase)
end

# ── Auto-sizing: base + per-tool budget, then clamp ────────────────────────────
mem = 4096   # base
cpu = 2      # base
mem += 1024 if truthy?(cfg["MONITORING"])
mem += 512  if truthy?(cfg["LOKI"])
if truthy?(cfg["JENKINS"]) ; mem += 2048 ; cpu += 1 ; end
if truthy?(cfg["NEXUS"])   ; mem += 2048 ; cpu += 1 ; end

computed_mem = mem
mem = [[mem, 4096].max, 8192].min   # clamp 4096..8192
cpu = [[cpu, 2].max, 4].min         # clamp 2..4

# Manual override wins (still clamped).
mem = [[cfg["VM_MEMORY"].to_i, 4096].max, 8192].min unless cfg["VM_MEMORY"].to_s.empty?
cpu = [[cfg["VM_CPUS"].to_i,  2].max,    4].min     unless cfg["VM_CPUS"].to_s.empty?

if computed_mem > 8192
  warn "\n[Vagrant] WARNING: enabled tools want #{computed_mem}MB but the VM is clamped to "\
       "8192MB. Expect memory pressure — consider disabling Jenkins or Nexus.\n\n"
end
puts "[Vagrant] Sizing VM: #{mem}MB RAM, #{cpu} vCPU  (domain: #{cfg['DOMAIN']})"

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"   # well-maintained box with VMware support
  config.vm.hostname = "k3-kube"

  # Private host-only network so the host can reach k3s/ArgoCD directly if needed.
  config.vm.network "private_network", ip: "192.168.56.50"

  config.vm.provider "vmware_desktop" do |v|
    v.memory = mem
    v.cpus   = cpu
    v.gui    = false
    v.vmx["virtualHW.version"] = "21"
  end

  # Ansible runs inside the guest (Windows host has no native Ansible).
  config.vm.provision "ansible_local" do |a|
    a.playbook         = "ansible/playbook.yml"
    a.install_mode     = "pip"
    a.compatibility_mode = "2.0"
    # Pass selected .env values through to the playbook as extra vars.
    a.extra_vars = {
      domain:        cfg["DOMAIN"],
      cf_api_token:  cfg["CF_API_TOKEN"],
      cf_account_id: cfg["CF_ACCOUNT_ID"],
      git_repo:      cfg["GIT_REPO"],
      git_branch:    (cfg["GIT_BRANCH"].to_s.empty? ? "main" : cfg["GIT_BRANCH"]),
      github_token:  cfg["GITHUB_TOKEN"]
    }
  end
end
