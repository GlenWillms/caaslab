
1. Complete standard lab up until the point you have a vk8s cluster and download your kubeconfig file.
2. Launch web shell for Jumpbox and Grafana machine
3. Clone caaslab github repo
```bash
cd ~
git clone https://github.com/GlenWillms/caaslab.git
```
4. Set NAMESPACE environment variable
```
export NAMESPACE=keen-duck or your own namespace value
```
5. Upload kubeconfig file to jumpbox using fileserver and set KUBECONFIG environment variable to point to kubeconfig file.
```bash
export KUBECONFIG=/srv/filebrowser/ves_$NAMESPACE\_$NAMESPACE-vk8s.yaml
```
6. Deploy manifests
```bash
cd ~/caaslab
kubectl apply -f vk8s/
```
7. Deploy origin pool as follows

Reference the k8s service mosquitto for your namespace as: mosquitto.namespace
Set the origin server selection to be **local endpoints only**.
![[Pasted image 20241227111702.png]]
8. Deploy the load balancer
![[Pasted image 20241227111739.png]]

![[Pasted image 20241227111758.png]]
![[Pasted image 20241227111820.png]].
9. Deploy grafana instance
```bash
cd ~/caaslab/docker-grafana
docker compose up -d
```
10. Run the stats generation from your web shell
```bash
~/caaslab/systemstats2mqtt.sh
```

11. View your live data from Grafana
 ![[Pasted image 20241227112210.png]]
Click through to view your dashboard:
![[Pasted image 20241227112326.png]]