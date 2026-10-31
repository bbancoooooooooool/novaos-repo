# NovaOS package repository

Binary packages for NovaOS, published automatically from the main project by
`.github/workflows/publish-repo.yml`. Do not edit this repository by hand.

On a NovaOS system installed from an older ISO, run once:

```bash
curl -fsSL https://raw.githubusercontent.com/bbancoooooooooool/novaos-repo/main/setup.sh | sudo sh
```

After that, updates arrive with `sudo pacman -Syu`.
