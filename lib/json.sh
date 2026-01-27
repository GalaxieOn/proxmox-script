#!/usr/bin/env bash
set -euo pipefail

json_init() {
  local json_file
  json_file="$(mktemp /tmp/proxmox-script.XXXXXX.json)"
  python3 - <<'PY' "$json_file"
import json, sys
path = sys.argv[1]
with open(path, 'w', encoding='utf-8') as f:
    json.dump({}, f)
PY
  echo "$json_file"
}

json_set() {
  local json_file="$1" key="$2" value="$3"
  python3 - <<'PY' "$json_file" "$key" "$value"
import json, sys
path, key, value = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

data[key] = value
with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
PY
}

json_set_bool() {
  local json_file="$1" key="$2" value="$3"
  python3 - <<'PY' "$json_file" "$key" "$value"
import json, sys
path, key, value = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

data[key] = value.lower() in ('true', '1', 'yes')
with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
PY
}

json_get() {
  local json_file="$1" key="$2"
  python3 - <<'PY' "$json_file" "$key"
import json, sys
path, key = sys.argv[1], sys.argv[2]
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
print(data.get(key, ''))
PY
}

json_pretty() {
  local json_file="$1"
  python3 - <<'PY' "$json_file"
import json, sys
path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
print(json.dumps(data, indent=2, ensure_ascii=False))
PY
}
