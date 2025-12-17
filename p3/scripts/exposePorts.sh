# sudo kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0 & sudo kubectl port-forward svc/iot-playground -n dev 1337:1337

sudo kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0 & sudo kubectl port-forward svc/iot-playground -n dev 1337:1337 --address 0.0.0.0
