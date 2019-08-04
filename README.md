![](https://raw.githubusercontent.com/lwieske/rancher-multimaster-rancheros/master/demo800x600.gif)

Kubernetes Cluster: rancher mgmt plane + 3 master ctrl plane + 3 worker data plane (Docker Machine)

![](https://raw.githubusercontent.com/lwieske/rancher-multimaster-rancheros/master/rancherui1.png)

![](https://raw.githubusercontent.com/lwieske/rancher-multimaster-rancheros/master/rancherui2.png)

![](https://raw.githubusercontent.com/lwieske/rancher-multimaster-rancheros/master/rancherui3.png)

![](https://raw.githubusercontent.com/lwieske/rancher-multimaster-rancheros/master/rancherui4.png)

## docker-machine spin up for 3 masters + 3 workers

### K8S 1.14.3

```console
                            |
                            |
                            |
┌───────────────────────────▼───────────────────────────┐
│                        rancher                        │
└───────────────────────────┬───────────────────────────┘
                            │
       ┌────────────────────┼─────────────────────┐
       │                    │                     │
┌──────▼─────┐       ┌──────▼─────┐        ┌──────▼─────┐
│  master01  │       │  master02  │        │  master03  │
└──────┬─────┘       └──────┬─────┘        └──────┬─────┘
       │                    │                     │
       ├────────────────────┼─────────────────────┤
       │                    │                     │
┌──────▼─────┐       ┌──────▼─────┐        ┌──────▼─────┐
│  worker01  │       │  worker02  │        │  worker03  │
└────────────┘       └────────────┘        └────────────┘
```

```console
... killing and removing existing machines
... machines killed and removed
... creating rancher machine
... rancher machine created
... preparing rancher machine
... ... pulling images
... ... starting rancher
... ... waiting for rancher
... ... login to rancher
... ... logged in as admin/admin
... ... changed to MTMzOGIw
... ... creating APITOKEN
... ... APITOKEN created
... ... configuring server-url
... ... server-url configured
... ... creating CLUSTERID
... ... CLUSTERID created
... ... creating CLUSTERREGISTRATIONTOKEN
... ... CLUSTERREGISTRATIONTOKEN created
... ... creating NODECOMMAND
... ... NODECOMMAND created
... ... creating master01 and starting agent
... ... master01 created and agent started
... ... creating master02 and starting agent
... ... master02 created and agent started
... ... creating master03 and starting agent
... ... master03 created and agent started
... ... creating worker01 and starting agent
... ... worker01 created and agent started
... ... creating worker02 and starting agent
... ... worker02 created and agent started
... ... creating worker03 and starting agent
... ... worker03 created and agent started
... all machines created and agents started
http://192.168.99.254
admin / MTMzOGIw
> 
```