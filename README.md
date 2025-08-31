# Cookbook for Synaptics Astra

<p align="center">
    <img
        src="https://www.synaptics.com/sites/default/files/2024-11/sl1680-back.jpg"
        alt="Rpi Logo"
        width="500" />
</p>

This cookbook provides a collection of recipes to help you get started with DeimOS for Synaptics Astra.

## Prerequisites

- [Gaia project Gaia Core](https://github.com/gaiaBuildSystem/gaia);

<p align="center">
    <img
        src="https://github.com/gaiaBuildSystem/.github/raw/main/profile/GaiaBuildSystemLogoDebCircle.png"
        alt="This is a Gaia Project based cookbook"
        width="170" />
</p>

## Build an Image

```bash
./gaia/bitcook --buildPath /home/user/workdir --distro ./cookbook-synaptics/distro-ref-astra-dolphin.json --noCache
```

This will build DeimOS for Synaptics Astra sl1680.

## Supported Boards -> Machines

| Board                      | Gaia Machine Name   |
|----------------------------|---------------------|
| Astra sl1680 Core Module   | sl1680              |
