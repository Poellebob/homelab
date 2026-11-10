# Two-Host Homelab

NixOS configurations for existing servers, managed by Colmena; not an installer.
Imports are local or flake inputs, with no external checkout dependencies.

## Layout And Sources

- `flake.nix` / `flake.lock`: node inventory, one shared package set, locked inputs, and hive. Inventory names set the actual hostnames.
- `modules/server.nix`: shared OS baseline; `modules/admin.nix`: shared admin account, Nix trust, and PAM sudo policy.
- `hosts/{thor,odin}/`: identical layout: `configuration.nix` (hostname and imports), `hardware-configuration.nix`, `networking.nix` (tunnels and credentials), and `users.nix` (host-specific accounts). Service selections are imported per node in `flake.nix`.
- `services/`: service modules imported explicitly per node in `flake.nix`, including `minecraft/base.nix` and selected per-server instances; no automatic discovery or service flake outputs. Custom tmux-managed Forge servers share `minecraft/forge.nix` (`services.forge-servers`); `docker.nix` is imported by the Windrose container module.
- `networking/`: shared Playit/cloudflared modules; each host's `networking.nix` supplies credentials, tunnel ID, and ingress when enabled.
- `keys.nix`: shared admin public keys; `secrets/secrets.nix`: agenix recipient policy.
- Thor source (`homeserver`, formerly `SlaveUndertheTY`): https://github.com/Poellebob/nixos-dotfiles/tree/a03494ec22e085df3fe34bf1a56a68cda96794f9/hosts/homeserver
- Odin source (LAN, formerly `nixos`): https://github.com/SESG-HTX-LAN/server-config/tree/41b3b93840d8da52306a25cb90a384d74f37c992

To add a node, copy one host directory, replace its hardware configuration, and
review its deployment target, bootloader, stateVersion, accounts, networking,
and service selections. Add a node entry in `flake.nix` with its imports and
`deployment.targetHost`, for example `loki = { imports = [ ... ]; deployment.targetHost = "loki"; };`.
All nodes use the same package sources.
Host-specific public keys live in `users.nix`; shared public keys remain in
`keys.nix`. Provision separate tunnel credentials for the new node rather
than copying another node's ciphertext or private host identity.

## Hosts And Pins

| Node / OS Hostname | SSH Target (`admin`) | Networking |
| --- | --- | --- |
| `thor` | `thor` → `thor.poellebob.xyz` over Cloudflare | Existing NetworkManager configuration |
| `odin` | `odin` → `odin.poellebob.xyz` over Cloudflare | NetworkManager and automatic DHCP determination |

`deployment.targetHost` is the bare node name; the deploy machine's `~/.ssh/config`
resolves it to the Cloudflare hostname. Ingress hostnames are third-level names
(`thor.poellebob.xyz`, `odin.poellebob.xyz`) because Universal SSL covers only
`*.poellebob.xyz`; cloudflared ingress matches hostnames only, never paths.
Each host terminates its own tunnel with its own ID and credentials; the tunnel
ID in each `networking.nix` must match the credentials in that host's
`secrets/<host>/cloudflared-credentials.age`. Never share one tunnel or its
credentials between hosts.
Odin's `10.34.144.50` remains the LAN fallback: no static IP or gateway is declared.
Its configuration includes user edits; do not infer static networking from the LAN source.
Preserve working runtime NetworkManager profiles and console access.
Both hosts are `x86_64-linux`; preserve host-specific hardware, disk UUIDs, UEFI systemd-boot,
and `system.stateVersion = "26.05"`. Do not raise stateVersion just to update packages.

Both hosts use the same `nixpkgs` input, Minecraft module, and Minecraft overlay.
Colmena, agenix, and Playit follow the shared nixpkgs input too; there are no
per-host package-set overrides.

Keep `flake.lock` for reproducibility. Run `nix flake update` to update the shared
inputs, then check both systems before deploying. The update applies the same
dependency versions to every node; `system.stateVersion` stays host-specific.

## Access And Bootstrap

Admin SSH is key-only: password, keyboard-interactive, and root SSH are disabled.
`admin` is in `wheel`; sudo uses PAM `sshAgentAuth`, `wheelNeedsPassword = true`, and
NixOS-managed authorized keys, not `NOPASSWD`. This passwordless account needs a matching agent key.
Each host retains its three original admin keys plus the shared key in `keys.nix`.
Thor's original `games` keys remain separate and unchanged; shared admin keys are not added.
**Trusted Nix users are effectively root**; `admin` is trusted even without sudo.
Forwarded agents let root or a compromised target request signatures while connected.
Forward only to trusted hosts; prefer a dedicated deployment key/agent, optionally
`ssh-add -c` with a working local confirmation UI.

Before first deployment, bootstrap both nodes through their existing rebuild workflow
(Odin's source lacked explicit Nix trust for `admin`). Check `ssh-add -l`, preserve existing
keys/groups, and configure a normal `admin` user with your public key, `wheel` membership,
and apply these Nix trust and sudo settings:

```nix
nix.settings.trusted-users = [ "admin" ];
security.pam.sshAgentAuth.enable = true;
security.pam.services.sudo.sshAgentAuth = true;
security.sudo.wheelNeedsPassword = true;
security.sudo.extraConfig = ''
  Defaults:admin noninteractive_auth
'';
```

`noninteractive_auth` lets Colmena's `sudo -n` attempt PAM agent authentication
without prompting. Load the matching admin key into your local SSH agent before deploying.

Remove old `NOPASSWD` rules. Keep existing root access and a console until both targets
pass these tests with verified SSH host fingerprints and fresh sudo timestamps:

```sh
ssh -A admin@<target> 'sudo -k; sudo -n true' # Must succeed.
ssh -a admin@<target> 'sudo -k; sudo -n true' # Must fail without forwarding.
```

Only then activate this flake, which disables root SSH. The hive forwards the agent;
no global SSH configuration is required.

## Verify And Deploy

Enable Nix `nix-command` and `flakes`. Git-backed flakes ignore untracked files.
Stage intended configs, lockfile, and ciphertext (never
private keys or plaintext secrets) before ordinary `nix flake check --no-build`.
To validate the untracked working tree instead, use `nix flake check path:. --no-build`.
Once required files are tracked, use the normal locked input references below.

Route DNS for each tunnel (one-time; or add proxied CNAMEs in the dashboard):

```sh
cloudflared tunnel route dns <thor-tunnel-id> thor.poellebob.xyz
cloudflared tunnel route dns <odin-tunnel-id> odin.poellebob.xyz
```

On the deploy machine, `~/.ssh/config` maps the node names onto the tunnels:

```
Host thor
  HostName thor.poellebob.xyz
  User admin
  ProxyCommand cloudflared access ssh --hostname %h

Host odin
  HostName odin.poellebob.xyz
  User admin
  ProxyCommand cloudflared access ssh --hostname %h
```

The SSH ingress only goes live once a configuration is applied, so the first
apply must use each host's current working route (point `HostName` at the old
address or LAN IP, apply, then switch to the Cloudflare hostname).

```sh
nix flake check --no-build
nix shell --inputs-from . colmena#colmena agenix#default nixpkgs#cloudflared
colmena build --on thor
colmena apply --on thor
# Confirm Thor's reachability and services before proceeding.
colmena build --on odin
colmena apply --on odin
# Optional, after verifying both nodes:
colmena apply --on @homelab
```

`buildOnTarget = true`: `colmena build` contacts nodes and builds remotely but does not
activate. Deployment connects as `admin`, forwards the agent, and escalates via `sudo -n`.
The same hive exposes `nixosConfigurations.thor` and `.odin`; local builds can use
`nix build .#nixosConfigurations.thor.config.system.build.toplevel` (or `odin`).
On the corresponding host, with its checkout, agent, and bootstrap checks satisfied,
activate with `sudo nixos-rebuild switch --flake .#thor` (or `.#odin`).

## Secrets And Backups

Thor's three unchanged ciphertext files are `secrets/thor/{playit-secret,cloudflared-credentials,windrose-env}.age`;
their recipients are unchanged. The host identity `/etc/ssh/ssh_host_ed25519_key` stays
outside the repository. A hostname rename is not key rotation and needs no rekey.
From `secrets/`, using agenix from the shell above so it finds `secrets.nix`:

```sh
agenix -e thor/cloudflared-credentials.age -i /path/to/identity
```

The identity must match an existing recipient. A new host key requires deliberate
ciphertext rekeying with an authorized identity; editing policy alone is insufficient.
Keep private identities and plaintext out of Git. Each host runs its own Playit and
Cloudflare tunnels with its own credentials; never reuse another host's secrets.
See `secrets/odin/README.md` for recipients, encryption, imports, tunnel ID, and ingress.
Back up `/srv/minecraft` on both hosts, plus Thor's `/srv/windrose/gooncave`.
Back up runtime NetworkManager profiles and host identities
independently: a configuration checkout is not a data backup.

## Service Caveats

- Odin Bedwars requires existing runtime jars/data, including `slimeworldmanager-classmodifier-2.2.1.jar`. `extraReload` uses `cp -rn` only on reload, not initial provisioning, and never overwrites files. Thor's custom Forge units also require existing runtime installations.
- Odin opens TCP 21 without configuring an FTP server; review exposure.
- Windrose uses a moving Docker tag, not an immutable digest.
- Thor Playit/cloudflared require existing external account/tunnel mappings. Minecraft voice/resource-pack addresses retain source values; this repository does not create external mappings or DNS.
- `SlaveUndertheTY Windrose` remains a game display label, not the OS hostname.
