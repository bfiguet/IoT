IoT
• 

• Le pot a ete recree ou perdu après un déploiement Argo CD qui a mis à jour le pod (passage de v1 → v2).
Kubernetes crée un nouveau pod pour appliquer le changement (nouvelle image v2). L’ancien pod a été supprimé.
kubectl port-forward était attaché à l’ancien pod → perdu / non existant. donc il faut relancer la comande
