#!/usr/bin/env bash
# Gera docs/script.sql (script unico da entrega) concatenando os arquivos
# numerados 01..08, na ordem em que devem ser executados.
# Uso: bash docs/build_script.sh
set -euo pipefail
cd "$(dirname "$0")"
out=script.sql
: > "$out"
for f in 0[1-8]_*.sql; do
  cat "$f" >> "$out"
  printf '\n' >> "$out"
done
echo "Gerado docs/$out a partir de: $(ls 0[1-8]_*.sql | tr '\n' ' ')"
