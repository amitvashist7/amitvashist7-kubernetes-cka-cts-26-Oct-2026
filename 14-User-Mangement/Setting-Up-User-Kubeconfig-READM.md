```
 691  openssl genrsa -out vagrant.pem 2048
  692  openssl  req -new -key vagrant.pem -out vagrant-csr.pem -subj "/CN=vagrant/O=training"
  693  openssl x509 -req -in vagrant-csr.pem -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out vagrant.crt -days 100
  694  kubectl config set-cluster kubernetes --server=https://172.31.0.100:6443 --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs=true  --kubeconfig=vagrant.kubeconfig
  695  cat vagrant.kubeconfig
  696  kubectl config set-credentials vagrant --client-certificate=/root/vagrant.crt  --client-key=/root/vagrant.pem --embed-certs=true --kubeconfig=vagrant.kubeconfig
  697  cat vagrant.kubeconfig
  618  kubectl config set-context vagrant@kubernetes --cluster=kubernetes --user=vagrant  --kubeconfig=vagrant.kubeconfig
  698  kubectl config use-context vagrant@kubernetes   --kubeconfig=vagrant.kubeconfig
  699  kubectl  get pods --kubeconfig=vagrant.kubeconfig

  626  cat vagrant.kubeconfig
  627  cp -rf vagrant.kubeconfig /home/vagrant/.kube/config
  628  chmod 777 /home/vagrant/.kube/config

```
