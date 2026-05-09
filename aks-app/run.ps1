$token = az acr login --name kmicabananica --expose-token --query accessToken -o tsv

docker login kmicabananica.azurecr.io `
  --username 00000000-0000-0000-0000-000000000000 `
  --password $token

docker build -t kmicabananica.azurecr.io/aks-demo:v1 .

docker push kmicabananica.azurecr.io/aks-demo:v1

az aks get-credentials `
  --resource-group rg3-algebra-project `
  --name aro-aks1 `
  --overwrite-existing

kubectl apply -f app-aks.yaml