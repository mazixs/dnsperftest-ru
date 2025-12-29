<div align="center">

# DNS Performance Test

**Benchmark DNS latency and stability for Russian & Global providers**

[![License](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE.txt)
[![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25.svg?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux-FCC624.svg?logo=linux&logoColor=black)](https://kernel.org)
[![Release](https://img.shields.io/github/v/release/mazixs/dnsperftest-ru?label=Release)](https://github.com/mazixs/dnsperftest-ru/releases)

</div>

---

## Overview

Interactive Bash script for testing DNS server performance. Measures latency across multiple domains and providers, with support for stability testing over multiple runs.

**Key capabilities:**
- Test Russian, Global, or mixed domain sets
- Choose specific DNS provider groups (RU / Global / All)
- Quick single-run or 10-run stability mode
- Automatic filtering of unstable servers
- Top 6 recommendations based on average latency
- IPv6 auto-detection and support

---

## Quick Start

### One-liner install

```bash
# wget
wget -qO dnstest.sh https://raw.githubusercontent.com/mazixs/dnsperftest-ru/v2.0.0/dnstest.sh && chmod +x dnstest.sh && ./dnstest.sh

# curl
curl -sO https://raw.githubusercontent.com/mazixs/dnsperftest-ru/v2.0.0/dnstest.sh && chmod +x dnstest.sh && ./dnstest.sh
```

### Requirements

| Dependency | Package |
|:-----------|:--------|
| Bash shell | *pre-installed* |
| DNS tools  | `dnsutils` / `bind-tools` / `bind-dig` |
| Awk        | *pre-installed* |

<details>
<summary><b>Installation by distro</b></summary>

| Distro | Command |
|:-------|:--------|
| Debian / Ubuntu | `sudo apt install dnsutils` |
| Arch Linux | `sudo pacman -S bind-tools` |
| Fedora / RHEL | `sudo dnf install bind-utils` |
| Entware (Keenetic, etc.) | `opkg install bash bind-dig wget-ssl ca-bundle` |

</details>

---

## Usage

The script uses a 3-step interactive menu:

| Step | Selection | Options |
|:-----|:----------|:--------|
| **1** | Domains | RU (`ya.ru`, `vk.com`) / Global (`google.com`) / All |
| **2** | DNS Providers | RU (`Yandex`, `MTS`) / Global (`Cloudflare`, `Google`) / All |
| **3** | Test Mode | Quick (1 run) / Stability (10 runs) |

> In Stability Mode, servers with 2+ failures are excluded from recommendations.

---

## Example Output

```
  ____  _   _ ____  ____  _____ ____  _____ _____ ____  _____
 |  _ \| \ | / ___||  _ \| ____|  _ \|  ___|_   _| ____|/ ___|
 | | | |  \| \___ \| |_) |  _| | |_) | |_    | | |  _|  \___ \
 | |_| | |\  |___) |  __/| |___|  _ <|  _|   | | | |___  ___) |
 |____/|_| \_|____/|_|   |_____|_| \_\_|     |_| |_____||____/

         DNS Performance & Stability Test (RU/Global)
================================================================

--- Run #1 / 10 ---
                     ya.ru       vk.com      gosuslugi   Average
Yandex               8 ms        9 ms        9 ms        8.66
Comss.one            15 ms       16 ms       15 ms       15.33
Google               18 ms       20 ms       19 ms       19.00

========================================
 Best 6 DNS
 (Based on 10 runs average, excluding unstable)
========================================
  Yandex (77.88.8.8) - 8.20 ms
  Comss.one (83.220.169.155) - 15.10 ms
  Google (8.8.8.8) - 19.50 ms
  Cloudflare (1.1.1.1) - 20.10 ms
  Quad9 (9.9.9.9) - 22.00 ms
  AdGuard (94.140.14.14) - 25.40 ms
```

---

## How It Works

1. **Connectivity probe** — fast check; unreachable servers marked `DOWN`
2. **Latency test** — `dig` queries with 1s timeout, 2 retries
3. **Aggregation** — Quick mode shows instant results; Stability mode averages 10 runs and filters unstable servers

---

## License

Licensed under **GPLv3**. See [LICENSE.txt](LICENSE.txt).

Based on [cleanbrowsing/dnsperftest](https://github.com/cleanbrowsing/dnsperftest).
