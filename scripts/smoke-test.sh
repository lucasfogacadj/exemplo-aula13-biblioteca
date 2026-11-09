#!/usr/bin/env bash
set -euo pipefail

base_url="${BASE_URL:-http://127.0.0.1:5220}"
db_file="${TMPDIR:-/tmp}/biblioteca-smoke-$RANDOM.db"
log_file="${TMPDIR:-/tmp}/biblioteca-smoke-$RANDOM.log"
ConnectionStrings__Biblioteca="Data Source=$db_file" dotnet run --no-build --configuration Release --urls "$base_url" >"$log_file" 2>&1 &
app_pid=$!
cleanup() { kill "$app_pid" 2>/dev/null || true; wait "$app_pid" 2>/dev/null || true; rm -f "$db_file" "$db_file-shm" "$db_file-wal" "$log_file"; }
trap cleanup EXIT

ready=0
for _ in $(seq 1 40); do
  if curl --silent --fail "$base_url/api/livros" >/dev/null; then ready=1; break; fi
  sleep 1
done
if [[ "$ready" != 1 ]]; then cat "$log_file"; echo "API did not become ready" >&2; exit 1; fi

initial="$(curl --silent --show-error "$base_url/api/livros")"
[[ "$initial" == "[]" ]] || { echo "Expected an empty database, got: $initial" >&2; exit 1; }

created="$(curl --silent --show-error -X POST "$base_url/api/livros" -H 'Content-Type: application/json' -d '{"titulo":"O Hobbit","autor":"J. R. R. Tolkien","anoPublicacao":1937}' -w '\n%{http_code}')"
status="${created##*$'\n'}"
payload="${created%$'\n'*}"
[[ "$status" == 201 ]] || { echo "Expected POST 201, got $status: $payload" >&2; exit 1; }
id="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["id"])' <<< "$payload")"

get_status="$(curl --silent --output /dev/null --write-out '%{http_code}' "$base_url/api/livros/$id")"
[[ "$get_status" == 200 ]] || { echo "Expected GET by ID 200, got $get_status" >&2; exit 1; }

put_status="$(curl --silent --output /dev/null --write-out '%{http_code}' -X PUT "$base_url/api/livros/$id" -H 'Content-Type: application/json' -d '{"titulo":"O Hobbit — edição revisada","autor":"J. R. R. Tolkien","anoPublicacao":1937}')"
[[ "$put_status" == 200 ]] || { echo "Expected PUT 200, got $put_status" >&2; exit 1; }

restart_id="$(curl --silent --show-error -X POST "$base_url/api/livros" -H 'Content-Type: application/json' -d '{"titulo":"Dom Casmurro","autor":"Machado de Assis","anoPublicacao":1899}' | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])')"
kill "$app_pid" 2>/dev/null || true
wait "$app_pid" 2>/dev/null || true
ConnectionStrings__Biblioteca="Data Source=$db_file" dotnet run --no-build --configuration Release --urls "$base_url" >"$log_file" 2>&1 &
app_pid=$!
ready=0
for _ in $(seq 1 40); do
  if curl --silent --fail "$base_url/api/livros" >/dev/null; then ready=1; break; fi
  sleep 1
done
[[ "$ready" == 1 ]] || { cat "$log_file"; echo "API did not restart" >&2; exit 1; }
persisted_status="$(curl --silent --output /dev/null --write-out '%{http_code}' "$base_url/api/livros/$restart_id")"
[[ "$persisted_status" == 200 ]] || { echo "Expected persisted record after restart (200), got $persisted_status" >&2; exit 1; }

delete_status="$(curl --silent --output /dev/null --write-out '%{http_code}' -X DELETE "$base_url/api/livros/$id")"
[[ "$delete_status" == 204 ]] || { echo "Expected DELETE 204, got $delete_status" >&2; exit 1; }
missing_status="$(curl --silent --output /dev/null --write-out '%{http_code}' "$base_url/api/livros/$id")"
[[ "$missing_status" == 404 ]] || { echo "Expected missing book 404, got $missing_status" >&2; exit 1; }

printf 'Smoke test passed: POST 201, GET 200, PUT 200, DELETE 204, missing 404, SQLite persistence after restart.\n'
