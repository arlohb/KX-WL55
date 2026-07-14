
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

