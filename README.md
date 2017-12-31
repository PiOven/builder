# Pi Builder

A script to automate building of a configured Raspberry Pi

# Config

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

The Pi will be given a static IP (which will be the same as is first assigned
via DHCP) and the hostname will become the `$PI_HOSTNAME` followed by the IP
address (eg, hostname-192-168-10-10).

If the Mailgun parameters are configured, it will send an email with the hostname
and IP address.

If the Docker parameter is set, it will install Docker will the single line command and set
the **PI_USERNAME** as part of the `docker` group. The command it runs is:

    curl -sSL https://get.docker.com | sh

## OS URLs

- [Raspbian](https://downloads.raspberrypi.org/raspbian/images)
- [Raspbian Lite](https://downloads.raspberrypi.org/raspbian_lite/images)

# Run

Once you have got your settings, hit `sudo make build`. This will create
a new Pi image you can flash to a memory card (suggest
[Etcher](http://etcher.io))

# ToDo

- [ ] Get a web app set up to allow `.img` file to be done remotely
- [ ] Get `make setup` to prompt for the setup
- [ ] Get working on other operating systems (currently only tested on Fedora)
- [ ] Configure DDNS
- [ ] Specify an IP address range
- [x] Set a Message Of The Day
- [x] Set static IP for eth0/wlan0 (depending on which is connected)
- [x] Send an email telling of the IP address of the Pi
- [x] Get `localhost` working (comment out the `::1    localhost ip6-localhost ip6-loopback` line) in `/etc/hosts`
- [x] Option to install Docker on first boot
- [x] Allow configuration of the GPU memory split
