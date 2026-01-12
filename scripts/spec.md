# setup-remote-env.sh
I want you to create a script called `setup-remote-env.sh` that will be used by ephemeral hosts when I need to ssh into them.

Requirements:
- This script must be run as current user
- This script is inside a git repo, hosted on github as a public repository under my account. The ephemeral hosts need to run a simple curl that will run the script. Probably pointing to raw? The repository is rodrigomideac/dotfiles.
- Must support debian based distros and arch based distros. you can ask the user what distro is.
- Must install the following packages in this order:
  - zsh
  - oh-my-zsh ( and set zsh as default shell )
  - Neovim
  - cifs-utils
  - smbclient
- Must copy the .zshrc file to the home directory of the user
- Must copy the .config/nvim directory
- Must add the following public ssh keys as authorized keys to the user:
  - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID6QfFvyZwY5lfjR+rTqF5NQIzeMI73NAS0h3oilaDTz
- Now an input from the user must be asked: Are you running on home network?
  - If the answer is yes:
    - ask the user for username and password for the NAS. Store then on ~/.smbcredentials with the following format:
<smbcredentials>
username=USER_NAME_FROM_INPUT.
password=USER_PASSWORD_FROM_INPUT
</smbcredentials>
    - run `smbclient -L //nas.casa -N` to test if it the NAS is reachable
    - create a systemd unit that mounts the cifs defined as below. Use the replace USERHOME with user home. Remember that if it will mount on /home/rodrigo/mnt/data, the unit must be named as home-rodrigo-mnt-data.mount due to systemd filename requirements 
<systemd_unit>
[Unit]
Description=Mount data share from NAS
After=network-online.target
Wants=network-online.target

[Mount]
What=//nas.casa/data
Where=USERHOME/mnt/data
Type=cifs
Options=credentials=USERHOME/.smbcredentials,iocharset=utf8,noperm,gid=1000,uid=1000,_netdev

[Install]
WantedBy=multi-user.target
</systemd_unit>
  - create the another systemd mount unit for the temp_data share:

<systemd_unit>
[Unit]
Description=Mount temp_data share from NAS
After=network-online.target
Wants=network-online.target

[Mount]
What=//nas.casa/temp_data
Where=USERHOME/mnt/temp_data
Type=cifs
Options=credentials=USERHOME/.smbcredentials,iocharset=utf8,noperm,gid=1000,uid=1000,_netdev

[Install]
WantedBy=multi-user.target
</systemd_unit>
  - I want these units to be enabled and started on boot, and they must retry the mount every 15s if it fails (change the systemd unit file accordingly or create a time, or whatever)

Help me plan a implementation for this script. Create a spec_v1.md file that will be handout to another claude code instance

