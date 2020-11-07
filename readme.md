```bash
~/code/zig/os $ zig build-exe main.zig -target i386-freestanding -static -Drelease-small -T linker.ld
~/code/zig/os $ qemu-system-i386 -kernel main
```
