# incus

## start

```
incus create cina cina -d eth0,ipv4.address=10.6.0.21
incus config device add cina eth1 nic network=public
incus start cina

incus create cinb cinb -d eth0,ipv4.address=10.6.0.22
incus config device add cinb eth1 nic network=public
incus start cinb
```

## ip change

```
incus config device override cina eth0 ipv4.address=10.6.0.21
```

## TODO

* auto-unset config removed from preseed (e.g. `incus project unset ingress restricted.devices.nic`)
* revisit macvlan vs. br-uplink bridge
* preservation on new vms
* ipv6
