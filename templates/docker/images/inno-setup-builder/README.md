# Dockerized Inno Setup Compiler (ISCC)

This Dockerfile provisions a headless Windows emulation environment using Wine inside a lightweight Debian Linux container. It automatically downloads, installs, and configures the **Inno Setup
Compiler (ISCC.exe)**, enabling you to build native Windows installers (`.exe`) directly from your Linux-based continuous integration (CI) pipelines or local development environments.

---

## Technical Highlights

* **Multi-Architecture Wine Support**: Configures Debian to support `i386` binaries, allowing both 32-bit and 64-bit Wine dependencies to co-exist cleanly.
* **Headless GUI Installation**: Utilizes `Xvfb` (X Virtual Framebuffer) to trick the native Inno Setup graphical installer into executing a silent, automated setup without a physical display present.
* **Optimized for CI/CD**: Suppresses graphical debugger overheads and disables heavy sub-components (like Gecko and Mono) to keep execution fast and the overall image lightweight.
* **Clean Container Lifecycle**: Automatically kills lingering background Wine server processes (`wineserver -k`) on termination and proxies the compiler exit code back to the host system.

---

## Environment Variable Configuration

The image utilizes specific configuration parameters to optimize Wine for automated scripts:

| Variable           | Configured Value    | Operational Purpose                                                                          |
|:-------------------|:--------------------|:---------------------------------------------------------------------------------------------|
| `DEBIAN_FRONTEND`  | `noninteractive`    | Prevents apt-get from blocking execution loops for user inputs.                              |
| `WINEPREFIX`       | `/wine`             | Establishes an explicit isolation directory for the virtual C: drive configuration.          |
| `WINEARCH`         | `win64`             | Targets a 64-bit virtual Windows workspace architecture.                                     |
| `WINEDLLOVERRIDES` | `"mscoree,mshtml="` | Explicitly disables native pop-up requests to install .NET (Mono) and HTML (Gecko) engines.  |
| `WINEDEBUG`        | `"-all,err+all"`    | Shuts down verbose trace logging, surfacing only critical runtime faults to keep logs clean. |

---

## Usage Reference

### 1. Build the Docker Image

Execute the build command within the directory containing your Dockerfile:

```bash
docker build -t innosetup-compiler .
```

### 2. Compile an Inno Setup Script (`.iss`)

To compile a project, mount your local workspace into the `/app` directory of the container and pass the path of your `.iss` script relative to the mount point as a trailing argument:

```bash
docker run --rm \
  -v "$(pwd)":/app \
  innosetup-compiler \
  myscript.iss
```

_For ARM64 architecture:_
```bash
docker run --rm --platform linux/amd64 -v "$(pwd):/app" myscript.iss
```

### 3. Passing Custom Compiler Flags

Since the container's `ENTRYPOINT` passes arguments directly to `ISCC.exe`, you can seamlessly append standard Inno Setup compilation flags (such as overriding the output directory or setting
passwords):

```bash
docker run --rm \
  -v "$(pwd)":/app \
  innosetup-compiler \
  /O"C:\app\dist" /V"1.2.3" myscript.iss
```

---

## Underlying Execution Mechanics

When the container initializes, the structured `ENTRYPOINT` script executes the following sequence:

1. **Invoke Compiler**: Runs `wine /wine/drive_c/InnoSetup/ISCC.exe "$@"` to pass your files and arguments into the emulation layer.
2. **Capture Exit State**: Captures the exact exit code returned by the compiler execution loop (`EXIT_CODE=$?`).
3. **Resource Cleanup**: Dispatches a termination signal to the underlying runtime infrastructure (`wineserver -k`) to guarantee that no orphaned Windows processes keep the container active.
4. **Proxy Result**: Terminates the container using the original compiler code (`exit $EXIT_CODE`), allowing your CI/CD pipelines to accurately identify build successes or script compilation failures.