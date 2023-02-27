# samples

It contains some sample file for testing.

## Run busybox with crictl
```
crictl run busybox-container.json busybox-pod.json
```

## Run nginx with crictl
```
crictl run nginx-container.json nginx-pod.json
```

## Run helloworld with crictl

step 1: pull image

> use ctr to pull image into namespace k8s.io, equals to `crictl pull`

```
# pull image with ctr
sudo ctr -n k8s.io image pull gcr.io/knative-samples/helloworld-go:latest

# check image
sudo crictl images | grep helloworld

```

step 2: run pod and container

- create contaienr in existed/public pod(such as `../samples/pod-sandbox.json`)

    ```
    # check pod status and get pod id
    sudo crictl pods | grep pod-sandbox

    # create helloworld container
    sudo crictl create <pod id>../samples/helloworld-container.json../samples/pod-sandbox.json
    ```

- create container in new specified pod

    ```
    # run pod
    sudo crictl runp ../samples/helloworld-sandbox.json

    # check pod status and get pod id
    sudo crictl pods | grep pod-sandbox

    # create helloworld container
    sudo crictl create <pod id>../samples/helloworld-container.json../samples/helloworld-pod.json
    ```
step 3: start container

```
# get container id
sudo crictl ps -a | grep hellowrold

# start container
sudo crictl start <container id>

# check container status
sudo crictl ps -a | grep helloworld
```

step 4: curl helloworld

```
# get pod ip
sudo crictl inspectp <pod id> 

# get port container listened, the helloworld listens port 8080

# curl container, you should receive message "Hello world!"
curl http://<pod ip>:8080

# check container log in log_path
sudo cat /tmp/helloworld.0.log
```