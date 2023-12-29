# Installazione Arch

## Preparare la Macchina Virtuale con `virt-manager`

### File ISO da utilizzare

Arch Linux mensile, ad esempio:

`archlinux-2023.12.01-x86_64.iso`

### Caratteristiche della VM

> RAM 1024MB
> Core 1
> HD 10GM

**NB** Flaggare la configurazione dell'hardware prima di avviare l'installazione.

### Cartella condivisa

Nel componente _Memory_, flaggare _enable shared memory_.

Aggiungere hardware tipo _Filesystem_ e compilare come segue:

> Driver: `virtiofs`  
> Source path: `/home/max/shared`  
> Target path: `/shared`

Avviare l'installazione.

## Avvio installazione da ISO

```shell
# loadkeys it
# curl -LO https://raw.githubusercontent.com/max-matty/arch_installer/master/install_sys.sh
# sh install_sys.sh
```

## Primo avvio in caso di Macchina Virtuale

La scelta comporta il salvataggio della variabile `~/.screenlayout/var_inst` che viene verificata all'avvio della macchina per impostare, in ambiente 'X', la configurazione schermo a 800x600 che può poi essere adattata allo schermo sia del portatile Asus che del display Samsung tramite la combinazione di tasti `$mod+a`.

## Inizializzazione Neovim e Tmux

Al primo avvio è necessario inizializzare i _plugins_ di Neovim e Tmux:

### Neovim

All'avvio Neovim aggiorna in automatico i plugins.

E' necessario verificare la presenza dei seguenti tramite `:Mason`:

- `bash-language-server`
- `efm`
- `lua-language-server`
- `luacheck`
- `markdownlint`
- `markdownlint-cli2`
- `prettierd`
- `shellcheck`
- `shfmt`
- `stylua`
- `zk`

Potrà essere utile caricare il plugin che permette di installare automaticamente alcuni server _LSP_ tramite il seguente comando:

`:Lazy load mason-lspconfig.nvim`

### Tmux

Per Tmux è necessario avviando una sessione (`$mod-Return`) e digitare `PREFIX+I`.

Con `PREFIX` che è la combinazione tasti `Ctrl+Space`.

## Utilizzo di Spice Viewer

E' consigliabile fare partire la macchina dal visualizzatore _Spice_ per una migliore gestione del cambio di Workspace in `i3-wm` nella macchina _Host_.

E' già configurata in `i3-wm` (lato _Host_) la combinazione tasti `$mod+Control+[0-9]` per avviare 10 VM.

Per collegare la singola VM è sufficiente impostare da `virt-manager` la porta _Spice_ all'interno del componente _Display Spice_, esempio: 5900 per la combinazione `$mod+Control+0` fino a 5009 per la combinazione `$mod+Control+9`.

## Utilizzo di ssh

Per fare partire la macchina in background digitare:

`$ virsh -c qemu:///system start <VM-name>`

Successivamente possiamo fare l'accesso da terminale:

`$ ssh max@<ip-guest>`

Per trovare l'indirizzo IP sulla rete digitare:

`$ arp -n`

Sono stati configurati sulla macchina _Host_ gli _alias_ per fare partire le 10 macchine virtuali e per stopparle come segue: `startVM-00` e `stopVM-00`.

### Files Multimediali

Quando ci colleghiamo tramite `ssh` è impostata di default la possibilità di eseguire applicazioni grafiche utilizzando il Server X della macchina _Host_.

## Github

Al primo utilizzo ci verrà chiesto di inserire nome ed indirizzo email.
