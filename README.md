# Carton
Carton is an advanced web toolchain for experimentation, and small projects. Carton exists as a contrast to [DairyBox](https://github.com/mikekasprzak/dairybox), for use with similar tools (Buble (ES6), ESLint, SVGO, GNU Make, etc). Unlike DairyBox, carton doesn't use a VM, and doesn't lend itself for use with PHP. It's designed for generating static minimized output, in a style that Mike likes. :wink:

To use Carton, you need:

* A Unix Environment (preferrably Ubuntu, a derivative of Ubuntu, or Ubuntu on Linux for Windows)

Instructions will assume an Ubuntu-esc environment.

## Setting up Carton

Checkout Carton to a directory in your source tree. Alternatively, you can add it as a submodule.

```bash
git submodule add https://github.com/mikekasprzak/carton
```

Next, you'll need to install various packages.

### 1. Install Packages

TODO: List packages you should install

```bash
sudo apt install make

```

### 2. Node Packages

Installing the node packages is simpler. So long as you're running a current version of node, simply browse to the carton directory and do the following:

```bash
cd carton
npm install
```

If you need to upgrade to a newer version of Node JS (and you should if you want the fastest builds), you can find instructions here:

https://github.com/nodesource/distributions#debinstall

## Using Carton

Under `carton/template`, you'll find a `Makefile`. Copy it to a folder where you want to be able to build, and edit it accordingly.

Then simply browse to that folder and execute make.

```bash
cd myproj
make
```
