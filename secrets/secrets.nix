let
  goonbox = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPoBp3cGMohQO+JdZyEiK4Ag/14BlmccQEkQeuQs8haA viggokh@goonbox-3000";
  framework13 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAoOyIvsIUwznoj71ZA9lFTixJis1s3ceTjF520uoWU/ viggokh@framework13";

  thor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOnGHIfOjqQDoH9iIc/+6e9ANLJKphkqcl6NORlXpNbR root@nixos";
  odin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIELBcMGJ73RjvZfqGOL3HQ7jGZl3DL4qW38kv1kRtGgy root@nixos";
in
{
  "thor/cloudflared-credentials.age".publicKeys = [
    goonbox
    thor
    framework13
  ];
  "thor/playit-secret.age".publicKeys = [
    goonbox
    thor
    framework13
  ];
  "thor/windrose-env.age".publicKeys = [
    goonbox
    thor
    framework13
  ];
  "odin/playit-secret.age".publicKeys = [
    goonbox
    odin
    framework13
  ];
  "odin/cloudflared-credentials.age".publicKeys = [
    goonbox
    odin
    framework13
  ];
  "odin/windrose-env.age".publicKeys = [
    goonbox
    odin
    framework13
  ];
}
