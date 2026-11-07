#!/usr/bin/env bash
set -euo pipefail

scenario="${1:-}"
if [[ ! "$scenario" =~ ^[1-4]$ ]]; then
  printf 'Uso: sudo bash cenarios.sh {1|2|3|4}\n' >&2
  exit 2
fi
if (( EUID != 0 )); then
  printf 'Execute com sudo.\n' >&2
  exit 2
fi

fail() { printf 'A checagem inicial não está pronta. Mostre a saída da checagem ao professor.\n' >&2; exit 1; }

systemctl is-active --quiet apache2 || fail
systemctl is-active --quiet ssh || fail
ufw status | grep -q '^Status: active$' || fail
ufw status verbose | grep -q 'Default: deny (incoming)' || fail
ufw status | grep -Eq '^22/tcp[[:space:]]+ALLOW IN' || fail
ufw status | grep -Eq '^80/tcp[[:space:]]+ALLOW IN' || fail

rule_number() {
  local port="$1"
  ufw status numbered | awk -v p="$port" '$0 ~ "^[[] *[0-9]+[]][[:space:]]+" p "/tcp[[:space:]]+ALLOW IN" && $0 !~ /[(]v6[)]/ {match($0,/^\[[[:space:]]*[0-9]+\]/); n=substr($0,RSTART,RLENGTH); gsub(/[^0-9]/,"",n); print n; exit}'
}

case "$scenario" in
  1) systemctl stop apache2 ;;
  2) number="$(rule_number 80)"; [[ -n "$number" ]] || fail; ufw --force delete "$number" >/dev/null ;;
  3) systemctl stop ssh ;;
  4) number="$(rule_number 22)"; [[ -n "$number" ]] || fail; ufw --force delete "$number" >/dev/null ;;
esac

printf 'Teste %s preparado. Registre os sintomas e investigue antes de corrigir.\n' "$scenario"
