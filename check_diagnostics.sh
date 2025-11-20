#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
nix develop . "${@}" --command cmake -B .build -S .
FIFO_IN=$(mktemp -u)
FIFO_OUT=$(mktemp -u)
mkfifo "$FIFO_IN"
mkfifo "$FIFO_OUT"
CLANGD_PID=""
DIAGNOSTICS_TIMEOUT=5
trap 'rm -f $FIFO_IN $FIFO_OUT; [[ -n $CLANGD_PID ]] && kill $CLANGD_PID 2>/dev/null || true' EXIT
MAIN_CPP="file://$SCRIPT_DIR/main.cpp"
rpc_request() {
    local json="$1"
    local length=$((${#json} + 1))
    printf "Content-Length: %s\r\n\r\n%s\n" "$length" "$json"
}
json_escape() {
    local input="$1"
    local output=""
    local i char
    for ((i=0; i<${#input}; i++)); do
        char="${input:$i:1}"
        case "$char" in
            '"')   output+='\"' ;;
            '\')   output+='\\' ;;
            $'\b') output+='\b' ;;
            $'\f') output+='\f' ;;
            $'\n') output+='\n' ;;
            $'\r') output+='\r' ;;
            $'\t') output+='\t' ;;
            *)     output+="$char" ;;
        esac
    done
    echo "$output"
}
nix develop . "${@}" --command bash -c "clangd < '$FIFO_IN' > '$FIFO_OUT' 2>&1" &
CLANGD_PID=$!
echo "Started clangd (${CLANGD_PID})"
sleep 0.5
exec 3>"$FIFO_IN"
exec 4<"$FIFO_OUT"
rpc_request '{"jsonrpc":"2.0","id":0,"method":"initialize","params":{"processId":null,"rootUri":"file://'"$SCRIPT_DIR"'","capabilities":{"textDocument":{"diagnostic":{}}}}}' >&3
rpc_request '{"jsonrpc":"2.0","method":"initialized","params":{}}' >&3
MAIN_CPP_TEXT=$(json_escape "$(cat main.cpp)")
rpc_request '{"jsonrpc":"2.0","method":"textDocument/didOpen","params":{"textDocument":{"uri":"'"$MAIN_CPP"'","languageId":"c++","version":0,"text":"'"$MAIN_CPP_TEXT"'"}}}' >&3
rpc_request '{"jsonrpc":"2.0","id":1,"method":"textDocument/documentHighlight","params":{"textDocument":{"uri":"'"$MAIN_CPP"'"},"position":{"line":0,"character":0}}}' >&3
echo "Waiting for diagnostics (timeout: ${DIAGNOSTICS_TIMEOUT}s)..."
DIAGNOSTICS_FOUND=""
ALL_OUTPUT=""
SECONDS=0
while IFS= read -r -t "$DIAGNOSTICS_TIMEOUT" line <&4; do
    ALL_OUTPUT+="$line"$'\n'
    if [[ "$line" =~ \"diagnostics\":\[\] ]]; then
        break
    fi
    if [[ "$line" =~ \"diagnostics\":\[.+\] ]]; then
        DIAGNOSTICS_FOUND="yes"
        break
    fi
    if [[ $SECONDS -ge $DIAGNOSTICS_TIMEOUT ]]; then
      TIMEOUT_EXCEEDED="yes"
      break
    fi
done
exec 3>&-
exec 4<&-
kill "$CLANGD_PID" 2>/dev/null || true
wait "$CLANGD_PID" 2>/dev/null || true
echo "$ALL_OUTPUT"
if [[ -n "$DIAGNOSTICS_FOUND" ]]; then
    echo "Found unexpected diagnostics in main.cpp" && exit 1
elif [[ -n "$TIMEOUT_EXCEEDED" ]]; then
    echo "Timeout exceeded" && exit 1
else
    echo "Success, no diagnostics found" && exit 0
fi
