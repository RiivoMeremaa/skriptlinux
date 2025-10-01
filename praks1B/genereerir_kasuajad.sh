#!/bin/bash
# genereeri_kasutajad.sh
# Lisab kasutajad süsteemi ja määrab neile paroolid, mis logitakse faili.
# Kasutus: sudo ./genereeri_kasutajad.sh kasutajate_fail

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Palun käivita rootina: sudo $0 kasutajate_fail"
  exit 1
fi

if [ "$#" -ne 1 ]; then
  echo "Kasutus: $0 kasutajate_fail"
  exit 2
fi

KASUTAJAD_FAIL="$1"
LOGIFAIL="loodud_kasutajad_paroolidega"

if [ ! -f "$KASUTAJAD_FAIL" ]; then
  echo "Viga: fail '$KASUTAJAD_FAIL' puudub."
  exit 3
fi

# Kontrolli ja paigalda pwgen kui vaja
if ! command -v pwgen &>/dev/null; then
  echo "'pwgen' puudub, paigaldan..."
  apt-get update && apt-get install -y pwgen
fi

# Varunda vana logifail, kui see olemas
if [ -f "$LOGIFAIL" ]; then
  BACKUP="${LOGIFAIL}.bak.$(date +%s)"
  cp -a "$LOGIFAIL" "$BACKUP"
  echo "Varundasin vana logi: $BACKUP"
fi

# Tühjenda logifail
: > "$LOGIFAIL"

# Loome kasutajad ja määrame paroolid
while IFS= read -r kasutaja || [ -n "$kasutaja" ]; do
  kasutaja="$(echo "$kasutaja" | tr -d '\r' | xargs)"  # puhasta CR ja tühikud
  [ -z "$kasutaja" ] && continue

  echo "Töötlen kasutajat: $kasutaja"

  if ! id "$kasutaja" &>/dev/null; then
    echo "  Kasutajat puudub, loon..."
    useradd -m -s /bin/bash "$kasutaja"
  else
    echo "  Kasutaja juba olemas."
  fi

  # Genereeri parool - 8 täheline, ainult väikesed ja suured tähed
  PAROOL=$(pwgen -A 8 1)

  # Sea parool
  echo "${kasutaja}:${PAROOL}" | chpasswd

  # Logi kasutaja ja parool
  echo "${kasutaja}:${PAROOL}" >> "$LOGIFAIL"
done < "$KASUTAJAD_FAIL"

echo "Kõik kasutajad töödeldud. Logifail: $LOGIFAIL"
echo "Paroolid on salvestatud failis, kaitse see tundlike andmetena!"
