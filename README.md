# 🚀 DNS Performance & Stability Test (RU/Global)

![License](https://img.shields.io/badge/license-GPLv3-blue.svg)
![Bash](https://img.shields.io/badge/language-Bash-green.svg)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)

A powerful and interactive Bash script to benchmark the latency and stability of various DNS providers against Russian and Global domains.

---

## ✨ Features

| Feature | Description |
| :--- | :--- |
| 🌍 **Multi-Region Support** | Choose between **Russian (RU)**, **Global**, or **All** domains/providers. |
| 🛡️ **Extensive Providers** | Tests popular global DNS (Cloudflare, Google) and local RU providers (Yandex, Comss, MTS). |
| ⚡ **Smart Handling** | Optimized `dig` timeouts (1s) and fast skip for dead servers. |
| 📊 **Stability Mode** | **10-run stability test** to detect packet loss and average out latency spikes. |
| 🏆 **Best 6 DNS** | Automatically calculates and suggests the **Top 6** fastest and most stable servers. |
| 🌈 **Rich Output** | Color-coded results (Green/Yellow/Red) for instant readability. |
| 📡 **IPv6 Ready** | Auto-detects IPv6 connectivity and includes IPv6 resolvers if available. |

---

## 🚀 Usage

### Prerequisites
- **Bash** (shell)
- **DNS Utils** (`dig` or `drill`)
- **Awk** (standard on most Linux distros)

### 📦 Quick Install (Single Script)

You can download and run the script directly without cloning the repository.

**Using wget:**
```bash
wget https://raw.githubusercontent.com/mazixs/dnsperftest-ru/v2.0.0/dnstest.sh
chmod +x dnstest.sh
./dnstest.sh
```

**Using curl:**
```bash
curl -O https://raw.githubusercontent.com/mazixs/dnsperftest-ru/v2.0.0/dnstest.sh
chmod +x dnstest.sh
./dnstest.sh
```

### 📦 Manual Installation (Git Clone)

If you prefer to have the full source code:

#### Debian / Ubuntu
```bash
sudo apt install dnsutils
git clone https://github.com/mazixs/dnsperftest-ru.git
cd dnsperftest-ru
chmod +x dnstest.sh
./dnstest.sh
```

#### Arch Linux
```bash
sudo pacman -S bind-tools
```

#### Fedora / CentOS / RHEL
```bash
sudo dnf install bind-utils
```

#### Entware (Routers / NAS)
```bash
opkg update
opkg install bash bind-dig wget-ssl ca-bundle
wget https://raw.githubusercontent.com/mazixs/dnsperftest-ru/v2.0.0/dnstest.sh
chmod +x dnstest.sh
bash ./dnstest.sh
```

---

## 🎮 Interactive Menu

The script guides you through a simple 3-step configuration:

### 1️⃣ Step 1: Select Region (Domains)
Define **which websites** will be used for latency testing.
*   **Russian Domains (RU)**: `ya.ru`, `vk.com`, `gosuslugi.ru`, etc.
*   **Global Domains**: `google.com`, `amazon.com`, etc.
*   **All**: A mix of both for a comprehensive picture.

### 2️⃣ Step 2: Select DNS Providers
Define **which DNS servers** you want to test against.
*   **Russian DNS**: `Yandex`, `Comss.one`, `MTS`, `Rostelecom`, etc.
*   **Global DNS**: `Cloudflare`, `Google`, `Quad9`, `OpenDNS`, etc.
*   **All**: The complete list (recommended for finding the absolute best).

### 3️⃣ Step 3: Select Test Mode
*   **🚀 Quick Test (1 run)**: Instant snapshot of current performance.
*   **📈 Stability Test (10 runs)**: Performs 10 sequential lookups to calculate a reliable average and detect packet loss. *Highly recommended for final selection.*

> **Note:** In Stability Mode, servers with >2 failures are automatically marked as "Unstable" and excluded from recommendations.

---

## 🖥️ Example Output

```text
Step 1: Select Region -> 1 (RU)
Step 2: Select DNS Providers -> 1 (RU)
Step 3: Select Test Mode -> 2 (Stability)

Starting 10-run stability test...

--- Run #1 / 10 ---
                     ya.ru       vk.com      gosuslugi.  Average     
127.0.0.53           1 ms        1 ms        1 ms          1.00
yandex               8 ms        9 ms        9 ms          8.66
comss.one            15 ms       16 ms       15 ms         15.33
mts                  25 ms       24 ms       26 ms         25.00
...

========================================
 Best 6 DNS
 (Based on 10 runs average, excluding unstable)
========================================
  yandex (77.88.8.8) - 8.20 ms
  comss.one (83.220.169.155) - 15.10 ms
  google (8.8.8.8) - 19.50 ms
  cloudflare (1.1.1.1) - 20.10 ms
  quad9 (9.9.9.9) - 22.00 ms
  adguard (94.140.14.14) - 25.40 ms
```

---

## ⚙️ How It Works

1.  **Connectivity Check**: Before running full tests, the script sends a quick probe to each DNS server. If it's unreachable, it is marked as `DOWN` immediately to save time.
2.  **Latency Measurement**: It queries specific domains using `dig`.
    *   **Timeout**: 1 second.
    *   **Retries**: 2 attempts.
3.  **Aggregation**:
    *   In **Quick Mode**, it reports the immediate result.
    *   In **Stability Mode**, it aggregates results from 10 runs, filters out unstable providers (packet loss), and calculates the mean latency.

---

## 📜 License
This project is licensed under **GPLv3**.

### Credits
Forked and enhanced from [cleanbrowsing/dnsperftest](https://github.com/cleanbrowsing/dnsperftest).
