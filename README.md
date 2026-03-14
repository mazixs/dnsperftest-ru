<div align="center">

# DNS Performance Benchmark

**One-file Bash benchmark for DNS v4, DNS v6, DoH and DoT**

[![License](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE.txt)
[![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25.svg?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux-FCC624.svg?logo=linux&logoColor=black)](https://kernel.org)

</div>

## What It Does

`dnstest.sh` benchmarks a curated set of Russian and global DNS providers from one file, with no `dig`, `drill` or `kdig` dependency.

It supports:

- Classic `DNS v4` and `DNS v6` using native Bash UDP sockets
- `DoH` with real `application/dns-message` POST requests through `curl`
- `DoT` with a real DNS-over-TLS payload through `openssl`
- Quick mode and multi-run stability mode
- Separate `Top 3` recommendations for every selected mode
- A separate system resolver reference block from `/etc/resolv.conf`
- Early quarantine for targets that fail the initial double probe

The domain set and provider pool are intentionally decoupled. That means RU domains can be tested against global providers like `NextDNS`, `Cloudflare` or `Google`.

## Current Catalog

Verified public targets currently shipped in the script:

- Global: `Cloudflare`, `Google Public DNS`, `Quad9`, `AdGuard DNS`, `NextDNS`
- Russian: `Yandex DNS`, `Comss.one`

The secure catalog is intentionally conservative. If a provider's `DoH` or `DoT` endpoint was not cleanly confirmed for this productized flow, it is omitted from that mode instead of being guessed.

## Requirements

Base tools:

- `bash`
- `awk`
- `sort`
- `od`
- `dd`
- `timeout`

Mode-specific tools:

- `curl` for `DoH`
- `openssl` for `DoT`

Notes:

- `DNS v6` is only enabled when the host can actually reach an IPv6 resolver.
- The script does not install anything and does not download helper files.

## Quick Start

Run locally:

```bash
chmod +x dnstest.sh
./dnstest.sh
```

Stable one-liner from the latest GitHub release:

```bash
curl -fsSLo dnstest.sh https://github.com/mazixs/dnsperftest-ru/releases/latest/download/dnstest.sh
chmod +x dnstest.sh
./dnstest.sh
```

Latest `master` one-liner:

```bash
curl -fsSLo dnstest.sh https://raw.githubusercontent.com/mazixs/dnsperftest-ru/master/dnstest.sh
chmod +x dnstest.sh
./dnstest.sh
```

If you want a specific stable version, replace `latest` with a tag:

```bash
curl -fsSLo dnstest.sh https://github.com/mazixs/dnsperftest-ru/releases/download/v3.0.0/dnstest.sh
chmod +x dnstest.sh
./dnstest.sh
```

Recommended usage:

- `releases/latest/download/dnstest.sh` for servers, routers, and production-like installs
- `raw.githubusercontent.com/.../master/dnstest.sh` if you explicitly want the newest unreleased changes

## CLI Usage

Interactive mode is the default. For automation, the script also supports flags:

```bash
./dnstest.sh \
  --lang ru \
  --profile quick \
  --domains ru \
  --providers all \
  --modes dns4,doh,dot
```

Available flags:

- `--lang ru|en`
- `--profile quick|stability`
- `--domains ru|global|all|custom`
- `--custom-domains domain1,domain2`
- `--providers system|ru|global|all`
- `--modes dns4,dns6,doh,dot`
- `--runs N`
- `--no-color`

Examples:

```bash
# RU domains against every public provider plus system resolver reference
./dnstest.sh --profile quick --domains ru --providers all --modes dns4,doh,dot

# Global domains, only global providers, encrypted transports only
./dnstest.sh --profile quick --domains global --providers global --modes doh,dot

# Short stability sweep
./dnstest.sh --profile stability --runs 3 --domains ru --providers all --modes dns4,doh,dot
```

## Interactive Flow

The interactive launcher uses 4 steps:

0. `Language`: `ru` or `en`
1. `Profile`: `quick` or `stability`
2. `Domain set`: `ru`, `global`, `all`, or `custom`
3. `Provider pool`: `system`, `ru`, `global`, or `all`
4. `Modes`: any combination of `dns4`, `dns6`, `doh`, `dot`

When `custom` is selected, the script asks for one or more domains separated by commas.

## Output Model

During execution the script prints one line per target:

- `[OK]` for clean runs
- `[DOWN]` when some domains fail in the current run
- `[QUAR]` when the initial double probe fails and the target is quarantined for the rest of the current run
- `[INFO]` for system resolver reference lines in the final report

The final report contains:

- `Top 3` public recommendations for every selected mode
- Concrete setup values for each recommendation (`DNS` IP, `DoH` URL, `DoT` host/IP)
- `median`, `p90`, `avg`, and `success rate`
- A short reason per recommended entry
- A system resolver reference block
- A quarantine summary

Recommendation thresholds:

- `quick`: only `100%` success candidates are recommended
- `stability`: only candidates with at least `95%` success and no hard quarantine are recommended

## Known Limits

- `DoH` and `DoT` are ranked separately from classic DNS because TLS/HTTPS overhead is real and should not be merged into UDP rankings.
- `DoH` and `DoT` in the UI are transport-first modes. The report shows the actual connection family used for those targets.
- Some providers may exist only in some modes. That is expected and preferable to shipping unverified secure endpoints.

## License

Licensed under **GPLv3**. See [LICENSE.txt](LICENSE.txt).

Based on [cleanbrowsing/dnsperftest](https://github.com/cleanbrowsing/dnsperftest), but heavily rewritten into a one-file transport benchmark.
