---
title: etcd
date: 2026-03-19T23:31:51+01:00
draft: false
tags: []
categories:
  - blog
  - k8s
  - basics
---
# setup
i have 3 VMs: vm1, vm2 and vm3

| Node  | IP Address     |
| ----- | -------------- |
| node1 | 172.31.253.147 |
| node2 | 172.31.250.205 |
| node3 | 172.31.253.194 |

![Pasted image 20260319171638](/images/Pasted%20image%2020260319171638.png)

# step1: Install etcd on ALL 3 Nodes and create the data dir

![Pasted image 20260319171828](/images/Pasted%20image%2020260319171828.png)

let's verify the version and create the data directory
![Pasted image 20260319171932](/images/Pasted%20image%2020260319171932.png)

# step2: Create the etcd systemd Service

![Pasted image 20260319172432](/images/Pasted%20image%2020260319172432.png)

we do the same thing for other VMs changing just the ip add
for example for node1

```bash
cat << 'EOF' | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/etcd-io/etcd
After=network.target

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \
  --name=etcd-1 \
  --data-dir=/var/lib/etcd \
  --listen-peer-urls=http://172.31.252.48:2380 \
  --listen-client-urls=http://172.31.252.48:2379,http://127.0.0.1:2379 \
  --advertise-client-urls=http://172.31.252.48:2379 \
  --initial-advertise-peer-urls=http://172.31.252.48:2380 \
  --initial-cluster=etcd-1=http://172.31.252.48:2380,etcd-2=http://172.31.250.205:2380,etcd-3=http://172.31.253.194:2380 \
  --initial-cluster-token=k8s-etcd-cluster \
  --initial-cluster-state=new
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

--name: is the identity of this node in the cluster
--data-dir: where etcd stores all data on disk
--listen-peer-urls port 2380: talk to OTHER etcd nodes (Raft)
...

# start the service
let's reload and start etcd on all nodes

```bash
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd
```

![Pasted image 20260319212111](/images/Pasted%20image%2020260319212111.png)

now let's see the Raft election on logs

but wait wait -> what is the Raft election ? [see this](https://en.wikipedia.org/wiki/Raft_(algorithm))

```bash
sudo journalctl -u etcd -f
```
![Pasted image 20260319213533](/images/Pasted%20image%2020260319213533.png)

let's see if the cluster is healthy

```bash
etcdctl \
  --endpoints=http://172.31.253.147:2379,http://172.31.250.205:2379,http://172.31.253.194:2379 \
  endpoint health
```

![Pasted image 20260319213308](/images/Pasted%20image%2020260319213308.png)

#### let's check the leader
btw you can run it where ever you want
```bash
etcdctl \
  --endpoints=http://172.31.253.147:2379,http://172.31.250.205:2379,http://172.31.253.194:2379 \
  endpoint status --write-out=table
```

![Pasted image 20260319213824](/images/Pasted%20image%2020260319213824.png)

---

# Phase 2 — Talk to etcd Directly
now we'll do the job of apiserver 

let's put and get from the leader .147

```bash
etcdctl \
  --endpoints=http://172.31.253.147:2379 \
  put /registry/pods/default/nginx '{"kind":"Pod","name":"nginx"}'
```
=> ok

```bash
etcdctl \
  --endpoints=http://172.31.253.147:2379 \
  get /registry/pods/default/nginx
```
=> {"kind":"Pod","name":"nginx"}

![Pasted image 20260319214942](/images/Pasted%20image%2020260319214942.png)


now let's read from a follower like node2 
so this is the magic of Raft

we put it on node1 -> we get it from node2 or 3 

![Pasted image 20260319220038](/images/Pasted%20image%2020260319220038.png)

---
to be continued ...