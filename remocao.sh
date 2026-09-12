#!/bin/bash
# VetFlow - Remocao dos Recursos Azure (Sprint 3 - ACR + ACI)
# Deletar o Resource Group remove tudo criado pelo criacao.sh: ACR, imagens e ACI.

GRUPO=vetflow
RG=rg-$GRUPO

echo "============================================="
echo " Removendo Resource Group: $RG"
echo " TODOS os recursos serão deletados (ACR, ACI)!"
echo "============================================="

read -p "Tem certeza? (s/N): " CONFIRM
if [[ "$CONFIRM" != "s" && "$CONFIRM" != "S" ]]; then
  echo "Operação cancelada."
  exit 0
fi

az group delete --name "$RG" --yes --no-wait

echo ""
echo "Remoção iniciada em background."
echo "Verifique no portal Azure: https://portal.azure.com"
echo ""
echo "Para confirmar que foi deletado:"
echo "  az group show --name $RG"
