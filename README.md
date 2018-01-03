# Carton
Carton is an advanced web toolchain for experimentation, and small projects. Carton exists as a contrast to [DairyBox](https://github.com/mikekasprzak/dairybox), for use with similar tools (Buble (ES6), ESLint, SVGO, GNU Make, etc). Unlike DairyBox, carton doesn't use a VM, and doesn't lend itself for use with PHP. It's designed for generating static minimized output, in a style that Mike likes. :wink:

To use Carton, you need:

* A Unix Environment (preferrably Ubuntu, a derivative of Ubuntu, or Ubuntu on Linux for Windows)

Instructions will assume an Ubuntu-esc environment.

## How to use Carton

Checkout Carton to a directory in your source tree. Alternatively, you can add it as a submodule.

```bash
git submodule add https://github.com/mikekasprzak/carton
```

Under `carton/template`, you'll find a `Makefile`. Copy it to a folder where you want to be able to build, and edit it accordingly.

Then simply browse to that folder and execute make.

```bash
cd myproj
make
```
