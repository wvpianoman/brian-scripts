#!/bin/bash
# Personal Fedora folder archiver backup
# Brian F,
# 12/16/2023

# created from script by Tolga Erok. ¯\_(ツ)_/¯

# Define the backup folder path within /etc/nixos
backup_folder="$HOME"
BACKUP_DIR="/backup"

# Create the backup folder structure if it doesn't exist
#mkdir -p "$HOME/backup"

# Define the backup filename without extension
backup_filename=fedora-backup-$(date "+%Y-%m-%d %l-%M%p")

zip -r "$HOME/$BACKUP_DIR/$backup_filename.zip" /home/brian -x "/home/$USER/Downloads/apps/*" -x "/home/$USER/.local/share/Trash/*" -x "/root/.local/share/Trash/*" -x "/home/$USER/Applications/*" -x "/home/$USER/backup/*" -x "/home/$USER/snap/*" -x "/home/$USER/.var/*" -x "/home/$USER/GitHub/*" -x "/home/$USER/.vscode/*" -x"/home/$USER/.cache/*" -x "/home/$USER/.config/Beeper/*"

echo "Backup completed and stored in $BACKUP_DIR/$backup_filename"
