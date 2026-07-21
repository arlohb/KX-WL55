
# Components

- `eprom_reader`
- Custom Ghidra with support for HD6303 CPU from [depili's Ghidra PR #6314](https://github.com/NationalSecurityAgency/ghidra/pull/6314)
- `f9dasm` for disassembly
- `onerom` CLI

# Using `eprom_reader`

Wire accordingly.

```bash
cd eprom_reader

make uploadserial
```

# Building Ghidra

```bash
cd ghidra-hd6303

# Create and enter venv, replace with your shell specific script
python -m venv .venv
source .venv/bin/activate # or activate.fish etc

# Install dependencies
gradle -I gradle/support/fetchDependencies.gradle

# Build
gradle buildGhidra
```

The final `.zip` is in `build/dist`, unzip that and run `ghidraRun`.

# Using `f9dasm`

```bash
# Build
cd f9dasm
make
cd ..

# Run
./f9dasm/f9dasm -6301 data/DataU1.bin > data/DataU1.asm
```
# Assembling with `dasm`

See https://dasm-assembler.github.io/

# Using `onerom`

```bash
# Build onerom CLI, only required first time
./onerom/build-onerom.sh

# Flashing, can use sudo or setup udev rules
sudo ./onerom/onerom program --config-file onerom/U2.json
```

