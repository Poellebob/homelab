# Homelab

NixOS + Colmena. Services, packages, and endpoints in `flake.nix`;
networking in `hosts/<node>/networking.nix`.

| Node | Nik |
| --- | --- |
| Odin | Den der beb brugt på htx |
| Thor | Min gamle slave |

## Deploy

```sh
nix flake check --no-build
nix develop
colmena build --on thor
colmena apply --on thor
```

## Minecraft

```sh
sudo systemctl start minecraft-server-bedwars
journalctl -u minecraft-server-bedwars -f
mc-attach bedwars
mc-console bedwars "say Hello"
```

## Secrets

From `secrets/`:

```sh
agenix -e thor/cloudflared-credentials.age -i /path/to/identity
```
