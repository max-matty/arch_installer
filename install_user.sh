#!/bin/bash

inst=$(cat /tmp/inst)

mkdir -p "/home/$(whoami)/Documents"
mkdir -p "/home/$(whoami)/Downloads"
mkdir "/home/$(whoami)/.screenlayout"
echo "$inst" >"/home/$(whoami)/.screenlayout/var_inst"

# Funzione per installare qualsiasi pacchetto da AUR.
# Riceve il nome del pacchetto come argomento.
aur_install() {
	curl -O "https://aur.archlinux.org/cgit/aur.git/snapshot/$1.tar.gz" &&
		tar -xvf "$1.tar.gz" &&
		cd "$1" &&
		makepkg --noconfirm -si &&
		cd - &&
		rm -rf "$1" "$1.tar.gz"
}

aur_check() {
	qm=$(pacman -Qm | awk '{print $1}')
	for arg in "$@"; do
		if [[ "$qm" != *"$arg"* ]]; then
			yay --noconfirm -S "$arg" &>>/tmp/aur_install ||
				aur_install "$arg" &>>/tmp/aur_install
		fi
	done
}

cd /tmp || exit
dialog --infobox "Installazione Yay, AUR helper..." 10 60
aur_check yay

count=$(wc -l </tmp/aur_queue)
c=0

while read -r line; do
	c=$(("$c" + 1))
	dialog --infobox \
		"AUR - Scarico ed installo il programma $c di $count: $line..." \
		10 60
	aur_check "$line"
done </tmp/aur_queue

# Pulisce la cache di Yay
yay --noconfirm -Sc --aur

DOTFILES="/home/$(whoami)/dotfiles"
if [ ! -d "$DOTFILES" ]; then
	# Scarica il repository con i dotfiles
	git clone https://github.com/max-matty/dotfiles.git \
		"$DOTFILES" >/dev/null
fi

source "$DOTFILES/zsh/.zshenv"
cd "$DOTFILES" && bash install.sh

# i3-wm: modifica tasto $mod in caso di VM
if [ "$inst" = "VM" ]; then
	cd "$DOTFILES/i3/" && sed -i 's/Mod4/Mod1/' config
fi

# crea la directory condivisa in guest
if [ "$inst" = "VM" ]; then
	mkdir "/home/$(whoami)/shared"
fi
