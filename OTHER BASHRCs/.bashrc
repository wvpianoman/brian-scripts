source /usr/share/defaults/etc/profile


# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi

unset rc

###---------- ALIASES ----------###
# source ~/.bashrc

# =====| my tools
alias htos="sudo ~/.config/MY-TOOLS/assets/scripts/Zysnc-Options/ZYSNC-HOME-TO-SERVER.sh"
alias mount="sudo ~/.config/MY-TOOLS/assets/scripts/Mounting-Options/MOUNT-ALL.sh"
alias mse="sudo ~/scripts/MYTOOLS/mse.sh"
alias stoh="sudo ~/.config/MY-TOOLS/assets/scripts/Zysnc-Options/ZYSNC-SERVER-TO-HOME.sh"
alias umount="sudo ~/.config/MY-TOOLS/assets/scripts/Mounting-Options/UMOUNT-ALL.sh"

# =====| alias pics="sxiv -t $HOME/Pictures/CUSTOM-WALLPAPERS/"
alias wp="sxiv -t $HOME/Pictures/Solus Wallpapers/"

# =====| navigate files and directories
alias ..="cd .."
alias cl="clear && rc"
alias copy="rsync -P"
alias la="lsd -a"
alias ll="lsd -l"
alias ls="lsd"
alias lsla="lsd -la"

# =====| update
alias grub="sudo grub2-mkconfig -o /boot/grub2/grub.cfg"
alias rc="source ~/.bashrc"
alias trim="sudo fstrim -av"
alias update="sudo eopkg up"

# =====| file access
alias bconf="vim ~/.config/bash/.bashrc"
alias cp="cp -riv"
alias htos='sudo ~/.config/MY-TOOLS/assets/scripts/Zysnc-Options/ZYSNC-HOME-TO-SERVER.sh'
alias mkdir="mkdir -vp"
alias mount='sudo ~/.config/MY-TOOLS/assets/scripts/Mounting-Options/MOUNT-ALL.sh'
alias mse='sudo ~/scripts/MYTOOLS/MAKE-SCRIPTS-EXECUTABLE.sh'
alias mv="mv -iv"
alias mynix='sudo ~/.config/MY-TOOLS/assets/scripts/COMMAN-NIX-COMMAND-SCRIPT/MyNixOS-commands.sh'
alias stoh='sudo ~/.config/MY-TOOLS/assets/scripts/Zysnc-Options/ZYSNC-SERVER-TO-HOME.sh'
alias trimgen='sudo ~/.config/MY-TOOLS/assets/scripts/GENERATION-TRIMMER/TrimmGenerations.sh'
alias umount='sudo ~/.config/MY-TOOLS/assets/scripts/Mounting-Options/UMOUNT-ALL.sh'
alias zconf="vim ~/.config/zsh/.zshrc"
alias search='eopkg li -l | grep "Name:" | awk "{print \$2, \$3, \$4}" | fzf'

# =====| Custom from tolga
alias cong="sysctl net.ipv4.teopkg scp_congestion_control"
alias io="cat /sys/block/sda/queue/scheduler"
alias rc="source ~/.bashrc"
alias sys="echo && io && echo && cong && echo"

# =====| Custom from brian
alias search='eopkg li -l | grep "Name:" | awk "{print \$2, \$3, \$4}" | fzf'
alias gitup='sudo ~/.config/MY-TOOLS/assets/scripts/GITHUB/tolga.sh'

# =====| Nix-Shell work around (crazy)
alias nix="nix-shell && exec $SHELL"

export PATH="/home/brian/.nix-profile/bin:$PATH"
. /home/brian/.nix-profile/etc/profile.d/nix.sh

PS1="\[[1;32m\]┌[\[[1;32m\]\u\[[1;34m\]@\h\[[1;m\]] \[[1;m\]::\[[1;36m\] \W \[[1;m\]::
\[[1;m\]└\[[1;33m\]➤ 🖐️👀 👉\[[0;m\] "

echo "" && fortune && echo ""

# Set locales
# export LC_NUMERIC="en_US.UTF-8"
# export LC_TIME="en_US.UTF-8"
export LOCALE_ARCHIVE="$(nix-env --installed --no-name --out-path --query glibc-locales)/lib/locale/locale-archive"

eval "$(direnv hook bash)"

fastfetch
