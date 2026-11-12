#!/usr/bin/env bash
# setup.sh - interactive RustDesk bootstrap. Pinned: 1.2.5. No secrets embedded.
V="1.2.5"; R="rustdesk-${V}-0.x86_64.rpm"
U="https://github.com/rustdesk/rustdesk/releases/download/${V}/${R}"
y(){ echo "[setup] $*"; }
d(){ y "FAIL: $*"; return 1; }
[ -t 0 ] || d "stdin is not a terminal"
command -v dnf >/dev/null || d "needs dnf"
printf 'Server address: '; read -r S
printf 'Key (44 chars): '; read -r K
[ -z "$S" ] && d "no server"
[ -z "$K" ] && d "no key"
curl -fL -o "/tmp/${R}" "$U" || d "download failed"
[ -s "/tmp/${R}" ] || d "empty file"
sudo dnf install -y "/tmp/${R}" || d "install failed"
rpm -q rustdesk || d "rpm missing"
T=$(printf "rendezvous_server = '%s'\nnat_type = 1\n\n[options]\ncustom-rendezvous-server = '%s'\nrelay-server = '%s'\napi-server = 'http://%s:21114'\nkey = '%s'\ndirect-server = 'Y'\nenable-hwcodec = 'Y'\nallow-auto-update = 'N'\nwhitelist = '100.64.0.0/10,192.168.0.0/16'\n" "$S" "$S" "$S" "$S" "$K")
mkdir -p ~/.config/rustdesk
printf '%s\n' "$T" > ~/.config/rustdesk/RustDesk2.toml
sudo mkdir -p /root/.config/rustdesk
printf '%s\n' "$T" | sudo tee /root/.config/rustdesk/RustDesk2.toml >/dev/null
sudo systemctl enable --now rustdesk.service || d "enable failed"
sudo systemctl restart rustdesk.service || d "restart failed"
sleep 2
y "service: $(systemctl is-active rustdesk)"
y "id: $(rustdesk --get-id)"
y "done"
