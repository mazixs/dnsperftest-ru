#!/usr/bin/env bash

set -u

VERSION="3.0.0"

PROGRAM_NAME=${0##*/}
DEFAULT_QUICK_RUNS=1
DEFAULT_STABILITY_RUNS=10
DNS_TIMEOUT=3
DOH_TIMEOUT=5
DOT_TIMEOUT=5
TOP_N=3

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

USE_COLOR=false
COMPACT_OUTPUT=false
HAS_TTY=false
TERMINAL_WIDTH=80
NO_COLOR_FLAG=false

PROFILE=""
LANG_CHOICE=""
DOMAINS_CHOICE=""
CUSTOM_DOMAINS_RAW=""
PROVIDERS_CHOICE=""
RUNS=""
SELECTED_MODES=()
SELECTED_DOMAINS=()
IPV6_STACK_AVAILABLE=false
TIMER_SOURCE="unknown"

PROVIDER_CATALOG=$(cat <<'EOF'
cloudflare|Cloudflare|global|1.1.1.1|2606:4700:4700::1111|https://cloudflare-dns.com/dns-query|1.1.1.1|2606:4700:4700::1111|cloudflare-dns.com|1.1.1.1|2606:4700:4700::1111|anycast,official
cloudflare-sec|Cloudflare-Sec|global|1.0.0.1||https://security.cloudflare-dns.com/dns-query|1.0.0.1||security.cloudflare-dns.com|1.0.0.1||secure-filter
cleanbrowsing|CleanBrowsing|global|185.228.168.9|2a0d:2a00:1::1|https://doh.cleanbrowsing.org/doh/family-filter/|185.228.168.9|2a0d:2a00:1::1|family-filter-dns.cleanbrowsing.org|185.228.168.9|2a0d:2a00:1::1|family-filter
cleanbrowsing-sec|CleanBrowsing-Sec|global|185.228.169.9||https://doh.cleanbrowsing.org/doh/security-filter/|185.228.169.9||security-filter-dns.cleanbrowsing.org|185.228.169.9||security-filter
adguard|Adguard|global|94.140.14.14|2a00:5a60::ad1:0ff|https://dns.adguard-dns.com/dns-query|94.140.14.14|2a00:5a60::ad1:0ff|dns.adguard-dns.com|94.140.14.14|2a00:5a60::ad1:0ff|anycast,official
adguard-sec|Adguard-Sec|global|94.140.15.15||https://dns-family.adguard-dns.com/dns-query|94.140.15.15||dns-family.adguard-dns.com|94.140.15.15||family-filter
controld-uncensored|ControlD-Uncensored|global|76.76.2.0||https://freedns.controld.com/uncensored|76.76.2.0||freedns.controld.com|76.76.2.0||anycast
controld-sec|ControlD-Sec|global|76.76.10.0||https://freedns.controld.com/p0|76.76.10.0||freedns.controld.com|76.76.10.0||secure-filter
dnssb|DNS.SB|global|185.222.222.222||https://doh.dns.sb/dns-query|185.222.222.222||dot.dns.sb|185.222.222.222||official
dnssb-sec|DNS.SB-Sec|global|45.11.45.11||||||||secure-filter
dns0eu|DNS0.EU|global|193.110.81.254||https://dns0.eu/dns-query|193.110.81.254||dns0.eu|193.110.81.254||official
dns0eu-sec|DNS0.EU-Sec|global|185.253.5.254||https://dns0.eu/zero/dns-query|185.253.5.254||zero.dns0.eu|185.253.5.254||secure-filter
google|Google|global|8.8.8.8|2001:4860:4860::8888|https://dns.google/dns-query|8.8.8.8|2001:4860:4860::8888|dns.google|8.8.8.8|2001:4860:4860::8888|anycast,official
google-sec|Google-Sec|global|8.8.4.4||https://dns.google/dns-query|8.8.4.4||dns.google|8.8.4.4||alt-ip
mullvad|Mullvad|global|194.242.2.2||https://doh.mullvad.net/dns-query|194.242.2.2||dot.mullvad.net|194.242.2.2||official
gcore|Gcore|global|95.85.95.85|2a03:90c0:999d::1|||||||official
gcore-sec|Gcore-Sec|global|2.56.220.2|2a03:90c0:9992::1|||||||secure-filter
quad9|Quad9|global|9.9.9.9|2620:fe::fe||||dns.quad9.net|9.9.9.9|2620:fe::fe|anycast,official,dot-only
quad9-sec|Quad9-Sec|global|149.112.112.112||https://dns.quad9.net/dns-query|149.112.112.112||dns.quad9.net|149.112.112.112||secure-filter
verisign|Verisign|global|64.6.64.6||||||||legacy
verisign-sec|Verisign-Sec|global|64.6.65.6||||||||legacy,secure-filter
dnswatch|DNS.WATCH|global|84.200.69.80||||||||legacy
dnswatch-sec|DNS.WATCH-Sec|global|84.200.70.40||||||||legacy,secure-filter
safedns|SafeDNS|global|195.46.39.39|2001:67c:2778::3939|||||||official
safedns-sec|SafeDNS-Sec|global|195.46.39.40|2001:67c:2778::3940|||||||official
uncensoreddns|UncensoredDNS|global|91.239.100.100||https://anycast.uncensoreddns.org/dns-query|91.239.100.100||unicast.uncensoreddns.org|91.239.100.100||official
uncensoreddns-sec|UncensoredDNS-Sec|global|89.233.43.71||||||||secure-filter
opendns|OpenDNS|global|208.67.222.222|2620:119:35::35|https://doh.opendns.com/dns-query|208.67.222.222|2620:119:35::35|dns.opendns.com|208.67.222.222|2620:119:35::35|official
opendns-sec|OpenDNS-Sec|global|208.67.220.220||||||||secure-filter
comodo|Comodo|global|8.26.56.26||||||||legacy
comodo-sec|Comodo-Sec|global|8.20.247.20||||||||legacy,secure-filter
level3|Level3|global|4.2.2.1||||||||legacy
level3-a|Level3-A|global|209.244.0.3||||||||legacy
level3-b|Level3-B|global|209.244.0.4||||||||legacy
nextdns|NextDNS|global|45.90.28.19|2a07:a8c0::15:8114|https://dns.nextdns.io|45.90.28.19|2a07:a8c0::15:8114|dns.nextdns.io|45.90.28.19|2a07:a8c0::15:8114|anycast,no-profile
nextdns-sec|NextDNS-Sec|global|45.90.30.19|2a07:a8c1::15:8114|https://dns.nextdns.io|45.90.30.19|2a07:a8c1::15:8114|dns.nextdns.io|45.90.30.19|2a07:a8c1::15:8114|anycast,no-profile
nwpsfi|NWPS.fi|global|95.217.11.63|2a01:4f9:c012:25a0::1|https://public.ns.nwps.fi/dns-query|95.217.11.63|2a01:4f9:c012:25a0::1|public.ns.nwps.fi|95.217.11.63|2a01:4f9:c012:25a0::1|official
nwpsfi-sec|NWPS.fi-Sec|global|135.181.103.31|2a01:4f9:c011:aa31::1|https://kids.ns.nwps.fi/dns-query|135.181.103.31|2a01:4f9:c011:aa31::1|kids.ns.nwps.fi|135.181.103.31|2a01:4f9:c011:aa31::1|kids-filter
comss|Comss.one|ru|83.220.169.155||https://dns.comss.one/dns-query|83.220.169.155||dns.comss.one|83.220.169.155||official
comss-sec|Comss.one-Sec|ru|212.109.195.93||https://dns.comss.one/dns-query|212.109.195.93||dns.comss.one|212.109.195.93||secure-filter
yandex|Yandex|ru|77.88.8.8|2a02:6b8::feed:0ff|https://common.dot.dns.yandex.net/dns-query|77.88.8.8||common.dot.dns.yandex.net|77.88.8.8||official
yandex-sec|Yandex-Sec|ru|77.88.8.1||https://common.dot.dns.yandex.net/dns-query|77.88.8.1||common.dot.dns.yandex.net|77.88.8.1||secure-filter
nsdi|NSDI|ru|195.208.4.1||||||||legacy
nsdi-sec|NSDI-Sec|ru|195.208.5.1||||||||legacy,secure-filter
rostelecom|Rostelecom|ru|91.122.77.189||||||||legacy
mts|MTS|ru|195.210.172.43||||||||legacy
mts-sec|MTS-Sec|ru|195.210.172.46||||||||legacy,secure-filter
akado|AKADO|ru|217.10.44.35||||||||legacy
EOF
)

DOMAINS_RU=(
  "ya.ru"
  "mail.ru"
  "vk.com"
  "ozon.ru"
  "gosuslugi.ru"
)

DOMAINS_GLOBAL=(
  "www.google.com"
  "amazon.com"
  "facebook.com"
  "www.youtube.com"
  "twitter.com"
)

declare -a TARGET_KEYS=()
declare -A TARGET_EXISTS
declare -A TARGET_PROVIDER_ID
declare -A TARGET_NAME
declare -A TARGET_GROUP
declare -A TARGET_MODE
declare -A TARGET_PUBLIC
declare -A TARGET_FAMILY
declare -A TARGET_CONNECT_IP
declare -A TARGET_URL
declare -A TARGET_HOST
declare -A TARGET_TAGS

declare -A RESULT_PROBED
declare -A RESULT_SAMPLES
declare -A RESULT_SUCCESS
declare -A RESULT_FAIL
declare -A RESULT_TOTAL
declare -A RESULT_QUARANTINED
declare -A RESULT_QUARANTINE_REASON

declare -A QUERY_ESCAPED
declare -A QUERY_TXID
declare -A QUERY_LENGTH

die() {
  printf '%s\n' "$(txt error_prefix) $*" >&2
  exit 1
}

warn() {
  printf '%s\n' "$(txt warning_prefix) $*" >&2
}

usage() {
  cat <<EOF
$(txt usage_title)
  ./${PROGRAM_NAME}
  ./${PROGRAM_NAME} --profile quick --domains ru --providers all --modes dns4,doh,dot

$(txt usage_options)
  --lang ru|en
  --profile quick|stability
  --domains ru|global|all|custom
  --custom-domains domain1,domain2
  --providers system|ru|global|all
  --modes dns4,dns6,doh,dot
  --runs N
  --no-color
  --help
EOF
}

txt() {
  local key=$1
  local lang=${LANG_CHOICE:-en}

  case "$lang:$key" in
    ru:error_prefix) printf '%s' "ошибка:" ;;
    en:error_prefix) printf '%s' "error:" ;;
    ru:warning_prefix) printf '%s' "предупреждение:" ;;
    en:warning_prefix) printf '%s' "warning:" ;;
    ru:usage_title) printf '%s' "Использование:" ;;
    en:usage_title) printf '%s' "Usage:" ;;
    ru:usage_options) printf '%s' "Опции:" ;;
    en:usage_options) printf '%s' "Options:" ;;
    ru:banner_title) printf '%s' " DNS Performance Benchmark v${VERSION}" ;;
    en:banner_title) printf '%s' " DNS Performance Benchmark v${VERSION}" ;;
    ru:step_lang) printf '%s' "Шаг 0: Выбор языка" ;;
    en:step_lang) printf '%s' "Step 0: Select Language" ;;
    ru:lang_ru) printf '%s' "1) Русский" ;;
    en:lang_ru) printf '%s' "1) Russian" ;;
    ru:lang_en) printf '%s' "2) English" ;;
    en:lang_en) printf '%s' "2) English" ;;
    ru:prompt_lang) printf '%s' "Выберите язык [1-2] (по умолчанию: 1): " ;;
    en:prompt_lang) printf '%s' "Enter choice [1-2] (default: 1): " ;;
    ru:step_profile) printf '%s' "Шаг 1: Выбор профиля" ;;
    en:step_profile) printf '%s' "Step 1: Select Profile" ;;
    ru:profile_quick) printf '%s' "1) Быстрый тест    (1 прогон)" ;;
    en:profile_quick) printf '%s' "1) Quick Test      (1 run)" ;;
    ru:profile_stability) printf '%s' "2) Тест стабильности (10 прогонов)" ;;
    en:profile_stability) printf '%s' "2) Stability Test  (10 runs)" ;;
    ru:prompt_profile) printf '%s' "Выберите [1-2] (по умолчанию: 1): " ;;
    en:prompt_profile) printf '%s' "Enter choice [1-2] (default: 1): " ;;
    ru:invalid_profile) printf '%s' "некорректный выбор профиля:" ;;
    en:invalid_profile) printf '%s' "invalid profile choice:" ;;
    ru:step_domains) printf '%s' "Шаг 2: Выбор набора доменов" ;;
    en:step_domains) printf '%s' "Step 2: Select Domain Set" ;;
    ru:domains_ru) printf '%s' "1) Российские домены" ;;
    en:domains_ru) printf '%s' "1) Russian domains" ;;
    ru:domains_global) printf '%s' "2) Глобальные домены" ;;
    en:domains_global) printf '%s' "2) Global domains" ;;
    ru:domains_all) printf '%s' "3) Все домены" ;;
    en:domains_all) printf '%s' "3) All domains" ;;
    ru:domains_custom) printf '%s' "4) Custom (мои домены)" ;;
    en:domains_custom) printf '%s' "4) Custom (my domains)" ;;
    ru:prompt_domains) printf '%s' "Выберите [1-4] (по умолчанию: 1): " ;;
    en:prompt_domains) printf '%s' "Enter choice [1-4] (default: 1): " ;;
    ru:prompt_custom_domains) printf '%s' "Введите один или несколько доменов через запятую: " ;;
    en:prompt_custom_domains) printf '%s' "Enter one or more domains, comma-separated: " ;;
    ru:invalid_domain_choice) printf '%s' "некорректный выбор доменов:" ;;
    en:invalid_domain_choice) printf '%s' "invalid domain choice:" ;;
    ru:step_providers) printf '%s' "Шаг 3: Выбор пула DNS-провайдеров" ;;
    en:step_providers) printf '%s' "Step 3: Select Provider Pool" ;;
    ru:providers_system) printf '%s' "1) Только системные резолверы" ;;
    en:providers_system) printf '%s' "1) System resolvers only" ;;
    ru:providers_ru) printf '%s' "2) Российские провайдеры" ;;
    en:providers_ru) printf '%s' "2) Russian providers" ;;
    ru:providers_global) printf '%s' "3) Глобальные провайдеры" ;;
    en:providers_global) printf '%s' "3) Global providers" ;;
    ru:providers_all) printf '%s' "4) Все провайдеры + системный reference" ;;
    en:providers_all) printf '%s' "4) All providers + system reference" ;;
    ru:prompt_providers) printf '%s' "Выберите [1-4] (по умолчанию: 4): " ;;
    en:prompt_providers) printf '%s' "Enter choice [1-4] (default: 4): " ;;
    ru:invalid_provider_choice) printf '%s' "некорректный выбор провайдеров:" ;;
    en:invalid_provider_choice) printf '%s' "invalid provider choice:" ;;
    ru:step_modes) printf '%s' "Шаг 4: Выбор режимов" ;;
    en:step_modes) printf '%s' "Step 4: Select Modes" ;;
    ru:prompt_modes) printf '%s' "Введите один или несколько вариантов через запятую (по умолчанию: %s): " ;;
    en:prompt_modes) printf '%s' "Enter one or more choices (comma-separated, default: %s): " ;;
    ru:config) printf '%s' "Конфигурация" ;;
    en:config) printf '%s' "Configuration" ;;
    ru:cfg_profile) printf '%s' "профиль" ;;
    en:cfg_profile) printf '%s' "profile" ;;
    ru:cfg_domains) printf '%s' "домены" ;;
    en:cfg_domains) printf '%s' "domains" ;;
    ru:cfg_providers) printf '%s' "провайдеры" ;;
    en:cfg_providers) printf '%s' "providers" ;;
    ru:cfg_modes) printf '%s' "режимы" ;;
    en:cfg_modes) printf '%s' "modes" ;;
    ru:cfg_terminal) printf '%s' "терминал" ;;
    en:cfg_terminal) printf '%s' "terminal" ;;
    ru:color) printf '%s' "цвет" ;;
    en:color) printf '%s' "color" ;;
    ru:plain) printf '%s' "plain" ;;
    en:plain) printf '%s' "plain" ;;
    ru:preflight_failed) printf '%s' "Preflight не пройден" ;;
    en:preflight_failed) printf '%s' "Preflight failed" ;;
    ru:preflight_cannot_run) printf '%s' "Текущий хост не может выполнить выбранный набор тестов:" ;;
    en:preflight_cannot_run) printf '%s' "The current host cannot run the selected benchmark:" ;;
    ru:preflight) printf '%s' "Preflight" ;;
    en:preflight) printf '%s' "Preflight" ;;
    ru:available) printf '%s' "доступен" ;;
    en:available) printf '%s' "available" ;;
    ru:unavailable) printf '%s' "недоступен" ;;
    en:unavailable) printf '%s' "unavailable" ;;
    ru:execution) printf '%s' "Выполнение" ;;
    en:execution) printf '%s' "Execution" ;;
    ru:run_fmt) printf '%s' "Прогон %s/%s" ;;
    en:run_fmt) printf '%s' "Run %s/%s" ;;
    ru:quarantine_reason) printf '%s' "initial probe failed twice; target quarantined for the rest of this run" ;;
    en:quarantine_reason) printf '%s' "initial probe failed twice; target quarantined for the rest of this run" ;;
    ru:final_report) printf '%s' "Итоговый отчёт" ;;
    en:final_report) printf '%s' "Final Report" ;;
    ru:final_hint) printf '%s' "Top-списки рекомендуют только стабильные публичные DNS для реально выбранного режима." ;;
    en:final_hint) printf '%s' "Top lists recommend only stable public targets for the mode you actually plan to use." ;;
    ru:system_reference) printf '%s' "Системные резолверы" ;;
    en:system_reference) printf '%s' "System Resolver Reference" ;;
    ru:no_system_reference) printf '%s' "Системные резолверы не участвовали в этом запуске." ;;
    en:no_system_reference) printf '%s' "No system resolvers were part of this benchmark." ;;
    ru:quarantined_targets) printf '%s' "Цели в карантине" ;;
    en:quarantined_targets) printf '%s' "Quarantined Targets" ;;
    ru:no_quarantine) printf '%s' "Ни одна цель не была помещена в карантин." ;;
    en:no_quarantine) printf '%s' "No targets were quarantined." ;;
    ru:no_stable_candidates) printf '%s' "Стабильных публичных кандидатов для рекомендации не найдено." ;;
    en:no_stable_candidates) printf '%s' "No stable public candidates met the recommendation threshold." ;;
    ru:domains_error) printf '%s' "domains must be ru, global, all, or custom" ;;
    en:domains_error) printf '%s' "domains must be ru, global, all, or custom" ;;
    ru:providers_error) printf '%s' "providers must be system, ru, global, or all" ;;
    en:providers_error) printf '%s' "providers must be system, ru, global, or all" ;;
    ru:lang_error) printf '%s' "lang must be ru or en" ;;
    en:lang_error) printf '%s' "lang must be ru or en" ;;
    ru:custom_required) printf '%s' "custom domains were selected, but no --custom-domains value was provided" ;;
    en:custom_required) printf '%s' "custom domains were selected, but no --custom-domains value was provided" ;;
    ru:no_modes_selected) printf '%s' "не выбрано ни одного режима" ;;
    en:no_modes_selected) printf '%s' "no modes selected" ;;
    ru:unsupported_mode_selector) printf '%s' "неподдерживаемый селектор режима:" ;;
    en:unsupported_mode_selector) printf '%s' "unsupported mode selector:" ;;
    ru:quick) printf '%s' "быстрый" ;;
    en:quick) printf '%s' "quick" ;;
    ru:stability) printf '%s' "стабильность" ;;
    en:stability) printf '%s' "stability" ;;
    *)
      printf '%s' "$key"
      ;;
  esac
}

supports_color() {
  if [ "$NO_COLOR_FLAG" = true ]; then
    return 1
  fi
  if [ -n "${NO_COLOR-}" ]; then
    return 1
  fi
  if [ -t 1 ]; then
    return 0
  fi
  return 1
}

style_text() {
  local color=$1
  local text=$2

  if [ "$USE_COLOR" = true ]; then
    printf '%b%s%b' "$color" "$text" "$NC"
  else
    printf '%s' "$text"
  fi
}

metric_label() {
  local text=$1
  if [ "$USE_COLOR" = true ]; then
    printf '%b%s%b' "$CYAN" "$text" "$NC"
  else
    printf '%s' "$text"
  fi
}

muted_text() {
  local text=$1
  if [ "$USE_COLOR" = true ]; then
    printf '%b%s%b' "$BLUE" "$text" "$NC"
  else
    printf '%s' "$text"
  fi
}

emphasis_text() {
  local text=$1
  if [ "$USE_COLOR" = true ]; then
    printf '%b%s%b' "$BOLD" "$text" "$NC"
  else
    printf '%s' "$text"
  fi
}

rank_badge() {
  local rank=$1
  local label="#${rank}"
  local color=$BOLD

  case "$rank" in
    1) color=$GREEN ;;
    2) color=$YELLOW ;;
    3) color=$CYAN ;;
  esac

  style_text "$color" "[$label]"
}

section_heading() {
  local title=$1
  local color=$MAGENTA

  if [ "$title" = "$(txt system_reference)" ]; then
    color=$BLUE
  elif [ "$title" = "$(txt quarantined_targets)" ]; then
    color=$RED
  fi

  printf '%s\n' "$(style_text "$color" "$title")"
}

status_tag() {
  local status=$1
  local color=$NC

  case "$status" in
    OK) color=$GREEN ;;
    DOWN) color=$RED ;;
    QUAR) color=$MAGENTA ;;
    SKIP) color=$CYAN ;;
    INFO) color=$BLUE ;;
  esac

  style_text "$color" "[$status]"
}

detect_terminal() {
  local width=""

  if [ -t 1 ]; then
    HAS_TTY=true
  fi

  if [ -n "${COLUMNS-}" ] && [[ "${COLUMNS-}" =~ ^[0-9]+$ ]]; then
    width=$COLUMNS
  elif command -v tput >/dev/null 2>&1; then
    width=$(tput cols 2>/dev/null || true)
  fi

  if ! [[ "$width" =~ ^[0-9]+$ ]]; then
    width=80
  fi

  TERMINAL_WIDTH=$width
  if [ "$TERMINAL_WIDTH" -lt 110 ]; then
    COMPACT_OUTPUT=true
  fi

  if supports_color; then
    USE_COLOR=true
  fi
}

now_ms() {
  if [ -n "${EPOCHREALTIME-}" ]; then
    local raw_time=${EPOCHREALTIME/,/.}
    local sec=${raw_time%%[.,]*}
    local frac=${raw_time#*[.,]}
    if [ "$frac" = "$raw_time" ]; then
      frac="0"
    fi
    frac="${frac}000"
    TIMER_SOURCE="bash:EPOCHREALTIME"
    printf '%s\n' "$((10#$sec * 1000 + 10#${frac:0:3}))"
    return 0
  fi

  local date_ms
  date_ms=$(date +%s%3N 2>/dev/null || true)
  if [[ "$date_ms" =~ ^[0-9]+$ ]]; then
    TIMER_SOURCE="date:%s%3N"
    printf '%s\n' "$date_ms"
    return 0
  fi

  TIMER_SOURCE="date:%s"
  printf '%s\n' "$(( $(date +%s) * 1000 ))"
}

seconds_to_ms() {
  awk -v value="$1" 'BEGIN { printf "%d", (value * 1000) + 0.5 }'
}

format_percent_x10() {
  local value=${1:-0}
  printf '%d.%d%%' "$((value / 10))" "$((value % 10))"
}

calc_percent_x10() {
  local success=${1:-0}
  local total=${2:-0}

  if [ "$total" -le 0 ]; then
    printf '0\n'
    return 0
  fi

  printf '%s\n' "$(( (success * 1000 + total / 2) / total ))"
}

join_csv() {
  local out=""
  local item

  for item in "$@"; do
    if [ -n "$out" ]; then
      out+=","
    fi
    out+="$item"
  done

  printf '%s\n' "$out"
}

family_of_ip() {
  case "$1" in
    *:*) printf '%s\n' "ipv6" ;;
    *) printf '%s\n' "ipv4" ;;
  esac
}

is_ipv6_literal() {
  case "$1" in
    *:*) return 0 ;;
    *) return 1 ;;
  esac
}

mode_label() {
  case "$1" in
    dns4) printf '%s\n' "DNS v4" ;;
    dns6) printf '%s\n' "DNS v6" ;;
    doh) printf '%s\n' "DoH" ;;
    dot) printf '%s\n' "DoT" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

mode_short_label() {
  case "$1" in
    dns4) printf '%s\n' "DNS4" ;;
    dns6) printf '%s\n' "DNS6" ;;
    doh) printf '%s\n' "DoH" ;;
    dot) printf '%s\n' "DoT" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

mode_transport_label() {
  local key=$1
  local mode=${TARGET_MODE[$key]}
  local family=${TARGET_FAMILY[$key]}
  local base

  base=$(mode_short_label "$mode")
  case "$mode" in
    doh|dot)
      if [ -n "$family" ]; then
        if [ "$family" = "ipv4" ]; then
          printf '%s/%s\n' "$base" "4"
        else
          printf '%s/%s\n' "$base" "6"
        fi
      else
        printf '%s\n' "$base"
      fi
      ;;
    *)
      printf '%s\n' "$base"
      ;;
  esac
}

sanitize_key() {
  local value=$1
  value=${value//[^A-Za-z0-9]/-}
  printf '%s\n' "$value"
}

build_query_for_domain() {
  local domain=$1
  local txid
  local escaped
  local label
  local txid_hex

  if [ -n "${QUERY_ESCAPED[$domain]:-}" ]; then
    return 0
  fi

  txid=$(( ((RANDOM << 8) ^ RANDOM) & 65535 ))
  printf -v txid_hex '%04x' "$txid"
  printf -v escaped '\\x%02x\\x%02x\\x01\\x00\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00' \
    "$(( (txid >> 8) & 255 ))" "$(( txid & 255 ))"

  IFS='.' read -r -a labels <<<"$domain"
  for label in "${labels[@]}"; do
    printf -v escaped '%s\\x%02x%s' "$escaped" "${#label}" "$label"
  done

  escaped+='\x00\x00\x01\x00\x01'
  QUERY_ESCAPED[$domain]=$escaped
  QUERY_TXID[$domain]=$txid_hex
  QUERY_LENGTH[$domain]=$(( ${#domain} + 18 ))
}

length_prefix_escaped() {
  local length=$1
  printf '\\x%02x\\x%02x' "$(( (length >> 8) & 255 ))" "$(( length & 255 ))"
}

probe_ipv6_stack() {
  local domain="www.google.com"
  local response_hex=""

  require_command timeout || return 1
  build_query_for_domain "$domain"

  if ! { exec {fd}<>"/dev/udp/2606:4700:4700::1111/53"; } 2>/dev/null; then
    return 1
  fi

  printf '%b' "${QUERY_ESCAPED[$domain]}" >&"$fd" 2>/dev/null || {
    exec {fd}>&-
    exec {fd}<&-
    return 1
  }

  response_hex=$(timeout "$DNS_TIMEOUT" dd bs=2 count=1 status=none <&"$fd" | od -An -tx1 | tr -d ' \n')
  exec {fd}>&-
  exec {fd}<&-

  if [ "$response_hex" = "${QUERY_TXID[$domain]}" ]; then
    return 0
  fi

  return 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1
}

pick_secure_endpoint() {
  local ip4=$1
  local ip6=$2

  if [ -n "$ip4" ]; then
    printf '%s|%s\n' "$ip4" "ipv4"
    return 0
  fi

  if [ -n "$ip6" ] && [ "$IPV6_STACK_AVAILABLE" = true ]; then
    printf '%s|%s\n' "$ip6" "ipv6"
    return 0
  fi

  printf '|\n'
}

add_target() {
  local key=$1
  local provider_id=$2
  local name=$3
  local group=$4
  local mode=$5
  local public_flag=$6
  local family=$7
  local connect_ip=$8
  local url=$9
  local host=${10}
  local tags=${11}

  if [ -n "${TARGET_EXISTS[$key]:-}" ]; then
    return 0
  fi

  TARGET_EXISTS[$key]=1
  TARGET_KEYS+=("$key")
  TARGET_PROVIDER_ID[$key]=$provider_id
  TARGET_NAME[$key]=$name
  TARGET_GROUP[$key]=$group
  TARGET_MODE[$key]=$mode
  TARGET_PUBLIC[$key]=$public_flag
  TARGET_FAMILY[$key]=$family
  TARGET_CONNECT_IP[$key]=$connect_ip
  TARGET_URL[$key]=$url
  TARGET_HOST[$key]=$host
  TARGET_TAGS[$key]=$tags
}

build_public_targets() {
  local row

  while IFS='|' read -r id name group dns4 dns6 doh_url doh_ip4 doh_ip6 dot_host dot_ip4 dot_ip6 tags; do
    [ -n "$id" ] || continue

    case "$PROVIDERS_CHOICE" in
      ru)
        [ "$group" = "ru" ] || continue
        ;;
      global)
        [ "$group" = "global" ] || continue
        ;;
      system)
        continue
        ;;
      all)
        ;;
      *)
        continue
        ;;
    esac

    local mode
    for mode in "${SELECTED_MODES[@]}"; do
      case "$mode" in
        dns4)
          [ -n "$dns4" ] || continue
          add_target "${id}::dns4" "$id" "$name" "$group" "dns4" "yes" "ipv4" "$dns4" "" "" "$tags"
          ;;
        dns6)
          [ -n "$dns6" ] || continue
          add_target "${id}::dns6" "$id" "$name" "$group" "dns6" "yes" "ipv6" "$dns6" "" "" "$tags"
          ;;
        doh)
          [ -n "$doh_url" ] || continue
          row=$(pick_secure_endpoint "$doh_ip4" "$doh_ip6")
          local doh_connect_ip=${row%%|*}
          local doh_family=${row##*|}
          [ -n "$doh_connect_ip" ] || continue
          add_target "${id}::doh" "$id" "$name" "$group" "doh" "yes" "$doh_family" "$doh_connect_ip" "$doh_url" "$(url_host "$doh_url")" "$tags"
          ;;
        dot)
          [ -n "$dot_host" ] || continue
          row=$(pick_secure_endpoint "$dot_ip4" "$dot_ip6")
          local dot_connect_ip=${row%%|*}
          local dot_family=${row##*|}
          [ -n "$dot_connect_ip" ] || continue
          add_target "${id}::dot" "$id" "$name" "$group" "dot" "yes" "$dot_family" "$dot_connect_ip" "" "$dot_host" "$tags"
          ;;
      esac
    done
  done <<<"$PROVIDER_CATALOG"
}

parse_system_resolvers() {
  local raw_ns
  local family
  declare -A seen_resolver=()

  [ "$PROVIDERS_CHOICE" = "system" ] || [ "$PROVIDERS_CHOICE" = "all" ] || return 0

  while read -r raw_ns; do
    [ -n "$raw_ns" ] || continue
    [ -n "${seen_resolver[$raw_ns]:-}" ] && continue
    seen_resolver[$raw_ns]=1

    case "$raw_ns" in
      *%*)
        warn "skipping system resolver with zone index: $raw_ns"
        continue
        ;;
    esac

    family=$(family_of_ip "$raw_ns")

    if mode_selected "dns4" && [ "$family" = "ipv4" ]; then
      add_target "system-$(sanitize_key "$raw_ns")::dns4" "system-$raw_ns" "System $raw_ns" "system" "dns4" "no" "ipv4" "$raw_ns" "" "" "system"
    fi

    if mode_selected "dns6" && [ "$family" = "ipv6" ]; then
      add_target "system-$(sanitize_key "$raw_ns")::dns6" "system-$raw_ns" "System $raw_ns" "system" "dns6" "no" "ipv6" "$raw_ns" "" "" "system"
    fi
  done < <(awk '/^nameserver[[:space:]]+/ { print $2 }' /etc/resolv.conf 2>/dev/null)
}

build_targets() {
  build_public_targets
  parse_system_resolvers
}

mode_selected() {
  local wanted=$1
  local mode
  for mode in "${SELECTED_MODES[@]}"; do
    [ "$mode" = "$wanted" ] && return 0
  done
  return 1
}

url_host() {
  local url=$1
  local rest=${url#https://}
  rest=${rest#http://}
  printf '%s\n' "${rest%%/*}"
}

parse_modes() {
  local raw=$1
  local token
  local want_dns4=0
  local want_dns6=0
  local want_doh=0
  local want_dot=0

  raw=${raw//,/ }

  for token in $raw; do
    case "$token" in
      1|dns4|DNS4) want_dns4=1 ;;
      2|dns6|DNS6) want_dns6=1 ;;
      3|doh|DOH|DoH) want_doh=1 ;;
      4|dot|DOT|DoT) want_dot=1 ;;
      "")
        ;;
      *)
        die "$(txt unsupported_mode_selector) $token"
        ;;
    esac
  done

  SELECTED_MODES=()
  [ "$want_dns4" -eq 1 ] && SELECTED_MODES+=("dns4")
  [ "$want_dns6" -eq 1 ] && SELECTED_MODES+=("dns6")
  [ "$want_doh" -eq 1 ] && SELECTED_MODES+=("doh")
  [ "$want_dot" -eq 1 ] && SELECTED_MODES+=("dot")

  [ "${#SELECTED_MODES[@]}" -gt 0 ] || die "$(txt no_modes_selected)"
}

validate_choice() {
  local value=$1
  shift
  local allowed
  for allowed in "$@"; do
    [ "$value" = "$allowed" ] && return 0
  done
  return 1
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --lang)
        [ "$#" -ge 2 ] || die "--lang requires a value"
        LANG_CHOICE=$2
        shift 2
        ;;
      --profile)
        [ "$#" -ge 2 ] || die "--profile requires a value"
        PROFILE=$2
        shift 2
        ;;
      --domains)
        [ "$#" -ge 2 ] || die "--domains requires a value"
        DOMAINS_CHOICE=$2
        shift 2
        ;;
      --custom-domains)
        [ "$#" -ge 2 ] || die "--custom-domains requires a value"
        CUSTOM_DOMAINS_RAW=$2
        shift 2
        ;;
      --providers)
        [ "$#" -ge 2 ] || die "--providers requires a value"
        PROVIDERS_CHOICE=$2
        shift 2
        ;;
      --modes)
        [ "$#" -ge 2 ] || die "--modes requires a value"
        parse_modes "$2"
        shift 2
        ;;
      --runs)
        [ "$#" -ge 2 ] || die "--runs requires a value"
        RUNS=$2
        shift 2
        ;;
      --no-color)
        NO_COLOR_FLAG=true
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        die "unknown argument: $1"
        ;;
    esac
  done
}

trim_whitespace() {
  local value=$1
  value=${value#"${value%%[![:space:]]*}"}
  value=${value%"${value##*[![:space:]]}"}
  printf '%s\n' "$value"
}

parse_custom_domains() {
  local raw=$1
  local token

  SELECTED_DOMAINS=()
  raw=${raw//,/ }

  for token in $raw; do
    token=$(trim_whitespace "$token")
    [ -n "$token" ] || continue
    SELECTED_DOMAINS+=("$token")
  done

  [ "${#SELECTED_DOMAINS[@]}" -gt 0 ] || die "$(txt custom_required)"
}

interactive_pick() {
  local prompt=$1
  local default_value=$2
  local answer=""

  read -r -p "$prompt" answer
  if [ -z "$answer" ]; then
    printf '%s\n' "$default_value"
  else
    printf '%s\n' "$answer"
  fi
}

run_interactive_setup() {
  local answer
  local default_modes="1,3,4"

  if [ "$IPV6_STACK_AVAILABLE" = true ]; then
    default_modes="1,2,3,4"
  fi

  printf '%s\n' "$(style_text "$YELLOW" "$(txt step_lang)")"
  printf '%s\n' "$(txt lang_ru)"
  printf '%s\n' "$(txt lang_en)"
  answer=$(interactive_pick "$(txt prompt_lang)" "1")
  case "$answer" in
    1|ru|RU) LANG_CHOICE="ru" ;;
    2|en|EN) LANG_CHOICE="en" ;;
    *) LANG_CHOICE="ru" ;;
  esac
  printf '\n'

  print_banner
  printf '%s\n' "$(style_text "$YELLOW" "$(txt step_profile)")"
  printf '%s\n' "$(txt profile_quick)"
  printf '%s\n' "$(txt profile_stability)"
  answer=$(interactive_pick "$(txt prompt_profile)" "1")
  case "$answer" in
    1) PROFILE="quick" ;;
    2) PROFILE="stability" ;;
    *) die "$(txt invalid_profile) $answer" ;;
  esac
  printf '\n'

  printf '%s\n' "$(style_text "$YELLOW" "$(txt step_domains)")"
  printf '%s\n' "$(txt domains_ru)"
  printf '%s\n' "$(txt domains_global)"
  printf '%s\n' "$(txt domains_all)"
  printf '%s\n' "$(txt domains_custom)"
  answer=$(interactive_pick "$(txt prompt_domains)" "1")
  case "$answer" in
    1) DOMAINS_CHOICE="ru" ;;
    2) DOMAINS_CHOICE="global" ;;
    3) DOMAINS_CHOICE="all" ;;
    4) DOMAINS_CHOICE="custom" ;;
    *) die "$(txt invalid_domain_choice) $answer" ;;
  esac
  if [ "$DOMAINS_CHOICE" = "custom" ]; then
    CUSTOM_DOMAINS_RAW=$(interactive_pick "$(txt prompt_custom_domains)" "")
  fi
  printf '\n'

  printf '%s\n' "$(style_text "$YELLOW" "$(txt step_providers)")"
  printf '%s\n' "$(txt providers_system)"
  printf '%s\n' "$(txt providers_ru)"
  printf '%s\n' "$(txt providers_global)"
  printf '%s\n' "$(txt providers_all)"
  answer=$(interactive_pick "$(txt prompt_providers)" "4")
  case "$answer" in
    1) PROVIDERS_CHOICE="system" ;;
    2) PROVIDERS_CHOICE="ru" ;;
    3) PROVIDERS_CHOICE="global" ;;
    4) PROVIDERS_CHOICE="all" ;;
    *) die "$(txt invalid_provider_choice) $answer" ;;
  esac
  printf '\n'

  printf '%s\n' "$(style_text "$YELLOW" "$(txt step_modes)")"
  printf '%s\n' "1) DNS v4"
  printf '%s\n' "2) DNS v6"
  printf '%s\n' "3) DoH"
  printf '%s\n' "4) DoT"
  printf -v answer_prompt "$(txt prompt_modes)" "$default_modes"
  answer=$(interactive_pick "$answer_prompt" "$default_modes")
  parse_modes "$answer"
}

finalize_profile_and_runs() {
  if [ -z "$PROFILE" ]; then
    PROFILE="quick"
  fi

  validate_choice "$PROFILE" quick stability || die "profile must be quick or stability"

  if [ -z "$RUNS" ]; then
    if [ "$PROFILE" = "quick" ]; then
      RUNS=$DEFAULT_QUICK_RUNS
    else
      RUNS=$DEFAULT_STABILITY_RUNS
    fi
  fi

  [[ "$RUNS" =~ ^[0-9]+$ ]] || die "--runs must be a positive integer"
  [ "$RUNS" -ge 1 ] || die "--runs must be at least 1"

  if [ "$RUNS" -gt 1 ]; then
    PROFILE="stability"
  fi
}

select_domains() {
  case "$DOMAINS_CHOICE" in
    ru)
      SELECTED_DOMAINS=("${DOMAINS_RU[@]}")
      ;;
    global)
      SELECTED_DOMAINS=("${DOMAINS_GLOBAL[@]}")
      ;;
    all)
      SELECTED_DOMAINS=("${DOMAINS_RU[@]}" "${DOMAINS_GLOBAL[@]}")
      ;;
    custom)
      parse_custom_domains "$CUSTOM_DOMAINS_RAW"
      ;;
    *)
      die "$(txt domains_error)"
      ;;
  esac
}

print_banner() {
  printf '%s\n' "$(style_text "$GREEN" "  ____  _   _ ____  ____  _____ ____  _____ _____ ____  _____ ")"
  printf '%s\n' "$(style_text "$GREEN" " |  _ \\| \\ | / ___||  _ \\| ____|  _ \\|  ___|_   _| ____|/ ___|")"
  printf '%s\n' "$(style_text "$GREEN" " | | | |  \\| \\___ \\| |_) |  _| | |_) | |_    | | |  _|  \\___ \\")"
  printf '%s\n' "$(style_text "$GREEN" " | |_| | |\\  |___) |  __/| |___|  _ <|  _|   | | | |___  ___) |")"
  printf '%s\n' "$(style_text "$GREEN" " |____/|_| \\_|____/|_|   |_____|_| \\_\\_|     |_| |_____||____/ ")"
  printf '%s\n' "$(txt banner_title)"
  printf '%s\n' "================================================================"
}

print_selection_summary() {
  local modes_csv
  modes_csv=$(join_csv "${SELECTED_MODES[@]}")

  printf '\n'
  printf '%s\n' "$(style_text "$BOLD" "$(txt config)")"
  printf '  %-12s %s\n' "$(txt cfg_profile)" "$( [ "$PROFILE" = "quick" ] && printf '%s' "$(txt quick)" || printf '%s' "$(txt stability)" ) (${RUNS} run$( [ "$RUNS" -eq 1 ] && printf '' || printf 's'))"
  printf '  %-12s %s\n' "$(txt cfg_domains)" "$( [ "$DOMAINS_CHOICE" = "custom" ] && printf 'custom (%s)' "$(join_csv "${SELECTED_DOMAINS[@]}")" || printf '%s' "$DOMAINS_CHOICE" )"
  printf '  %-12s %s\n' "$(txt cfg_providers)" "$PROVIDERS_CHOICE"
  printf '  %-12s %s\n' "$(txt cfg_modes)" "$modes_csv"
  printf '  %-12s %s\n' "$(txt cfg_terminal)" "${TERMINAL_WIDTH} cols, $( [ "$USE_COLOR" = true ] && printf '%s' "$(txt color)" || printf '%s' "$(txt plain)" )"
}

run_preflight() {
  local issues=()
  local target_count=0
  local mode

  require_command awk || issues+=("awk is required")
  require_command sort || issues+=("sort is required")
  require_command od || issues+=("od is required")
  require_command dd || issues+=("dd is required")
  if mode_selected "dns4" || mode_selected "dns6" || mode_selected "dot"; then
    require_command timeout || issues+=("timeout is required for strict socket timeouts")
  fi

  if mode_selected "doh"; then
    require_command curl || issues+=("curl is required for DoH mode")
  fi

  if mode_selected "dot"; then
    require_command openssl || issues+=("openssl is required for DoT mode")
  fi

  if mode_selected "dns6" && [ "$IPV6_STACK_AVAILABLE" != true ]; then
    issues+=("IPv6 transport was selected, but this host cannot reach an IPv6 resolver")
  fi

  [ "${#TARGET_KEYS[@]}" -gt 0 ] || issues+=("no targets were built for the selected provider pool and modes")

  if [ "${#issues[@]}" -gt 0 ]; then
    printf '\n'
    printf '%s\n' "$(style_text "$RED" "$(txt preflight_failed)")"
    printf '%s\n' "$(txt preflight_cannot_run)"
    local issue
    for issue in "${issues[@]}"; do
      printf '  - %s\n' "$issue"
    done
    exit 1
  fi

  printf '\n'
  printf '%s\n' "$(style_text "$BOLD" "$(txt preflight)")"
  printf '  %-12s %s\n' "timer" "$TIMER_SOURCE"
  printf '  %-12s %s\n' "ipv6" "$( [ "$IPV6_STACK_AVAILABLE" = true ] && printf '%s' "$(txt available)" || printf '%s' "$(txt unavailable)" )"
  printf '  %-12s %s\n' "curl" "$( require_command curl && printf 'yes' || printf 'no' )"
  printf '  %-12s %s\n' "openssl" "$( require_command openssl && printf 'yes' || printf 'no' )"
  printf '  %-12s %s\n' "timeout" "$( require_command timeout && printf 'yes' || printf 'no' )"

  for mode in "${SELECTED_MODES[@]}"; do
    target_count=0
    local key
    for key in "${TARGET_KEYS[@]}"; do
      [ "${TARGET_MODE[$key]}" = "$mode" ] || continue
      target_count=$((target_count + 1))
    done
    printf '  %-12s %s target(s)\n' "$(mode_label "$mode")" "$target_count"
  done
}

record_success() {
  local key=$1
  local latency=$2

  RESULT_SUCCESS[$key]=$(( ${RESULT_SUCCESS[$key]:-0} + 1 ))
  RESULT_TOTAL[$key]=$(( ${RESULT_TOTAL[$key]:-0} + 1 ))

  if [ -n "${RESULT_SAMPLES[$key]:-}" ]; then
    RESULT_SAMPLES[$key]+=" $latency"
  else
    RESULT_SAMPLES[$key]="$latency"
  fi
}

record_failure() {
  local key=$1
  RESULT_FAIL[$key]=$(( ${RESULT_FAIL[$key]:-0} + 1 ))
  RESULT_TOTAL[$key]=$(( ${RESULT_TOTAL[$key]:-0} + 1 ))
}

quarantine_target() {
  local key=$1
  local reason=$2
  RESULT_QUARANTINED[$key]=1
  RESULT_QUARANTINE_REASON[$key]=$reason
}

resolve_dns_udp() {
  local server_ip=$1
  local domain=$2
  local start_ms
  local end_ms
  local response_hex=""

  require_command timeout || return 1
  build_query_for_domain "$domain"

  if ! exec {fd}<>"/dev/udp/${server_ip}/53" 2>/dev/null; then
    return 1
  fi

  start_ms=$(now_ms)
  if ! printf '%b' "${QUERY_ESCAPED[$domain]}" >&"$fd" 2>/dev/null; then
    exec {fd}>&-
    exec {fd}<&-
    return 1
  fi

  response_hex=$(timeout "$DNS_TIMEOUT" dd bs=2 count=1 status=none <&"$fd" | od -An -tx1 | tr -d ' \n')
  end_ms=$(now_ms)
  exec {fd}>&-
  exec {fd}<&-

  if [ "$response_hex" = "${QUERY_TXID[$domain]}" ] && [ -n "$response_hex" ]; then
    printf '%s\n' "$((end_ms - start_ms))"
    return 0
  fi

  return 1
}

resolve_doh() {
  local url=$1
  local connect_ip=$2
  local domain=$3
  local host
  local metrics=""
  local resolve_arg=()
  local http_code=0
  local size_download=0
  local time_total=0

  host=$(url_host "$url")
  build_query_for_domain "$domain"

  if [ -n "$connect_ip" ]; then
    if is_ipv6_literal "$connect_ip"; then
      resolve_arg=(--resolve "${host}:443:[${connect_ip}]")
    else
      resolve_arg=(--resolve "${host}:443:${connect_ip}")
    fi
  fi

  metrics=$(printf '%b' "${QUERY_ESCAPED[$domain]}" | curl -sS --max-time "$DOH_TIMEOUT" \
    "${resolve_arg[@]}" \
    -o /dev/null \
    -w '%{http_code}|%{size_download}|%{time_total}' \
    -H 'Content-Type: application/dns-message' \
    -H 'Accept: application/dns-message' \
    --data-binary @- \
    "$url" 2>/dev/null || true)

  IFS='|' read -r http_code size_download time_total <<<"$metrics"

  if [[ "$http_code" =~ ^2[0-9][0-9]$ ]] && [ "${size_download:-0}" -gt 0 ]; then
    seconds_to_ms "${time_total:-0}"
    return 0
  fi

  return 1
}

resolve_dot() {
  local connect_ip=$1
  local servername=$2
  local domain=$3
  local connect_target
  local prefix_escaped
  local header_hex=""
  local start_ms
  local end_ms

  require_command timeout || return 1
  build_query_for_domain "$domain"
  prefix_escaped=$(length_prefix_escaped "${QUERY_LENGTH[$domain]}")

  connect_target="${connect_ip}:853"
  if is_ipv6_literal "$connect_ip"; then
    connect_target="[${connect_ip}]:853"
  fi

  start_ms=$(now_ms)
  exec {fd}< <(
    timeout "$DOT_TIMEOUT" bash -c '
      printf "%b" "$1$2" | openssl s_client -connect "$3" -servername "$4" -quiet 2>/dev/null
    ' _ "$prefix_escaped" "${QUERY_ESCAPED[$domain]}" "$connect_target" "$servername" 2>/dev/null
  )
  header_hex=$(timeout "$DOT_TIMEOUT" dd bs=4 count=1 status=none <&"$fd" | od -An -tx1 | tr -d ' \n')
  exec {fd}<&-
  end_ms=$(now_ms)

  if [ "${#header_hex}" -ge 8 ] && [ "${header_hex:4:4}" = "${QUERY_TXID[$domain]}" ]; then
    printf '%s\n' "$((end_ms - start_ms))"
    return 0
  fi

  return 1
}

run_single_query() {
  local key=$1
  local domain=$2
  local mode=${TARGET_MODE[$key]}

  case "$mode" in
    dns4|dns6)
      resolve_dns_udp "${TARGET_CONNECT_IP[$key]}" "$domain"
      ;;
    doh)
      resolve_doh "${TARGET_URL[$key]}" "${TARGET_CONNECT_IP[$key]}" "$domain"
      ;;
    dot)
      resolve_dot "${TARGET_CONNECT_IP[$key]}" "${TARGET_HOST[$key]}" "$domain"
      ;;
    *)
      return 1
      ;;
  esac
}

avg_from_samples() {
  local samples=$1
  local sum=0
  local count=0
  local value

  for value in $samples; do
    sum=$((sum + value))
    count=$((count + 1))
  done

  if [ "$count" -le 0 ]; then
    printf '0\n'
    return 0
  fi

  printf '%s\n' "$(( (sum + count / 2) / count ))"
}

compute_stats() {
  local key=$1
  local samples=${RESULT_SAMPLES[$key]:-}
  local success=${RESULT_SUCCESS[$key]:-0}
  local total=${RESULT_TOTAL[$key]:-0}
  local -a sorted_samples=()
  local sorted
  local count=0
  local mid_left=0
  local mid_right=0
  local median=0
  local p90=0
  local avg=0
  local success_rate_x10=0
  local p90_index=0

  if [ -n "$samples" ]; then
    mapfile -t sorted_samples < <(printf '%s\n' $samples | sort -n)
    count=${#sorted_samples[@]}
  fi

  if [ "$count" -gt 0 ]; then
    avg=$(avg_from_samples "$samples")
    mid_left=$(( (count - 1) / 2 ))
    mid_right=$(( count / 2 ))
    median=$(( (sorted_samples[$mid_left] + sorted_samples[$mid_right] + 1) / 2 ))
    p90_index=$(( (count * 9 + 9) / 10 - 1 ))
    [ "$p90_index" -lt 0 ] && p90_index=0
    p90=${sorted_samples[$p90_index]}
  fi

  success_rate_x10=$(calc_percent_x10 "$success" "$total")
  printf '%s|%s|%s|%s|%s|%s\n' "$median" "$avg" "$p90" "$success" "$total" "$success_rate_x10"
}

render_run_line() {
  local key=$1
  local status=$2
  local ok_count=$3
  local total_count=$4
  local avg_ms=$5
  local extra=$6

  local tag
  tag=$(status_tag "$status")

  if [ "$COMPACT_OUTPUT" = true ]; then
    printf '%s %-6s %-22s ok %2d/%-2d avg %4sms %s\n' \
      "$tag" \
      "$(mode_transport_label "$key")" \
      "${TARGET_NAME[$key]}" \
      "$ok_count" \
      "$total_count" \
      "$avg_ms" \
      "$extra"
  else
    printf '%s %-7s %-28s %-7s ok %2d/%-2d avg %4sms %s\n' \
      "$tag" \
      "$(mode_transport_label "$key")" \
      "${TARGET_NAME[$key]}" \
      "$( [ "${TARGET_PUBLIC[$key]}" = "yes" ] && printf 'public' || printf 'system' )" \
      "$ok_count" \
      "$total_count" \
      "$avg_ms" \
      "$extra"
  fi
}

test_target() {
  local key=$1
  local successes_this_run=0
  local failures_this_run=0
  local first_domain_consumed=0
  local total_domains=${#SELECTED_DOMAINS[@]}
  local latency=""
  local average_this_run=0
  local domain
  local index
  local run_samples=""

  if [ "${RESULT_QUARANTINED[$key]:-0}" -eq 1 ]; then
    return 0
  fi

  if [ "${RESULT_PROBED[$key]:-0}" -eq 0 ]; then
    domain=${SELECTED_DOMAINS[0]}
    latency=$(run_single_query "$key" "$domain" 2>/dev/null || true)
    if [[ "$latency" =~ ^[0-9]+$ ]]; then
      record_success "$key" "$latency"
      successes_this_run=$((successes_this_run + 1))
      first_domain_consumed=1
      run_samples="$latency"
    else
      latency=$(run_single_query "$key" "$domain" 2>/dev/null || true)
      if [[ "$latency" =~ ^[0-9]+$ ]]; then
        record_success "$key" "$latency"
        successes_this_run=$((successes_this_run + 1))
        first_domain_consumed=1
        run_samples="$latency"
      else
        record_failure "$key"
        failures_this_run=1
        quarantine_target "$key" "$(txt quarantine_reason)"
        RESULT_PROBED[$key]=1
        render_run_line "$key" "QUAR" "$successes_this_run" "1" "0" "$(txt quarantine_reason)"
        return 0
      fi
    fi
    RESULT_PROBED[$key]=1
  fi

  for ((index = first_domain_consumed; index < total_domains; index++)); do
    domain=${SELECTED_DOMAINS[$index]}
    latency=$(run_single_query "$key" "$domain" 2>/dev/null || true)
    if [[ "$latency" =~ ^[0-9]+$ ]]; then
      record_success "$key" "$latency"
      successes_this_run=$((successes_this_run + 1))
      if [ -n "$run_samples" ]; then
        run_samples+=" $latency"
      else
        run_samples="$latency"
      fi
    else
      record_failure "$key"
      failures_this_run=$((failures_this_run + 1))
    fi
  done

  if [ "$successes_this_run" -gt 0 ]; then
    average_this_run=$(avg_from_samples "$run_samples")
  fi

  if [ "$failures_this_run" -gt 0 ]; then
    render_run_line "$key" "DOWN" "$successes_this_run" "$total_domains" "$average_this_run" "$(printf 'failures %d' "$failures_this_run")"
  else
    render_run_line "$key" "OK" "$successes_this_run" "$total_domains" "$average_this_run" ""
  fi
}

render_recommendation_reason() {
  local mode=$1
  local rank=$2
  local median=$3
  local p90=$4
  local success_rate_x10=$5
  local jitter=$((p90 - median))

  if [ "$rank" -eq 1 ]; then
    case "$mode" in
      doh|dot)
        printf '%s\n' "best encrypted balance"
        ;;
      *)
        printf '%s\n' "fastest stable"
        ;;
    esac
    return 0
  fi

  if [ "$jitter" -le 10 ]; then
    printf '%s\n' "lowest jitter"
  elif [ "$success_rate_x10" -ge 1000 ]; then
    printf '%s\n' "clean fallback"
  else
    printf '%s\n' "strong fallback"
  fi
}

render_target_setup() {
  local key=$1
  local mode=${TARGET_MODE[$key]}
  local family=${TARGET_FAMILY[$key]}
  local connect_ip=${TARGET_CONNECT_IP[$key]}
  local url=${TARGET_URL[$key]}
  local host=${TARGET_HOST[$key]}

  case "$mode" in
    dns4|dns6)
      printf 'DNS: %s\n' "$connect_ip"
      ;;
    doh)
      if [ -n "$connect_ip" ]; then
        printf 'DoH: %s | connect %s (%s)\n' "$url" "$connect_ip" "$family"
      else
        printf 'DoH: %s\n' "$url"
      fi
      ;;
    dot)
      if [ -n "$connect_ip" ]; then
        printf 'DoT: %s | connect %s (%s)\n' "$host" "$connect_ip" "$family"
      else
        printf 'DoT: %s\n' "$host"
      fi
      ;;
    *)
      printf '%s\n' "$connect_ip"
      ;;
  esac
}

render_mode_top() {
  local mode=$1
  local threshold_x10=1000
  local records=()
  local key
  local stats
  local median
  local avg
  local p90
  local success
  local total
  local success_rate_x10
  local line
  local setup
  local rank=0

  if [ "$PROFILE" = "stability" ]; then
    threshold_x10=950
  fi

  for key in "${TARGET_KEYS[@]}"; do
    [ "${TARGET_MODE[$key]}" = "$mode" ] || continue
    [ "${TARGET_PUBLIC[$key]}" = "yes" ] || continue
    [ "${RESULT_QUARANTINED[$key]:-0}" -eq 0 ] || continue

    stats=$(compute_stats "$key")
    IFS='|' read -r median avg p90 success total success_rate_x10 <<<"$stats"

    [ "$success" -gt 0 ] || continue
    [ "$success_rate_x10" -ge "$threshold_x10" ] || continue

    records+=("$(printf '%010d|%010d|%010d|%s' "$median" "$p90" "$avg" "$key")")
  done

  printf '\n'
  section_heading "$(mode_label "$mode") Top ${TOP_N}"

  if [ "${#records[@]}" -eq 0 ]; then
    printf '  %s\n' "$(txt no_stable_candidates)"
    return 0
  fi

  while IFS='|' read -r median p90 avg key; do
    [ -n "$key" ] || continue
    rank=$((rank + 1))
    if [ "$rank" -gt "$TOP_N" ]; then
      break
    fi

    stats=$(compute_stats "$key")
    IFS='|' read -r median avg p90 success total success_rate_x10 <<<"$stats"
    line=$(render_recommendation_reason "$mode" "$rank" "$median" "$p90" "$success_rate_x10")
    setup=$(render_target_setup "$key")

    printf '  %s %s\n' \
      "$(rank_badge "$rank")" \
      "$(emphasis_text "${TARGET_NAME[$key]}")"

    printf '     %s %sms   %s %sms   %s %sms   %s %s\n' \
      "$(metric_label "median")" \
      "$median" \
      "$(metric_label "p90")" \
      "$p90" \
      "$(metric_label "avg")" \
      "$avg" \
      "$(metric_label "success")" \
      "$(format_percent_x10 "$success_rate_x10")"

    if [ "${TARGET_MODE[$key]}" = "doh" ] || [ "${TARGET_MODE[$key]}" = "dot" ]; then
      printf '     %s %s   %s %s\n' \
        "$(metric_label "family")" \
        "${TARGET_FAMILY[$key]}" \
        "$(metric_label "reason")" \
        "$line"
    else
      printf '     %s %s\n' \
        "$(metric_label "reason")" \
        "$line"
    fi

    printf '     %s %s\n' "$(metric_label "setup")" "$(emphasis_text "$setup")"
  done < <(printf '%s\n' "${records[@]}" | sort)
}

render_system_reference() {
  local printed=0
  local key
  local stats
  local median
  local avg
  local p90
  local success
  local total
  local success_rate_x10

  printf '\n'
  section_heading "$(txt system_reference)"

  for key in "${TARGET_KEYS[@]}"; do
    [ "${TARGET_PUBLIC[$key]}" = "no" ] || continue

    printed=1
    if [ "${RESULT_QUARANTINED[$key]:-0}" -eq 1 ]; then
      printf '  %s %s - %s\n' "$(status_tag "QUAR")" "${TARGET_NAME[$key]}" "${RESULT_QUARANTINE_REASON[$key]}"
      continue
    fi

    stats=$(compute_stats "$key")
    IFS='|' read -r median avg p90 success total success_rate_x10 <<<"$stats"

    if [ "$success" -gt 0 ]; then
      printf '  %s %-26s %s %sms, %s %sms, %s %sms, %s %s\n' \
        "$(status_tag "INFO")" \
        "${TARGET_NAME[$key]} ($(mode_label "${TARGET_MODE[$key]}"))" \
        "$(metric_label "median")" \
        "$median" \
        "$(metric_label "p90")" \
        "$p90" \
        "$(metric_label "avg")" \
        "$avg" \
        "$(metric_label "success")" \
        "$(format_percent_x10 "$success_rate_x10")"
    else
      printf '  %s %-26s no successful responses\n' \
        "$(status_tag "DOWN")" \
        "${TARGET_NAME[$key]} ($(mode_label "${TARGET_MODE[$key]}"))"
    fi
  done

  if [ "$printed" -eq 0 ]; then
    printf '  %s\n' "$(txt no_system_reference)"
  fi
}

render_quarantine_summary() {
  local printed=0
  local key

  printf '\n'
  section_heading "$(txt quarantined_targets)"

  for key in "${TARGET_KEYS[@]}"; do
    [ "${RESULT_QUARANTINED[$key]:-0}" -eq 1 ] || continue
    printed=1
    printf '  %s %-24s %-7s %s\n' \
      "$(status_tag "QUAR")" \
      "$(emphasis_text "${TARGET_NAME[$key]}")" \
      "$(muted_text "$(mode_transport_label "$key")")" \
      "$(muted_text "${RESULT_QUARANTINE_REASON[$key]}")"
  done

  if [ "$printed" -eq 0 ]; then
    printf '  %s\n' "$(txt no_quarantine)"
  fi
}

render_final_report() {
  local mode

  printf '\n'
  printf '%s\n' "================================================================"
  printf '%s\n' "$(style_text "$BOLD" "$(txt final_report)")"
  printf '%s\n' "================================================================"
  printf '%s\n' "$(txt final_hint)"

  for mode in "${SELECTED_MODES[@]}"; do
    render_mode_top "$mode"
  done

  render_system_reference
  render_quarantine_summary
  printf '\n'
}

main() {
  local run

  parse_args "$@"
  detect_terminal

  if probe_ipv6_stack; then
    IPV6_STACK_AVAILABLE=true
  fi
  now_ms >/dev/null

  if [ -z "$PROFILE" ] && [ -z "$DOMAINS_CHOICE" ] && [ -z "$PROVIDERS_CHOICE" ] && [ "${#SELECTED_MODES[@]}" -eq 0 ] && [ -z "$RUNS" ]; then
    run_interactive_setup
  else
    [ -n "$PROFILE" ] || PROFILE="quick"
    [ -n "$DOMAINS_CHOICE" ] || DOMAINS_CHOICE="ru"
    [ -n "$PROVIDERS_CHOICE" ] || PROVIDERS_CHOICE="all"
    [ "${#SELECTED_MODES[@]}" -gt 0 ] || parse_modes "dns4,doh,dot"
  fi

  finalize_profile_and_runs
  [ -n "$LANG_CHOICE" ] || LANG_CHOICE="en"
  validate_choice "$LANG_CHOICE" ru en || die "$(txt lang_error)"
  validate_choice "$PROVIDERS_CHOICE" system ru global all || die "$(txt providers_error)"
  validate_choice "$DOMAINS_CHOICE" ru global all custom || die "$(txt domains_error)"
  select_domains
  build_targets

  print_banner
  print_selection_summary
  run_preflight

  printf '\n'
  printf '%s\n' "$(style_text "$BOLD" "$(txt execution)")"
  for ((run = 1; run <= RUNS; run++)); do
    if [ "$RUNS" -gt 1 ]; then
      printf '\n'
      printf -v run_label "$(txt run_fmt)" "$run" "$RUNS"
      printf '%s\n' "$(style_text "$BLUE" "$run_label")"
    fi

    local key
    for key in "${TARGET_KEYS[@]}"; do
      test_target "$key"
    done
  done

  render_final_report
}

main "$@"
