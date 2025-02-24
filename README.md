# ionutnechita-assist-nix-darwin-config

Nix Darwin Config

To update and rebuild your system use this commands:

$ nix flake update --commit-lock-file

.#your-username - change with your real user

$ darwin-rebuild switch --flake .#your-username

Example:
$ darwin-rebuild switch --flake .#assist
