#!/usr/bin/env bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

{ command -v drill > /dev/null && dig=drill; } || { command -v dig > /dev/null && dig=dig; } || { echo "error: dig was not found. Please install dnsutils."; exit 1; }

# Create temp file for results
RESULTS_FILE=$(mktemp)
trap "rm -f $RESULTS_FILE" EXIT

NAMESERVERS=`cat /etc/resolv.conf | grep ^nameserver | cut -d " " -f 2 | sed 's/\(.*\)/&#&/'`

PROVIDERS_GLOBAL_V4="
1.1.1.1#Cloudflare 
1.0.0.1#Cloudflare-Sec
185.228.168.9#CleanBrowsing
185.228.169.9#CleanBrowsing-Sec
94.140.14.14#Adguard
94.140.15.15#Adguard-Sec
76.76.2.0#ControlD-Uncensored
76.76.10.0#ControlD-Sec
185.222.222.222#DNS.SB
45.11.45.11#DNS.SB-Sec
193.110.81.254#DNS0.EU
185.253.5.254#DNS0.EU-Sec
8.8.8.8#Google
8.8.4.4#Google-Sec
194.242.2.2#Mullvad
95.85.95.85#Gcore
2.56.220.2#Gcore-Sec
9.9.9.9#Quad9
149.112.112.112#Quad9-Sec
64.6.64.6#Verisign
64.6.65.6#Verisign-Sec
156.154.70.1#Neustar
156.154.71.1#Neustar-Sec
84.200.69.80#DNS.WATCH
84.200.70.40#DNS.WATCH-Sec
195.46.39.39#SafeDNS
195.46.39.40#SafeDNS-Sec
185.121.177.177#OpenNIC
169.239.202.202#OpenNIC-Sec
91.239.100.100#UncensoredDNS
89.233.43.71#UncensoredDNS-Sec
81.218.119.11#GreenTeamDNS
209.88.198.133#GreenTeamDNS-Sec
208.67.222.222#Cisco-Umbrella
208.67.220.220#Cisco-Umbrella-Sec
8.26.56.26#Comodo
8.20.247.20#Comodo-Sec
4.2.2.1#Level3
209.244.0.3#Level3-A
209.244.0.4#Level3-B
80.80.80.80#Freenom
80.80.81.81#Freenom-Sec
199.85.126.10#Norton
199.85.127.10#Norton-Sec
45.90.28.82#NextDNS
45.90.30.82#NextDNS-Sec
45.90.28.202#NextDNS-Sec2
95.217.11.63#NWPS.fi
135.181.103.31#NWPS.fi-Sec
81.3.27.54#LightningWireLabs
80.67.169.12#FDN
80.67.169.40#FDN-Sec
45.80.1.6#LinuxPatch
"

PROVIDERS_RU_V4="
83.220.169.155#Comss.one
212.109.195.93#Comss.one-Sec
77.88.8.8#Yandex
77.88.8.1#Yandex-Sec
195.208.4.1#NSDI
195.208.5.1#NSDI-Sec
91.122.77.189#Rostelecom
195.210.172.43#MTS
195.210.172.46#MTS-Sec
217.10.44.35#AKADO
"

PROVIDERS_GLOBAL_V6="
2606:4700:4700::1111#cloudflare-v6
2001:4860:4860::8888#google-v6
2620:fe::fe#quad9-v6
2620:119:35::35#opendns-v6
2a0d:2a00:1::1#cleanbrowsing-v6
2a00:5a60::ad1:0ff#adguard-v6
2610:a1:1018::3#neustar-v6
"

PROVIDERS_RU_V6="
2a02:6b8::feed:0ff#yandex-v6
"

# Lists of domains
DOMAINS_GLOBAL="www.google.com amazon.com facebook.com www.youtube.com twitter.com"
DOMAINS_RU="ya.ru mail.ru vk.com ozon.ru gosuslugi.ru"

# Determine IPv6 support
$dig +short +tries=1 +time=2 +stats @2a0d:2a00:1::1 www.google.com |grep 216.239.38.120 >/dev/null 2>&1
if [ $? = 0 ]; then
    hasipv6="true"
fi

# Header function
print_banner() {
    clear
    echo -e "${GREEN}"
    echo "  ____  _   _ ____  ____  _____ ____  _____ _____ ____  _____ "
    echo " |  _ \| \ | / ___||  _ \| ____|  _ \|  ___|_   _| ____|/ ___|"
    echo " | | | |  \| \___ \| |_) |  _| | |_) | |_    | | |  _|  \___ \\"
    echo " | |_| | |\  |___) |  __/| |___|  _ <|  _|   | | | |___  ___) |"
    echo " |____/|_| \_|____/|_|   |_____|_| \_\_|     |_| |_____||____/ "
    echo -e "${NC}"
    echo "         DNS Performance & Stability Test (RU/Global)"
    echo "================================================================"
    echo ""
}

print_banner

# Step 1: Select Region
echo -e "${YELLOW}Step 1: Select Region${NC}"
echo "1) Russian Domains (RU) - ya.ru, vk.com, etc."
echo "2) Global Domains       - google.com, facebook.com, etc."
echo "3) All (RU + Global)    - Comprehensive test"
read -p "Enter choice [1-3]: " region_choice


case $region_choice in
    1) DOMAINS2TEST="$DOMAINS_RU" ;;
    2) DOMAINS2TEST="$DOMAINS_GLOBAL" ;;
    *) DOMAINS2TEST="$DOMAINS_RU $DOMAINS_GLOBAL" ;;
esac

echo ""

# Step 2: Select DNS Providers
echo -e "${YELLOW}Step 2: Select DNS Providers${NC}"
echo "1) Russian DNS (RU)     - Yandex, Comss, MTS, etc."
echo "2) Global DNS           - Cloudflare, Google, Quad9, etc."
echo "3) All (RU + Global)    - Complete list"
read -p "Enter choice [1-3]: " provider_choice

echo ""

# Determine IP mode (ipv4, ipv6, or all)
ip_mode="ipv4"
if [ "x$1" = "xipv6" ]; then
    ip_mode="ipv6"
elif [ "x$1" = "xall" ]; then
    ip_mode="all"
fi

if [ "$ip_mode" != "ipv4" ] && [ "x$hasipv6" = "x" ]; then
    echo "error: IPv6 support not found. Unable to do the ipv6 test."
    exit 1
fi

# Build provider list based on IP mode and Menu Choice
providerstotest=""

add_providers() {
    local type=$1 # ru or global
    
    if [ "$ip_mode" = "ipv4" ] || [ "$ip_mode" = "all" ]; then
        if [ "$type" = "ru" ]; then providerstotest="$providerstotest $PROVIDERS_RU_V4"; fi
        if [ "$type" = "global" ]; then providerstotest="$providerstotest $PROVIDERS_GLOBAL_V4"; fi
    fi
    
    if [ "$ip_mode" = "ipv6" ] || [ "$ip_mode" = "all" ]; then
         if [ "$type" = "ru" ]; then providerstotest="$providerstotest $PROVIDERS_RU_V6"; fi
         if [ "$type" = "global" ]; then providerstotest="$providerstotest $PROVIDERS_GLOBAL_V6"; fi
    fi
}

case $provider_choice in
    1) # RU
        add_providers "ru"
        ;;
    2) # Global
        add_providers "global"
        ;;
    *) # All
        add_providers "ru"
        add_providers "global"
        ;;
esac

# Step 3: Select Test Mode
echo -e "${YELLOW}Step 3: Select Test Mode${NC}"
echo "1) Quick Test      (1 run)   - Fast check"
echo "2) Stability Test  (10 runs) - Detects drops & averages latency"
read -p "Enter choice [1-2]: " mode_choice

is_stability=false
max_runs=1

case $mode_choice in
    2)
        is_stability=true
        max_runs=10
        ;;
    *)
        # Default is Quick Test
        ;;
esac

echo ""
if [ "$is_stability" = "true" ]; then
    echo "Starting 10-run stability test..."
else
    echo "Testing DNS performance..."
fi
echo ""

# Calculate total domains
totaldomains=0
for d in $DOMAINS2TEST; do
    totaldomains=$((totaldomains + 1))
done

if [ "$totaldomains" -eq 0 ]; then
    echo "Error: No domains selected for testing."
    exit 1
fi

# Header function
print_header() {
    printf "%-21s" ""
    for d in $DOMAINS2TEST; do
        d_short=$(echo $d | cut -c1-10)
        printf "%-12s" "$d_short"
    done
    printf "%-12s" "Average"
    echo ""
}

print_header

start_time=$SECONDS
run_count=0

while true; do
    if [ "$is_stability" = "true" ]; then
        run_count=$((run_count + 1))
        echo "--- Run #$run_count / $max_runs ---"
    fi

    for p in $NAMESERVERS $providerstotest; do
        pip=${p%%#*}
        pname=${p##*#}
        ftime=0
        
        printf "%-21s" "$pname"
        
        # Check if server is up first to avoid long waits on dead servers
        # Simple ping check or single dig check (fast)
        # Using dig to check reachability quickly
        check_up=`$dig +tries=1 +time=1 +short @$pip . > /dev/null 2>&1; echo $?`
        
        is_down=0
        if [ "$check_up" -ne 0 ]; then
             # Try one more time with a real domain
             check_up_retry=`$dig +tries=1 +time=1 +short @$pip google.com > /dev/null 2>&1; echo $?`
             if [ "$check_up_retry" -ne 0 ]; then
                is_down=1
             fi
        fi

        if [ "$is_down" -eq 1 ]; then
            # Server seems down, skip detailed tests
            for d in $DOMAINS2TEST; do
                printf "${RED}%-12s${NC}" "DOWN"
                ftime=$((ftime + 1000))
            done
            printf "  ${RED}1000${NC}\n"
            # Log DOWN for analysis
            echo "DOWN $pname $pip" >> "$RESULTS_FILE"
            continue
        fi

        for d in $DOMAINS2TEST; do
            # Optimized dig: 2 tries, 1s timeout each.
            # This prevents hanging for too long but handles 1 dropped packet.
            ttime=`$dig +tries=2 +time=1 +stats @$pip $d |grep "Query time:" | cut -d : -f 2- | cut -d " " -f 2`
            
            if [ -z "$ttime" ]; then
                ttime=1000
            elif [ "x$ttime" = "x0" ]; then
                ttime=1
            fi

            # Color coding
            if [ "$ttime" -lt 50 ]; then
                printf "${GREEN}%-12s${NC}" "$ttime ms"
            elif [ "$ttime" -lt 150 ]; then
                printf "${YELLOW}%-12s${NC}" "$ttime ms"
            else
                 printf "${RED}%-12s${NC}" "$ttime ms"
            fi
            
            ftime=$((ftime + ttime))
        done
        
        # Calculate average using awk instead of bc
        avg=$(awk "BEGIN {printf \"%.2f\", $ftime/$totaldomains}")
        echo "  $avg"
        
        # Save result for top 2 calculation (avg name ip)
        echo "$avg $pname $pip" >> "$RESULTS_FILE"
    done

    # Break loop if not stability test
    if [ "$is_stability" = "false" ]; then
        break
    fi

    # Check run limit
    if [ "$run_count" -ge "$max_runs" ]; then
        break
    fi
    
    # Small pause between runs to not flood too aggressively
    sleep 2
    echo ""
done

echo ""
echo "========================================"
echo " Best 2 DNS"
if [ "$is_stability" = "true" ]; then
    echo " (Based on 10 runs average, excluding unstable)"
fi
echo "========================================"
# Sort by average time (numeric), take top 2
# Exclude current system resolver (127.0.0.53) if desired, but user might want to know if local is best.
# We will show whatever is best.

if [ -f "$RESULTS_FILE" ]; then
    # Use awk to aggregate results
    # Logic: 
    # 1. Sum latency and count runs per provider.
    # 2. Count DOWN occurrences.
    # 3. If DOWN count >= 2, exclude provider (unstable).
    # 4. Calculate overall average.
    
    awk '
    {
        name = $2
        ip = $3
        val = $1
        
        if (val == "DOWN") {
            downs[name]++
            # Store IP just in case it is only seen as DOWN
            ips[name] = ip
        } else {
            sum[name] += val
            count[name]++
            ips[name] = ip
        }
    }
    END {
        for (name in ips) {
            # Exclusion criteria: 2 or more failures implies instability in 10 min test
            # For quick test (single run), downs will be 0 or 1.
            # If quick test, we still show result even if 1 failure (it is just DOWN).
            # We can detect mode by checking total runs, but simpler is:
            # If count > 0, calculate avg.
            
            # Strict stability check:
            # If downs >= 2, skip.
            if (downs[name] >= 2) {
                continue
            }
            
            if (count[name] > 0) {
                avg = sum[name] / count[name]
                printf "%.2f %s %s\n", avg, name, ips[name]
            }
        }
    }' "$RESULTS_FILE" | sort -n | head -n 2 | while read avg name ip; do
        echo "  $name ($ip) - $avg ms"
    done
else
    echo "No results found."
fi
echo ""

exit 0;
