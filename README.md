# MonoLisa NF

*Most* Batteries inlcuded repo to patch MonoLisa with Nerd Fonts glyphs

## Before You Begin

First you will need to install `fontforge`
There are a number of caveats to invoking the `font-patcher` script.
Some of which are explained by [nerd fonts](https://github.com/ryanoasis/nerd-fonts#font-patcher).

Using `patch-monolisa` assumes you have installed fontforge using your system dependency manager.
On ubuntu: `sudo apt-get install fontforge`.

## Downloading MonoLisa

Once you have acquired MonoLisa, follow the link in your email to download it.
Then extract the `.zip` into `MonoLisa/`.

## Patching your font

Once you have downloaded MonoLisa and `fontforge`
you can easily apply the nerd font patches using the `patch-monolisa` script.
The only required argument is the font file extension you want to patch. 
All remaining supplied arguments are passed to the `font-patcher` script.

```bash
./patch-monolisa otf -c -w
```

You can find your patched fonts in the `patched/` directory

If like me you want to place your patched fonts in a standard location on your Unix system you can move them to `~/.local/share/fonts/MonoLisa` with the `update-fonts` script.

## Changing the Batteries

If I haven't committed to this repo in a while it's likely a good idea to run `update-src` to update the fonts, icons and patcher script.

## Special Thanks

- [MonoLisa](https://www.monolisa.dev)
- [Nerd Fonts](https://www.nerdfonts.com)
