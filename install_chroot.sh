#!/bin/bash

uefi=$(cat /var_uefi)
hd=$(cat /var_hd)
inst=$(cat /inst)
comp=$(cat /comp)

echo "$comp" >/etc/hostname && rm /comp

pacman --noconfirm -S dialog
pacman --noconfirm -S pacman-contrib
pacman -S --noconfirm grub

if [ "$uefi" = 1 ]; then
	pacman -S --noconfirm efibootmgr
	grub-install --target=x86_64-efi \
		--bootloader-id=GRUB \
		--efi-directory=/boot/efi
else
	grub-install "$hd"
fi

grub-mkconfig -o /boot/grub/grub.cfg

# Imposta hardware clock da system clock
hwclock --systohc
# Imposta il fuso orario
ln -sf /usr/share/zoneinfo/Europe/Rome /etc/localtime

# Imposta la lingua utilizzata
echo "en_US.UTF-8 UTF-8" >>/etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >/etc/locale.conf

# Imposta il layout della tastiera
echo "KEYMAP=it" >>/etc/vconsole.conf

# Funzione di creazione utente ed impostazione password.
# - senza argomenti: chiede nome utente.
# - con argomento: lo utilizza come nome utente.
function config_user() {
	if [ -z "$1" ]; then
		dialog --no-cancel --inputbox "Inserire username." \
			10 60 2>name
	else
		echo "$1" >name
	fi
	dialog --no-cancel --passwordbox "Inserire password." \
		10 60 2>pass1
	dialog --no-cancel --passwordbox "Conferma password." \
		10 60 2>pass2
	while [ "$(cat pass1)" != "$(cat pass2)" ]; do
		dialog --no-cancel --passwordbox \
			"Le password inserite non coincidono." \
			10 60 2>pass1
		dialog --no-cancel --passwordbox \
			"Ripetere l'inserimento." \
			10 60 2>pass2
	done

	name=$(cat name) && rm name
	pass1=$(cat pass1) && rm pass1 pass2

	# Creazione dell'utente se non esiste
	if [[ ! "$(id -u "$name" 2>/dev/null)" ]]; then
		dialog --infobox "Aggiunta utente $name..." 4 50
		useradd -m -g wheel -s /bin/bash "$name"
	fi

	# Aggiunge la password
	echo "$name:$pass1" | chpasswd

	# Aggiungo l'utente al gruppo 'audio'
	if [ "$inst" = "VM" ]; then
		usermod -aG audio "$name"
	fi
}

dialog --title "Password di root" \
	--msgbox "Inserire la password dell'utente root" \
	10 60
config_user root

dialog --title "Aggiunta nuovo utente" \
	--msgbox "Creazione di un nuovo utente del sistema." \
	10 60
config_user

# Scrive valori delle variabili per il prossimo script 'install_apps.sh'
echo "$name" >/tmp/user_name
echo "$inst" >/tmp/inst

# Chiede se installare altre apps e dotfiles.
if [ "$inst" = "VM" ]; then
	curl https://raw.githubusercontent.com/max-matty/arch_installer/master/install_apps.sh >/tmp/install_apps.sh &&
		bash /tmp/install_apps.sh
else
	dialog --title "Continuazione installazione" --yesno \
		"Vuoi installare tutte le tue applicazioni e dotfiles?" \
		10 60 &&
		curl https://raw.githubusercontent.com/max-matty/arch_installer/master/install_apps.sh >/tmp/install_apps.sh &&
		bash /tmp/install_apps.sh
fi
