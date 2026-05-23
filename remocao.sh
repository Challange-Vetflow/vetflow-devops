# =============================================================
# VetFlow – Remoção dos Recursos Azure
# Challenge FIAP 2026 – DevOps Tools & Cloud Computing
# =============================================================

GRUPO=vetflow
RG=rg-$GRUPO

echo "============================================="
echo " Removendo Resource Group: $RG"
echo " TODOS os recursos serão deletados!"
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
