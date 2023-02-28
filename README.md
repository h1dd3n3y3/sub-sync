# sub_sync
A simple bash script for adjusting subtitle file timing, making changes permament, while providing graphical progress of the work being done.
## Usage
```
bash sub_sync.sh [OPTION] <subtitle-file> <time-offset-in-sec>
```
Where OPTION: `-s, --silent: Suppress graphical progress.`  
`-s` or `--silent` is useful to systems that are limited in resources, like VMs, SSH connections, low RAM, etc.
