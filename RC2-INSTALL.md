# RealmOps v0.2.0 RC2 installation

## Safe upgrade

Keep the existing repository until RC2 passes compile and in-game validation.

```bash
cd /home/cura/azerothcore/modules/mod-realm-ops
git tag archive/v0.1.6-before-rc2
git switch -c develop/v0.2.0-rc2
```

Replace the repository contents with this RC2 snapshot, while preserving `.git`.

## Preflight

```bash
cd /home/cura/azerothcore/modules/mod-realm-ops
./tools/realmops-check
```

## Configure and build

Because source files were added, re-run CMake before compiling.

```bash
cd /home/cura/azerothcore
cmake -S . -B build \
  -DCMAKE_INSTALL_PREFIX=/home/cura/server \
  -DMODULES=static
cmake --build build --target modules -j1 2>&1 | tee /tmp/realmops-rc2-build.log
```

After a successful modules build:

```bash
cmake --build build --target worldserver -j1
cmake --install build
```

## Smoke tests

```text
.realmops version
.realmops instance search nexus
.realmops instance audit 576
.realmops quest search wrath
.realmops quest info 13003
.realmops quest audit 13003
```

The exact map and quest IDs may be replaced by IDs available on your realm.
