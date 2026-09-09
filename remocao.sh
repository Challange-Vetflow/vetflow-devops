#!/bin/bash
# =============================================================
# VetFlow – Remoção dos Recursos Azure (Sprint 3 – ACR + ACI)
# Challenge FIAP 2026 – DevOps Tools & Cloud Computing
# =============================================================
# Deletar o Resource Group remove automaticamente TUDO que foi
# criado pelo criacao.sh: ACR, imagens, ACI (app + banco),
# Storage Account e o File Share (volume nomeado).

GRUPO=vetflow
RG=rg-$GRUPO

echo "============================================="
echo " Removendo Resource Group: $RG"
echo " TODOS os recursos serão deletados (ACR, ACI, Storage)!"
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
