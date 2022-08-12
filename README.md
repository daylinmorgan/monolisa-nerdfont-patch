# MonoLisa NF

*Most* Batteries inlcuded repo to patch MonoLisa with Nerd Fonts glyphs

tested w/ MonoLisa v1.808

## Before You Begin

First you will need to install `fontforge`
There are a number of caveats to invoking the `font-patcher` script.
Some of which are explained by [nerd fonts](https://github.com/ryanoasis/nerd-fonts#font-patcher).

On Arch:

```bash
sudo pacman -S fontforge
```

You can also download the version for your system from the releases in the fontforge [repo](https://github.com/fontforge/fontforge).

## Downloading MonoLisa

Once you have acquired MonoLisa, follow the link in your email to download it.
Then extract the `.zip` file of the type you've downloaded into `MonoLisa/`.

The expected directory structure is below.
You only need to download the font types you plan to use.

```bash
MonoLisa
├── otf
├── ttf
├── woff
└── woff2
```

## Patching your font

Once you have downloaded MonoLisa and `fontforge`
you can easily apply the nerd font patches with `make`.

To patch all font types use the default `patch` rule.


```bash
make
```

By default the complete (`-c`) flag is passed to the font-patcher script to include all icons/symbols.
You can change this by specifying the `ARGS` at runtime.


```bash
ARGS="-c -w" make patch
```

You can find your patched fonts in the `patched/` directory

If like me you want to place your patched fonts in a standard location on your Unix system you can move them to `~/.local/share/fonts/MonoLisa` with the `bin/update-fonts` script.

Or for simplicity you can copy the fonts and update the cache with:
```bash
make update-fonts
```

You can verify the fonts have been added with `make check`.

## Changing the Batteries

If I haven't committed to this repo in a while it's likely a good idea to run `make update-src` to update the fonts, icons and patcher script from nerd fonts.

## Special Thanks

- [MonoLisa](https://www.monolisa.dev)
- [Nerd Fonts](https://www.nerdfonts.com)
