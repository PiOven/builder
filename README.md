# Pi Builder

[![Build Status](https://travis-ci.org/PiOven/builder.svg?branch=master)](https://travis-ci.org/PiOven/builder)

A script to automate the headless building of a configured Raspberry Pi

# Quick Start

```bash
make setup
make build
```

When this has run, write the `./dist/cache/os.img` file to an SD card using
[Etcher](http://etcher.io) and put in a Raspberry Pi.

This will take up-to 5 mins to boot-up and you will have a fully-configured
Raspberry Pi. You can use this image across multiple Raspberry Pis to get an
identical setup - **IF USING A STATIC IP ADDRESS, ONCE SETUP YOU WILL NEED 
TO REBOOT THE PI**

# Features

- Use any version of Raspbian that you have the `.img` for
- Secure SSH access with an SSH key or random 32 character password
- Select an existing SSH key or create one during setup
- Secures the Pi by removing the `pi` username
- Image generated is completely atomic and can be flashed to one Pi or a thousand 
- Configure networking - can connect to a WiFi and set a static IP address
- Install Docker to the Pi
- Configure the GPU networking - reduce allocation of video memory if using as a headless server
- Sends an email when the Pi is set up
- Checks for and installs software updates on a daily basis
- Disables WiFi power management - the WiFi is always-on

# Config

> Requires Docker v1.17 or above

The recommended way is to use the NodeJS script to build the `settings.sh`
file for you. This will ask you various questions about how you want your
Pis setup.

```bash
make setup
```

## The settings

Create a file at `./settings.sh` with the following variables defined:

- **PI_WIFI_SSID**: The SSID WiFi
- **PI_WIFI_PASS**: The password for the WiFi
- **PI_HOSTNAME**: The new network hostname prefix (replacing `raspberry`)
- **PI_SSH_KEY**: The filepath to the SSH public key to use for connecting (replacing password)
- **PI_USERNAME**: The new username (replacing `pi`)
- **PI_OS**: The URL to the OS to download
- **PI_MAILGUN_API_KEY**: [Mailgun](http://mailgun.com) API key (optional)
- **PI_MAILGUN_DOMAIN**: [Mailgun](http://mailgun.com) domain (optional)
- **PI_EMAIL_ADDRESS**: Email address to send to (optional)
- **PI_GPU_MEMORY**: The value of the memory split - can be one of `16`, `32`, `64`, `128`, `256` (optional)
- **PI_INSTALL_DOCKER**: Whether to install [Docker](http://docker.com) or not (optional)
- **PI_IP_ADDRESS_RANGE_START**: Will search for a free IP address in this range (optional, but recommended)
- **PI_IP_ADDRESS_RANGE_END**: End of the IP address range (optional, but recommended)

The Pi will be given a static IP (which will be the same as is first assigned
via DHCP) and the hostname will become the `$PI_HOSTNAME` followed by the IP
address (eg, hostname-192-168-10-10).

If the Mailgun parameters are configured, it will send an email with the hostname
and IP address.

If the Docker parameter is set, it will install Docker will the single line command and set
the **PI_USERNAME** as part of the `docker` group. The command it runs is:

    curl -sSL https://get.docker.com | sh

## OS URLs

- [Raspbian Lite](https://downloads.raspberrypi.org/raspbian_lite/images)
- [Raspbian](https://downloads.raspberrypi.org/raspbian/images)

> Lite images are smaller (typically around 1.7GB rather than 4.7GB) and have no 
> desktop attached so are better suited to being used as a server. These images
> are what was envisaged when this project was created, however using the full
> images should work fine.

# Run

Once you have got your settings, hit `make build`. This will create
a new Pi image you can flash to a memory card (suggest [Etcher](http://etcher.io)).

When you power-up the Pi, which will take between 30 seconds and 5 minutes 
(the longest part is installing Docker), you will eventually be able to connect 
to the Pi with the credentials you provided. If you configured the email, it
will send you an email when it's all configured.

> If you set an IP address range, you will probably have to restart the Pi after 
> the first run. This is due to the `/etc/rc.local` file not being able to handle
> restarting services in there (if anyone know's how to do this, please open a PR).
> Before the restart, the Pi will have the IP address initially set by DHCP.

# ToDo

- [ ] Get a web app set up to allow `.img` file to be done remotely
- [ ] Watch for changes in a Git repo to allow automated deployments to the Pi 
- [ ] Reduce Docker image size (ideally to Alpine)
- [x] Get working on other operating systems (currently only tested on Fedora)
- [x] Cronjob to do updates
- [x] Get `make setup` to prompt for the setup
- [x] Specify an IP address range
- [x] Set a Message Of The Day
- [x] Set static IP for eth0/wlan0 (depending on which is connected)
- [x] Send an email telling of the IP address of the Pi
- [x] Get `localhost` working (comment out the `::1    localhost ip6-localhost ip6-loopback` line) in `/etc/hosts`
- [x] Option to install Docker on first boot
- [x] Allow configuration of the GPU memory split

# Troubleshooting

## `mount: could not find any device /dev/loop#Bad address` during `make build`

This appears to be an intermittent error. Run it again and it should work ok.
