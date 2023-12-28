#!/bin/bash

# Mai eseguire 'pacman -Sy' sul proprio sistema!
pacman -Sy dialog --noconfirm

timedatectl set-ntp true

# Messaggio di benvenuto tipo 'yesno' - vedi `man dialog`
dialog --defaultno --title "Istruzioni e conferma installazione" --yesno \
	"\nArch Installer personale (thanks to Matthieu Cneude). \n\
E' consigliabile leggere README.md prima di procedere. \n\
La presente installazione cancellerà completamente il disco! \n\n\
Si conferma di procedere?" 15 60 || exit

dialog --no-cancel --inputbox "Inserire il nome del computer." \
	10 60 2>comp

comp=$(cat comp) && rm comp

# Verifica UEFI/BIOS
uefi=0
ls /sys/firmware/efi/efivars 2>/dev/null && uefi=1

# Verifica installazione HD/VM
dialog --title "Destinazione installazione" --no-cancel --radiolist \
	"\nDove vuoi installare il sistema operativo? \n\
Seleziona tramite SPAZIO, conferma con ENTER.\n\n" \
	12 50 3 "HD" "Hard Disk" off "VM" "Macchina Virtuale" on 2>inst

inst=$(cat inst) && rm inst

# Scelta del disco
if [ "$inst" = "VM" ]; then
	hd="/dev/vda"
else
	mapfile -t devices_list < <(lsblk -d | awk '{print "/dev/" $1 " " $4 " on"}' |
		grep -E 'sd|hd|vd|nvme|mmcblk')

	dialog --title "Scelta del disco" --no-cancel --radiolist \
		"\nSu quale disco vuoi installare Archlinux? \n\
      Selezione con SPAZIO e conferma con INVIO. \n\n\
        AVVERTIMENTO: Il contenuto del disco verrà distrutto!" \
		15 60 4 "${devices_list[@]}" 2>hd

	hd=$(cat hd) && rm hd
fi

# Dimensione swap
if [ "$inst" = "VM" ]; then
	size="1"
else
	default_size="8"

	dialog --no-cancel --inputbox \
		"Saranno create TRE partizioni: Boot, Root and Swap \n\
  La partizione di Boot sarà di 512M \n\
  La partizione Root occuperà lo spazio residuale del disco \n\n\
  Inserisci la dimensione (in GB) della partizione di Swap. \n\n\
  Se non si inserisce nulla, sarò creata un partizione di ${default_size}GB. \n" \
		20 60 2>swap_size

	size=$(cat swap_size) && rm swap_size

	[[ $size =~ ^[0-9]+$ ]] || size=$default_size
fi

if [ "$inst" = "VM" ]; then
	hderaser="3"
else
	dialog --no-cancel \
		--title "!!! CANCELLAZIONE TOTALE !!!" \
		--menu "Scegli come il disco deve essere cancellato ($hd)" \
		15 60 4 \
		1 "Usa 'dd' (pulisce l'intero disco)" \
		2 "Use 'schred' (più lento ma sicuro)" \
		3 "Nessuna cancellazione - il disco è vuoto" 2>eraser

	hderaser=$(cat eraser)
	rm eraser
fi

# Funzione per la cancellazione del disco.
# NON ESEGUIRE LA FUNZIONE SUL SISTEMA IN USO!!!
function eraseDisk() {
	case $1 in
	1) dd if=/dev/zero of="$hd" status=progress 2>&1 |
		dialog \
			--title "Formattazione $hd..." \
			--progressbox --stdout 20 60 ;;
	2) shred -v "$hd" |
		dialog \
			--title "Formattazione $hd..." \
			--progressbox --stdout 20 60 ;;
	3) ;;
	esac
}

eraseDisk "$hderaser"

boot_partition_type=1
[[ "$uefi" == 0 ]] && boot_partition_type=4

# Creazione delle partizioni tramite 'fdisk':
#g - crea una 'partition table' vuota tipo GPT
#n - crea nuova partizione
#p - partizione primaria
#e - partizione estesa
#w - scrive 'partition table' su disco ed esce

partprobe "$hd"

fdisk "$hd" <<EOF
g
n


+512M
t
$boot_partition_type
n


+${size}G
n



w
EOF

partprobe "$hd"

# Aggiunge suffisso 'p' in caso di NVMe controller chip
echo "$hd" | grep -E 'nvme' &>/dev/null && hd="${hd}p"

# Formattazione delle partizioni
mkswap "${hd}2"
swapon "${hd}2"
mkfs.ext4 "${hd}3"
mount "${hd}3" /mnt

if [ "$uefi" = 1 ]; then
	mkfs.fat -F32 "${hd}1"
	mkdir -p /mnt/boot/efi
	mount "${hd}1" /mnt/boot/efi
fi

# Installazione Arch Linux
pacstrap /mnt base base-devel linux linux-firmware
genfstab -U /mnt >>/mnt/etc/fstab

# prepara /etc/fstab per poter montare la directory condivisa con host
if [ "$inst" = "VM" ]; then
	{
		echo " "
		echo "# cartella condivisa con host"
		echo "/shared    /home/max/shared    virtiofs    defaults    0 0"
	} >>/mnt/etc/fstab
fi

# Scrive i valori delle variabili da riportare al successivo script
echo "$inst" >/mnt/inst
mkdir /mnt/root/.screenlayout
echo "$inst" >/mnt/root/.screenlayout/var_inst
echo "$uefi" >/mnt/var_uefi
echo "$hd" >/mnt/var_hd
echo "$comp" >/mnt/comp

# Scarica il successivo script 'install_chroot.sh'
curl https://raw.githubusercontent.com/max-matty/arch_installer/master/install_chroot.sh >/mnt/install_chroot.sh

arch-chroot /mnt bash install_chroot.sh

rm /mnt/inst
rm /mnt/var_uefi
rm /mnt/var_hd
rm /mnt/install_chroot.sh
rm /mnt/comp

[ "$inst" = "VM" ] && reboot

dialog --title "Scelta se riavviare?" --yesno \
	"\nTutto completato! Il sistema è stato installato! \n\
Per alcune configurazioni Post Installazione si consiglia di \n\
leggere le istruzioni contenute in ~/dotfiles/README.md file\n\n\
Riavviare il computer?" 20 60

response=$?

case $response in
0) reboot ;;
1) clear ;;
esac
