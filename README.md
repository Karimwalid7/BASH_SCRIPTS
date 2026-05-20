# BASH_SCRIPTS

# Bash Utilities & Monitoring Scripts

This repository contains a set of simple, practical Bash scripts designed to handle common system administration and automation tasks with minimal overhead.

## Features

- System resource monitoring (CPU, memory, disk usage)
- Threshold-based alerts
- Reusable script patterns for automation
- Modular and easy-to-extend scripts

---

## Philosophy

These scripts are intentionally lightweight and transparent.  
They are not meant to replace full monitoring solutions like Prometheus or Datadog, but to provide:

- Quick diagnostics  
- Learning references for shell scripting  
- Simple automation building blocks  

---

## Example Use Cases

- Running periodic health checks via `cron`
- Debugging performance issues on remote servers
- Bootstrapping monitoring in minimal environments
- Learning how to interact with Linux system metrics

## Getting Started

```bash
chmod +x script.sh
./script.sh
