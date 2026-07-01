# dev_env
Stores automation to streamline setting up a dev environment on a linux box

## Deployment

### For Online Hosts

To configure an **online host** to have this dev environment, do the following:

1) Execute:
    - `cd scripts && ./install_online.sh`

### For Offline Hosts

To configure an **offline host** to have this dev environment, do the following:

1) On an online host, package all the necessary dependencies with:
    - `cd scripts && ./package_for_offline.sh`

2) Move everything to the offline host via secure method
3) Configure and install everything with:
    - `cd scripts && ./install_offline.sh`

### Tutorials I Used
[Setup Zsh on Ubuntu (How and Why)](https://dev.to/kanakos01/setup-zsh-on-ubuntu-how-and-why-2kl4)
