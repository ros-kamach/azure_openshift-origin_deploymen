# azure_openshift-origin_deploymen

# Prometheus and Grafana for OpenShift

This repository contains components for Deploy Openshift-Origin on Azure cluster. 

This Implimentation based on preconfigurated components in 
<img src="https://i1.wp.com/blog.openshift.com/wp-content/uploads/redhatopenshift.png?w=1376&ssl=1" alt="Thunder" width="10%"/> **"[microsoft/openshift-origin](https://github.com/microsoft/openshift-origin)"** CMS for OpenShift

To deploy, run:

syntax:
```
$ bash project.sh <project name for monitoring> <apply or delete> 
```
example:
```
$ bash prometheus-grafana.sh openshift-metrics apply
```