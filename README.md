# NixOS clangd failure reproducer

This is a quick'n'dirty test to show that clangd is broken on current nixos-unstable.

## How to use

This is a Nix flake and uses `nix develop` internally, and assumes that flakes and nix-command are both already enabled; it would be trivial to adapt it to run another way, but it's beyond the scope of this very rough demonstration.

Run the test by doing:

```
./check_diagnostics.sh
```

You can pass arguments to the underlying `nix develop` shell. To reproduce the current failure, for example, you can do:

```
# Check that it worked before
./check_diagnostics.sh --override-input nixpkgs github:NixOS/nixpkgs/c4d1151093af5d483d1900d9214a65e68bc21560

# Now check that it is broken afterwards
./check_diagnostics.sh --override-input nixpkgs github:NixOS/nixpkgs/de21549a840be528ef4763dd7dca2006caf9c11f
```
