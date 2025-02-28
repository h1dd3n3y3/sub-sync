# sub-sync
A simple bash script for adjusting subtitle file timing, making changes permament, while providing graphical progress of the work being done.
## Usage:
```
bash sub_sync.sh [OPTIONS] <subtitle-file> <seconds-offset>
```
`<subtitle-file>` : The .srt file (path)  
`<seconds-offset>` : A Real Number of seconds offset (even negative or floating point)  

OPTIONS:  
- `-s, --silent: Suppress graphical progress.` Useful when not ran natively, like VMs & SSH connections, where lag is presented in the progress bar.  
- `-h, --help: Show this usage prompt.`
