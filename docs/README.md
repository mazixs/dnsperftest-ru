# DNS Performance Test (RU/Global)

A Bash script to test the latency of various DNS providers against Russian and Global domains.

## Features

- **Multi-Region Support**: Select between Russian domains, Global domains, or both.
- **Smart Timeout Handling**: Optimized `dig` settings to prevent long hangs on packet loss.
- **Dead Server Detection**: Quickly skips servers that are down or unreachable.
- **Color-Coded Output**:
  - 🟢 **Green**: < 50ms (Fast)
  - 🟡 **Yellow**: 50ms - 150ms (Medium)
  - 🔴 **Red**: > 150ms (Slow)
- **IPv6 Support**: Automatically detects and tests IPv6 if available.
- **Top Recommendation**: Automatically suggests the top 2 fastest DNS servers for your connection at the end of the test.
- **Stability Test**: 10 sequential runs to calculate average latency and filter out unstable servers (drops).
- **Extensive Provider List**: Includes Global, Russian, Finnish, German, and French DNS providers.

## Usage

### Prerequisites
You need `bash` and `dnsutils` (contains `dig`) or `ldns` (contains `drill`). `awk` is used for calculations (usually pre-installed).

```bash
# Debian/Ubuntu
sudo apt install dnsutils

# Arch Linux
sudo pacman -S bind
```

### Running the Script

Make the script executable:
```bash
chmod +x dnstest.sh
```

Run it:
```bash
./dnstest.sh
```

You will be prompted to select a test mode:
1. **Quick Test - Russian Domains (RU)**: ya.ru, mail.ru, vk.com, etc.
2. **Quick Test - Global Domains**: google.com, facebook.com, etc.
3. **Quick Test - All**: Both sets.
4. **Stability Test (10 runs)**: Runs the test 10 times in a loop, aggregating results to find the most stable and fast servers.

### Command Line Arguments

You can filter providers by IP version:

```bash
./dnstest.sh ipv4   # Test only IPv4 providers
./dnstest.sh ipv6   # Test only IPv6 providers
./dnstest.sh all    # Test both (default behavior depends on system)
```

## Example Output

```text
                     ya.ru       mail.ru     vk.com      ozon.ru     gosuslugi.  Average     
127.0.0.53           1 ms        1 ms        1 ms        1 ms        1 ms          1.00
cloudflare           28 ms       24 ms       22 ms       33 ms       23 ms         26.00
google               19 ms       20 ms       19 ms       19 ms       19 ms         19.20
yandex               8 ms        5 ms        5 ms        9 ms        9 ms          7.20
adguard              DOWN        DOWN        DOWN        DOWN        DOWN          1000

========================================
 Best 2 DNS
========================================
  nextdns (45.90.28.202) - 4.40 ms
  yandex (77.88.8.7) - 7.20 ms
```

## How it works

The script queries a comprehensive list of public DNS resolvers (Google, Cloudflare, Yandex, Quad9, AdGuard, Comss, etc.) across multiple regions (Global, RU, EU) as well as your local system resolvers. It measures the time to resolve specific domains.

### Optimization Details
- **Timeout**: 1 second per try.
- **Retries**: 2 tries.
- If a server fails a quick connectivity check, it is skipped immediately to save time.

## License
MIT
