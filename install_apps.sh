#!/bin/bash

name=$(cat /tmp/user_name)
inst=$(cat /tmp/inst)

apps_path="/tmp/apps.csv"

# Scarica elenco delle apps
curl https://raw.githubusercontent.com/max-matty\
/arch_installer/master/apps.csv > $apps_path

if [ "$inst" != "VM" ]; then
  dialog --title "Benvenuto!" \
    --msgbox "Script di installazione pacchetti aggiuntivi e dotfiles!" \
    10 60
fi

# Array con elenco tipologia di apps da cui scegliere cosa installare
apps=("essential" "Essentials" on
      "network" "Network" on
      "tools" "Nice tools to have (highly recommended)" on
      "media" "Multimedia apps" on
      "tmux" "Tmux" on
      "notifier" "Notification tools" on
      "git" "Git & git tools" on
      "i3" "i3 wm" on
      "zsh" "The Z-Shell (zsh)" on
      "neovim" "Neovim" on
      "urxvt" "URxvt" on
      "chromium" "Chromium (browser)" on
      "pandoc" "Pandoc" on
      "js" "JavaScript tooling" on
      "zathura" "Zathura (pdf viewer)" on)

dialog --checklist \
"Scegli quali categorie di applicazioni installare. \n\n\
Selezionare l'opzione tramnite SPAZIO, confermare con INVIO." \
0 0 0 \
"${apps[@]}" 2> app_choices
choices=$(cat app_choices) && rm app_choices

# Create a regex to only select the packages we want
selection="^$(echo "$choices" | sed -e 's/ /,|^/g'),"
lines=$(grep -E "$selection" "$apps_path")
count=$(echo "$lines" | wc -l)
packages=$(echo "$lines" | awk -F, {'print $2'})

echo "$selection" "$lines" "$count" >> "/tmp/packages"

pacman -Syu --noconfirm

rm -f /tmp/aur_queue

if [ "$inst" != "VM" ]; then
  dialog --title "Perfetto!" --msgbox \
    "Verrà installato tutto quanto è stato selezionato.\n\n\
    Ci vorrà qualche minuto.\n\n " \
    13 60
fi

c=0
echo "$packages" | while read -r line; do
    c=$(( "$c" + 1 ))

    dialog --title "Installazione Arch Linux" --infobox \
    "Download ed installazione programma $c di $count: $line..." \
    8 70

    ((pacman --noconfirm --needed -S "$line" > /tmp/arch_install 2>&1) \
    || echo "$line" >> /tmp/aur_queue) \
    || echo "$line" >> /tmp/arch_install_failed

    # pacchetto 'zsh' imposta come shell di default
    if [ "$line" = "zsh" ]; then
        chsh -s "$(which zsh)" "$name"
    fi

    # pacchetto 'networkmanager'
    if [ "$line" = "networkmanager" ]; then
        systemctl enable NetworkManager.service
    fi

    # pacchetto 'openssh'
    if [ "$line" = "openssh" ]; then
      systemctl enable sshd.service
      # Permette di eseguire applicazioni grafiche
      # tramite il Server 'X' della macchina host
      if [ "$inst" = "VM" ]; then
        echo "X11Forwarding yes" >>/etc/ssh/sshd_config
      fi
    fi
done

# elimina tutta la cache
paccache -qf -rk 0

echo "%wheel ALL=(ALL) ALL" >>/etc/sudoers

# Imposta layout della tastiera per ambiente 'X'
{
  echo 'Section "InputClass"'
  echo '        Identifier "system-keyboard"'
  echo '        MatchIsKeyboard "on"'
  echo '        Option "XkbLayout" "it"'
  echo 'EndSection'
} >>/etc/X11/xorg.conf.d/00-keyboard.conf

# Scrive la variabili per il successivo script 'install_user.sh'
echo "$inst" > /tmp/inst

# Scarica lo script 'install_user.sh'
curl https://raw.githubusercontent.com/max-matty\
/arch_installer/master/install_user.sh > /tmp/install_user.sh;

# Cambia utente ed esegue lo script finale
sudo -u "$name" sh /tmp/install_user.sh
