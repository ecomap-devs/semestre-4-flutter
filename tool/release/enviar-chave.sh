#!/usr/bin/env bash
# Envia a chave de assinatura do app para o ambiente `release` do GitHub, sem mostrar nada
# dela na tela. O `gh secret set` lê o valor da entrada padrão e o cifra antes de enviar.
#
# Como usar, em Git Bash, com o `gh` autenticado e permissão de administrador no repositório,
# na máquina que tem android/key.properties e o keystore:
#
#   bash tool/release/enviar-chave.sh
#
# Veja "A chave de assinatura" em RELEASES.md.
set -euo pipefail

cd "$(dirname "$0")/../.."
REPO=ecomap-devs/semestre-4-flutter

if [ ! -f android/key.properties ]; then
  echo "Falta android/key.properties: só quem tem a chave original pode enviá-la." >&2
  exit 1
fi

arquivo=$(sed -n 's/^storeFile=//p' android/key.properties | tr -d '\r')
case "$arquivo" in
  "" | /* | *:* | *..*)
    echo "O storeFile do key.properties precisa ser um caminho relativo a android/." >&2
    exit 1
    ;;
esac
if [ ! -f "android/$arquivo" ]; then
  echo "O keystore não está em android/$arquivo." >&2
  exit 1
fi

base64 -w0 "android/$arquivo" | gh secret set ANDROID_KEYSTORE_BASE64 --env release -R "$REPO"
base64 -w0 android/key.properties | gh secret set ANDROID_KEY_PROPERTIES_BASE64 --env release -R "$REPO"

echo "Pronto. Secrets no ambiente release:"
gh secret list --env release -R "$REPO" --json name,updatedAt --template '{{range .}}{{.name}} {{.updatedAt}}{{"\n"}}{{end}}'
