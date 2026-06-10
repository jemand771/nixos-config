# nixos-config

Nixing all over these OSes

## nixos-anywhere

replace `HOST` with target hostname. nom will be broken but better than nothing ig.
should take about 10 minutes

```sh
nixos-anywhere -f .#HOST --target-host root@HOST --build-on remote &| nom
```
