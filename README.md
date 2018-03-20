# Pi Builder

A script to automate the headless building of a configured Raspberry Pi

# Features

- Use any version of Raspbian that you have the `.img` for
- Secure SSH access with an SSH key or random 32 character password
- Secures the Pi by removing the `pi` username
- Image generated is completely atomic and can be flashed to one Pi or a thousand 
- Configure networking - can connect to a WiFi and set a static IP address
- Install Docker to the Pi
- Configure the GPU networking - reduce allocation of video memory if using as a headless server
- Sends an email when the Pi is set up
- Checks for and installs software updates on a daily basis
- Disables WiFi power management - the WiFi is always-on

# Config

> Requires NodeJS v4 or above

The recommended way is to use the NodeJS script to build the `./settings.sh`
file for you. This will ask you various questions about how you want your
Pis setup.

```bash
npm install # Only needs to be run once
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

- [Raspbian](https://downloads.raspberrypi.org/raspbian/images)
- [Raspbian Lite](https://downloads.raspberrypi.org/raspbian_lite/images)

# Run

Once you have got your settings, hit `sudo make build`. This will create
a new Pi image you can flash to a memory card (suggest
[Etcher](http://etcher.io)).

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
- [ ] Get working on other operating systems (currently only tested on Fedora)
- [ ] Watch for changes in a Git repo to allow automated deployments to the Pi 
- [x] Cronjob to do updates
- [x] Get `make setup` to prompt for the setup
- [x] Specify an IP address range
- [x] Set a Message Of The Day
- [x] Set static IP for eth0/wlan0 (depending on which is connected)
- [x] Send an email telling of the IP address of the Pi
- [x] Get `localhost` working (comment out the `::1    localhost ip6-localhost ip6-loopback` line) in `/etc/hosts`
- [x] Option to install Docker on first boot
- [x] Allow configuration of the GPU memory split
