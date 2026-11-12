export QUDS_RECOVERY_BASE=/home/agent/.codex/skills/remote-skills/office-recovery-0905ba96fd2d
export FLUTTER_ROOT="$QUDS_RECOVERY_BASE/flutter-3.44"
export PUB_CACHE="$QUDS_RECOVERY_BASE/pub-cache"
export PATH="$FLUTTER_ROOT/bin:$QUDS_RECOVERY_BASE/native/clang/bin:$PATH"
export LD_LIBRARY_PATH="$QUDS_RECOVERY_BASE/native/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export TMPDIR=/workspace/scratch/07eb2580faa9/runtime/tmp-source
export XDG_CACHE_HOME=/workspace/scratch/07eb2580faa9/runtime/cache-source
export XDG_DATA_HOME=/workspace/scratch/07eb2580faa9/runtime/data-source
export CI=true
export FLUTTER_SUPPRESS_ANALYTICS=true
export DART_SUPPRESS_ANALYTICS=true
export PYTHONDONTWRITEBYTECODE=1
mkdir -p "$TMPDIR" "$XDG_CACHE_HOME" "$XDG_DATA_HOME"
