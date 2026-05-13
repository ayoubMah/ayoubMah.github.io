---
title: Day 0 - linux primitives that make k8s possible
date: 2026-03-19T23:33:57+01:00
draft: false
tags: []
categories:
  - blog
  - k8s
  - basics
---
## so what what happen when we install k8s ?

when we install k8s actually we get this processes 
we can separate them logically (they are not separated physically like not namespaces or something)
they are just have a different roles :

```
Our Physical Machine (or VM)
│
├── Control plan processes  ← just Linux processes
│   ├── etcd           (a process)
│   ├── kube-apiserver (a process)
│   ├── kube-scheduler (a process)
│   └── kube-controller-manager (a process)
│
└── Worker Node processes    ← also just Linux processes
    ├── kubelet        (a process)
    ├── kube-proxy     (a process)
    └── containerd     (a process)
```

## so what is a node ?

a node it's just a machine (VM/ cloud instance) that k8s know about it and can schedule a work onto it

Node = a machine registered with Kubernetes that can run containers

node has: kubelet, kube-proxy and containerd 

```
┌─────────────────────────────────┐
│           NODE (a machine)      │
│                                 │
│  ┌─────────┐  ┌──────────────┐  │
│  │ kubelet │  │  containerd  │  │
│  └─────────┘  └──────────────┘  │
│  ┌────────────┐                 │
│  │ kube-proxy │                 │
│  └────────────┘                 │
│                                 │
│  [ pods running here ]          │
└─────────────────────────────────┘
```
kubelet is what make a machine node -> no kubelet = no node

## now what is a pod

"people say"= a pod is group of containers 
yes it's correct but not enough 

>A pod is the smallest deployable unit in k8s; it's a group of containers that share the same network namespace and the same storage, they live and die together 


```
┌─────────────────────────────────────────┐
│                  POD                    │
│                                         │
│  ┌──────────┐  pause  ┌──────────────┐  │
│  │  app     │container│   sidecar    │  │
│  │container │         │  container   │  │
│  └──────────┘         └──────────────┘  │
│                                         │
│  shared: network namespace (same IP)    │
│  shared: storage volumes                │
│  NOT shared: filesystem, processes      │
└─────────────────────────────────────────┘
```

so
app container    → localhost:8080
sidecar container → localhost:8080  ← same IP, same ports
                                      they ARE on the same "machine"
                                      from a network perspective

Visually 

```
┌──────────────────────────────────────────────────────┐
│                    NODE (machine)                    │
│                                                      │
│   ┌─────────────────┐     ┌─────────────────┐        │
│   │      POD 1      │     │      POD 2      │        │
│   │  ┌───────────┐  │     │  ┌───────────┐  │        │
│   │  │ container │  │     │  │ container │  │        │
│   │  └───────────┘  │     │  └───────────┘  │        │
│   │  IP: 10.0.0.1   │     │  IP: 10.0.0.2   │        │
│   └─────────────────┘     └─────────────────┘        │
│                                                      │
│   kubelet + containerd + kube-proxy                  │
└──────────────────────────────────────────────────────┘
```

each pod has its own ip
different pods on the same node can't use localhost to talk to each other  (cuz they are in a different network namespace)

