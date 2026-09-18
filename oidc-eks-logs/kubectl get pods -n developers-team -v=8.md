test@test:~$ kubectl get pods -n developers-team -v=8
I0918 11:35:33.313784  372046 loader.go:395] Config loaded from file:  /home/test/.kube/config
I0918 11:35:33.315750  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/api?timeout=32s
I0918 11:35:33.315829  372046 round_trippers.go:469] Request Headers:
I0918 11:35:33.315844  372046 round_trippers.go:473]     Accept: application/json;g=apidiscovery.k8s.io;v=v2beta1;as=APIGroupDiscoveryList,application/json
I0918 11:35:33.315860  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.257460  372046 round_trippers.go:574] Response Status: 200 OK in 941 milliseconds
I0918 11:35:34.257512  372046 round_trippers.go:577] Response Headers:
I0918 11:35:34.257533  372046 round_trippers.go:580]     Content-Length: 149
I0918 11:35:34.257549  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:34 GMT
I0918 11:35:34.257561  372046 round_trippers.go:580]     Audit-Id: 10a34adc-694d-4b14-b575-33c7b8f85417
I0918 11:35:34.257573  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:34.257582  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:34.257591  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:34.257599  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:34.258377  372046 request.go:1212] Response Body: {"kind":"APIVersions","versions":["v1"],"serverAddressByClientCIDRs":[{"clientCIDR":"0.0.0.0/0","serverAddress":"ip-10-0-35-241.ec2.internal:443"}]}
I0918 11:35:34.260315  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis?timeout=32s
I0918 11:35:34.260346  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.260365  372046 round_trippers.go:473]     Accept: application/json;g=apidiscovery.k8s.io;v=v2beta1;as=APIGroupDiscoveryList,application/json
I0918 11:35:34.260378  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.564050  372046 round_trippers.go:574] Response Status: 200 OK in 303 milliseconds
I0918 11:35:34.564092  372046 round_trippers.go:577] Response Headers:
I0918 11:35:34.564112  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:34 GMT
I0918 11:35:34.564126  372046 round_trippers.go:580]     Audit-Id: 8ebc4202-40be-4edd-a21b-4cb4d44ad2a3
I0918 11:35:34.564141  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:34.564151  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:34.564158  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:34.564170  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:34.564921  372046 request.go:1212] Response Body: {"kind":"APIGroupList","apiVersion":"v1","groups":[{"name":"apiregistration.k8s.io","versions":[{"groupVersion":"apiregistration.k8s.io/v1","version":"v1"}],"preferredVersion":{"groupVersion":"apiregistration.k8s.io/v1","version":"v1"}},{"name":"apps","versions":[{"groupVersion":"apps/v1","version":"v1"}],"preferredVersion":{"groupVersion":"apps/v1","version":"v1"}},{"name":"events.k8s.io","versions":[{"groupVersion":"events.k8s.io/v1","version":"v1"}],"preferredVersion":{"groupVersion":"events.k8s.io/v1","version":"v1"}},{"name":"authentication.k8s.io","versions":[{"groupVersion":"authentication.k8s.io/v1","version":"v1"}],"preferredVersion":{"groupVersion":"authentication.k8s.io/v1","version":"v1"}},{"name":"authorization.k8s.io","versions":[{"groupVersion":"authorization.k8s.io/v1","version":"v1"}],"preferredVersion":{"groupVersion":"authorization.k8s.io/v1","version":"v1"}},{"name":"autoscaling","versions":[{"groupVersion":"autoscaling/v2","version":"v2"},{"groupVersion":"autoscaling/v1","version":"v1"}], [truncated 3835 chars]
I0918 11:35:34.567179  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/coordination.k8s.io/v1?timeout=32s
I0918 11:35:34.567213  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.567234  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.567247  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.567273  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/api/v1?timeout=32s
I0918 11:35:34.567294  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.567310  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.567326  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.567430  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/discovery.k8s.io/v1?timeout=32s
I0918 11:35:34.567453  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.567473  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.567484  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/resource.k8s.io/v1beta1?timeout=32s
I0918 11:35:34.567512  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.567506  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/metrics.eks.amazonaws.com/v1?timeout=32s
I0918 11:35:34.567552  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.567278  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/authorization.k8s.io/v1?timeout=32s
I0918 11:35:34.567567  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/vpcresources.k8s.aws/v1alpha1?timeout=32s
I0918 11:35:34.567214  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/authentication.k8s.io/v1?timeout=32s
I0918 11:35:34.567591  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.567530  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.567609  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.567630  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.567659  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/certificates.k8s.io/v1?timeout=32s
I0918 11:35:34.567680  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.567323  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/resource.k8s.io/v1?timeout=32s
I0918 11:35:34.567715  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.567721  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/metrics.k8s.io/v1beta1?timeout=32s
I0918 11:35:34.567735  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/networking.k8s.io/v1?timeout=32s
I0918 11:35:34.567760  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.567659  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/flowcontrol.apiserver.k8s.io/v1?timeout=32s
I0918 11:35:34.567778  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.567787  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.567795  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.567810  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.567822  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/autoscaling/v2?timeout=32s
I0918 11:35:34.567854  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.567740  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.567896  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.567912  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.567858  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/apiregistration.k8s.io/v1?timeout=32s
I0918 11:35:34.567968  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.567989  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.567999  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.567814  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/policy/v1?timeout=32s
I0918 11:35:34.567828  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.568414  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.568451  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.568467  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.567617  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/scheduling.k8s.io/v1?timeout=32s
I0918 11:35:34.567554  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/networking.k8s.aws/v1alpha1?timeout=32s
I0918 11:35:34.568554  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.567573  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.568600  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.568611  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.568635  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.567433  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/storage.k8s.io/v1beta1?timeout=32s
I0918 11:35:34.568650  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.568666  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.568676  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.567197  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/events.k8s.io/v1?timeout=32s
I0918 11:35:34.568684  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.568716  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.568734  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.568737  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.567476  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/eks.amazonaws.com/v1?timeout=32s
I0918 11:35:34.568767  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.568778  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.568795  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.568817  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.567492  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/admissionregistration.k8s.io/v1?timeout=32s
I0918 11:35:34.568898  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.568929  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.568940  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.567495  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.567494  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/autoscaling/v1?timeout=32s
I0918 11:35:34.569093  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.569109  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.569125  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.567563  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/batch/v1?timeout=32s
I0918 11:35:34.569141  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.569159  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.569169  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.567568  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/eks.amazonaws.com/v1alpha1?timeout=32s
I0918 11:35:34.569221  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.569235  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.569246  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.567579  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/storage.k8s.io/v1?timeout=32s
I0918 11:35:34.569336  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.567580  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.569357  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.569376  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.567585  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/apps/v1?timeout=32s
I0918 11:35:34.569404  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.567599  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.567602  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/apiextensions.k8s.io/v1?timeout=32s
I0918 11:35:34.569423  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.567618  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.569448  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.569494  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.569505  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.567727  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.567741  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/rbac.authorization.k8s.io/v1?timeout=32s
I0918 11:35:34.569582  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.569598  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.567772  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/karpenter.sh/v1?timeout=32s
I0918 11:35:34.569608  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.569619  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.567773  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/node.k8s.io/v1?timeout=32s
I0918 11:35:34.570078  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.570098  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.570107  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.567830  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/vpcresources.k8s.aws/v1beta1?timeout=32s
I0918 11:35:34.570165  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.570181  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.570193  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.567876  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.570265  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.568687  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.569376  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.570394  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.569448  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.570419  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.567723  372046 round_trippers.go:469] Request Headers:
I0918 11:35:34.570432  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.570444  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.569633  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:34.570459  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.570474  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:34.871538  372046 round_trippers.go:574] Response Status: 200 OK in 304 milliseconds
I0918 11:35:34.871597  372046 round_trippers.go:577] Response Headers:
I0918 11:35:34.871628  372046 round_trippers.go:580]     Audit-Id: f327d6a4-8e8a-40bc-9ba8-fa46143b8849
I0918 11:35:34.871646  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:34.871661  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:34.871678  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:34.871715  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:34.871750  372046 round_trippers.go:580]     Content-Length: 294
I0918 11:35:34.871767  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:34 GMT
I0918 11:35:34.871779  372046 round_trippers.go:574] Response Status: 200 OK in 304 milliseconds
I0918 11:35:34.871859  372046 round_trippers.go:577] Response Headers:
I0918 11:35:34.871877  372046 round_trippers.go:574] Response Status: 200 OK in 303 milliseconds
I0918 11:35:34.871807  372046 round_trippers.go:574] Response Status: 200 OK in 304 milliseconds
I0918 11:35:34.871858  372046 round_trippers.go:574] Response Status: 200 OK in 304 milliseconds
I0918 11:35:34.871935  372046 round_trippers.go:574] Response Status: 200 OK in 303 milliseconds
I0918 11:35:34.871958  372046 round_trippers.go:577] Response Headers:
I0918 11:35:34.871894  372046 round_trippers.go:580]     Audit-Id: f1995ddb-e7b7-496c-9693-6c92e2610260
I0918 11:35:34.871982  372046 round_trippers.go:574] Response Status: 200 OK in 303 milliseconds
I0918 11:35:34.871996  372046 round_trippers.go:580]     Audit-Id: de4ee5b3-e432-4df4-ba82-234ae988effd
I0918 11:35:34.872004  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:34.872030  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:34.872057  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:34.871967  372046 round_trippers.go:577] Response Headers:
I0918 11:35:34.872134  372046 round_trippers.go:580]     Audit-Id: f14be7c7-d6fe-435b-80ce-3898348691de
I0918 11:35:34.872162  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:34.872177  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:34.872036  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:34.872190  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:34.872215  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:34.872243  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:34.872261  372046 round_trippers.go:580]     Content-Length: 329
I0918 11:35:34.872218  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:34.872282  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:34 GMT
I0918 11:35:34.872303  372046 round_trippers.go:580]     Content-Length: 850
I0918 11:35:34.872322  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:34 GMT
I0918 11:35:34.872011  372046 round_trippers.go:577] Response Headers:
I0918 11:35:34.872422  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:34.871932  372046 round_trippers.go:574] Response Status: 200 OK in 303 milliseconds
I0918 11:35:34.872468  372046 round_trippers.go:577] Response Headers:
I0918 11:35:34.872494  372046 round_trippers.go:580]     Audit-Id: 9b43a268-fc5d-46cd-b7d3-20d67927c790
I0918 11:35:34.872516  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:34.871952  372046 round_trippers.go:577] Response Headers:
I0918 11:35:34.872534  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:34.872547  372046 round_trippers.go:580]     Audit-Id: 3d46b817-e71f-48f4-9315-832b07bd90f9
I0918 11:35:34.872561  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:34.872570  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:34.872584  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:34.872596  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:34.872612  372046 round_trippers.go:580]     Content-Length: 465
I0918 11:35:34.872619  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:34.872628  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"coordination.k8s.io/v1","resources":[{"name":"leases","singularName":"lease","namespaced":true,"kind":"Lease","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"gqkMMb/YqFM="}]}
I0918 11:35:34.872079  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:34.872772  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:34.872795  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:34 GMT
I0918 11:35:34.871924  372046 round_trippers.go:577] Response Headers:
I0918 11:35:34.872857  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:34.872872  372046 round_trippers.go:580]     Content-Length: 365
I0918 11:35:34.872886  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:34 GMT
I0918 11:35:34.872900  372046 round_trippers.go:580]     Audit-Id: 335f4f87-2226-466c-98ff-df295f8d48b5
I0918 11:35:34.872914  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:34.872929  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:34.872942  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:34.872913  372046 round_trippers.go:574] Response Status: 503 Service Unavailable in 304 milliseconds
I0918 11:35:34.873023  372046 round_trippers.go:577] Response Headers:
I0918 11:35:34.873044  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:34.873060  372046 round_trippers.go:580]     Content-Length: 20
I0918 11:35:34.873073  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:34 GMT
I0918 11:35:34.873086  372046 round_trippers.go:580]     Audit-Id: b0cabe46-0dbc-428e-a7b2-fdb28fd38e6c
I0918 11:35:34.873099  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:34.873113  372046 round_trippers.go:580]     Content-Type: text/plain; charset=utf-8
I0918 11:35:34.873130  372046 round_trippers.go:580]     X-Content-Type-Options: nosniff
I0918 11:35:34.873143  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:34.872631  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:34 GMT
I0918 11:35:34.872642  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:34.873233  372046 round_trippers.go:580]     Content-Length: 1461
I0918 11:35:34.873253  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:34 GMT
I0918 11:35:34.872440  372046 round_trippers.go:580]     Content-Length: 1686
I0918 11:35:34.873290  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:34 GMT
I0918 11:35:34.873304  372046 round_trippers.go:580]     Audit-Id: 15223a16-0179-410f-a124-c20621000fac
I0918 11:35:34.873322  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:34.873335  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:34.873350  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:34.873415  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"vpcresources.k8s.aws/v1alpha1","resources":[{"name":"cninodes","singularName":"cninode","namespaced":false,"kind":"CNINode","verbs":["delete","deletecollection","get","list","patch","create","update","watch"],"shortNames":["cnd"],"storageVersionHash":"w5K4FF5Ny3g="}]}
I0918 11:35:34.875003  372046 request.go:1212] Response Body: {"kind":"APIResourceList","groupVersion":"v1","resources":[{"name":"bindings","singularName":"binding","namespaced":true,"kind":"Binding","verbs":["create"]},{"name":"componentstatuses","singularName":"componentstatus","namespaced":false,"kind":"ComponentStatus","verbs":["get","list"],"shortNames":["cs"]},{"name":"configmaps","singularName":"configmap","namespaced":true,"kind":"ConfigMap","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"shortNames":["cm"],"storageVersionHash":"qFsyl6wFWjQ="},{"name":"endpoints","singularName":"endpoints","namespaced":true,"kind":"Endpoints","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"shortNames":["ep"],"storageVersionHash":"fWeeMqaN/OA="},{"name":"events","singularName":"event","namespaced":true,"kind":"Event","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"shortNames":["ev"],"storageVersionHash":"r2yiGXH7wu8="},{"name":"limitranges","singularName":"limitrange" [truncated 5464 chars]
I0918 11:35:35.179344  372046 round_trippers.go:574] Response Status: 200 OK in 610 milliseconds
I0918 11:35:35.179409  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.179448  372046 round_trippers.go:580]     Audit-Id: 64d3c288-330d-41b9-9237-b399b7c02a8f
I0918 11:35:35.179474  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.179500  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.179521  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.179547  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.179560  372046 round_trippers.go:580]     Content-Length: 308
I0918 11:35:35.179575  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:34 GMT
I0918 11:35:35.179593  372046 round_trippers.go:574] Response Status: 200 OK in 610 milliseconds
I0918 11:35:35.179667  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.179671  372046 round_trippers.go:574] Response Status: 200 OK in 610 milliseconds
I0918 11:35:35.179769  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.179775  372046 round_trippers.go:574] Response Status: 200 OK in 611 milliseconds
I0918 11:35:35.179802  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.179808  372046 round_trippers.go:574] Response Status: 200 OK in 610 milliseconds
I0918 11:35:35.179827  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.179852  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.179870  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:34 GMT
I0918 11:35:35.179878  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.179897  372046 round_trippers.go:580]     Audit-Id: ef80e345-9184-4978-ae42-217424f62f2b
I0918 11:35:35.179903  372046 round_trippers.go:574] Response Status: 200 OK in 610 milliseconds
I0918 11:35:35.179923  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.179933  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.179936  372046 round_trippers.go:574] Response Status: 200 OK in 610 milliseconds
I0918 11:35:35.179952  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.179968  372046 round_trippers.go:574] Response Status: 200 OK in 610 milliseconds
I0918 11:35:35.179978  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.179981  372046 round_trippers.go:574] Response Status: 200 OK in 610 milliseconds
I0918 11:35:35.179988  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.179975  372046 round_trippers.go:574] Response Status: 200 OK in 609 milliseconds
I0918 11:35:35.180008  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.180021  372046 round_trippers.go:580]     Audit-Id: 56fa781c-e1bf-4aef-8de2-55d138b8b0ed
I0918 11:35:35.180029  372046 round_trippers.go:574] Response Status: 200 OK in 609 milliseconds
I0918 11:35:35.180038  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.180042  372046 request.go:1212] Response Body: service unavailable
I0918 11:35:35.180056  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.180060  372046 round_trippers.go:574] Response Status: 200 OK in 609 milliseconds
I0918 11:35:35.180175  372046 round_trippers.go:574] Response Status: 200 OK in 609 milliseconds
I0918 11:35:35.180218  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.180231  372046 round_trippers.go:574] Response Status: 200 OK in 609 milliseconds
I0918 11:35:35.180302  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.180335  372046 round_trippers.go:580]     Content-Length: 338
I0918 11:35:35.180354  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:35 GMT
I0918 11:35:35.180367  372046 round_trippers.go:580]     Audit-Id: a8275f40-e2d2-4965-8e12-358a02842615
I0918 11:35:35.179824  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.180427  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.180445  372046 round_trippers.go:580]     Content-Length: 2043
I0918 11:35:35.180454  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:34 GMT
I0918 11:35:35.180467  372046 round_trippers.go:580]     Audit-Id: 0de38ef3-b8e9-4b1c-9915-1e850a3d875b
I0918 11:35:35.180479  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.180257  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.180517  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.180535  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.180545  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.180567  372046 round_trippers.go:580]     Content-Length: 679
I0918 11:35:35.180586  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:35 GMT
I0918 11:35:35.180038  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.180659  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.180708  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.179898  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.180725  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"storage.k8s.io/v1beta1","resources":[{"name":"volumeattributesclasses","singularName":"volumeattributesclass","namespaced":false,"kind":"VolumeAttributesClass","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"shortNames":["vac"],"storageVersionHash":"tIjydgKBC5w="}]}
I0918 11:35:35.180738  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.180779  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.180793  372046 round_trippers.go:580]     Content-Length: 1604
I0918 11:35:35.180806  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:34 GMT
I0918 11:35:35.180819  372046 round_trippers.go:580]     Audit-Id: bdd8dd71-6236-49de-8879-08745174603c
I0918 11:35:35.179969  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.180877  372046 round_trippers.go:580]     Audit-Id: a0cfdac1-20d0-421c-8ef7-a611fac5285a
I0918 11:35:35.180893  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.180907  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.179668  372046 round_trippers.go:574] Response Status: 200 OK in 610 milliseconds
I0918 11:35:35.180922  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.180941  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.179926  372046 round_trippers.go:574] Response Status: 200 OK in 610 milliseconds
I0918 11:35:35.180961  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:34 GMT
I0918 11:35:35.180972  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.180992  372046 round_trippers.go:580]     Audit-Id: 9016c447-d1c2-448b-9580-76184acf52d2
I0918 11:35:35.181008  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.181022  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.179946  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.181089  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.181113  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.181131  372046 round_trippers.go:580]     Content-Length: 481
I0918 11:35:35.180947  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.181191  372046 round_trippers.go:580]     Content-Length: 798
I0918 11:35:35.181205  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:34 GMT
I0918 11:35:35.180975  372046 round_trippers.go:580]     Audit-Id: ac684376-54d7-433f-8955-493dd81397ce
I0918 11:35:35.181259  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.181270  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.181281  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.181294  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.181306  372046 round_trippers.go:580]     Content-Length: 1122
I0918 11:35:35.179509  372046 round_trippers.go:574] Response Status: 200 OK in 610 milliseconds
I0918 11:35:35.181345  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.181364  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.181378  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.179733  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:34 GMT
I0918 11:35:35.181397  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.181413  372046 round_trippers.go:580]     Content-Length: 1028
I0918 11:35:35.181429  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:34 GMT
I0918 11:35:35.181404  372046 round_trippers.go:580]     Audit-Id: 07ffe12a-6491-47ce-a644-a667b6ead78f
I0918 11:35:35.181468  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"apiregistration.k8s.io/v1","resources":[{"name":"apiservices","singularName":"apiservice","namespaced":false,"kind":"APIService","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"categories":["api-extensions"],"storageVersionHash":"InPBPD7+PqM="},{"name":"apiservices/status","singularName":"","namespaced":false,"kind":"APIService","verbs":["get","patch","update"]}]}
I0918 11:35:35.181495  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.181522  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.181538  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.181551  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.181563  372046 round_trippers.go:580]     Content-Length: 755
I0918 11:35:35.179898  372046 round_trippers.go:574] Response Status: 200 OK in 610 milliseconds
I0918 11:35:35.179828  372046 round_trippers.go:574] Response Status: 200 OK in 610 milliseconds
I0918 11:35:35.179929  372046 round_trippers.go:574] Response Status: 200 OK in 609 milliseconds
I0918 11:35:35.180025  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.181687  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.181733  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:35 GMT
I0918 11:35:35.181749  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.180051  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.181767  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.181757  372046 round_trippers.go:580]     Audit-Id: dc9f5548-cafd-4c49-8d4b-6a52b2e5cf1e
I0918 11:35:35.181788  372046 round_trippers.go:580]     Content-Length: 942
I0918 11:35:35.181797  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.181810  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:35 GMT
I0918 11:35:35.181822  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.181833  372046 round_trippers.go:580]     Audit-Id: 197f3f0c-5239-44fb-8a8c-5ca77b64467f
I0918 11:35:35.181855  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.181844  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.181891  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.181903  372046 round_trippers.go:580]     Content-Length: 561
I0918 11:35:35.180076  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.181999  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.180067  372046 round_trippers.go:574] Response Status: 200 OK in 609 milliseconds
I0918 11:35:35.182013  372046 round_trippers.go:580]     Content-Length: 2254
I0918 11:35:35.182025  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.182032  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:35 GMT
I0918 11:35:35.182044  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.182067  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.180262  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.182081  372046 round_trippers.go:580]     Content-Length: 527
I0918 11:35:35.182093  372046 round_trippers.go:580]     Content-Length: 364
I0918 11:35:35.182103  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:35 GMT
I0918 11:35:35.182112  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:35 GMT
I0918 11:35:35.182170  372046 round_trippers.go:580]     Audit-Id: ad90dc12-9151-480b-86b8-1c0f08c92c3e
I0918 11:35:35.182180  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.182191  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.180387  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.182204  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.182218  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.182259  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.182272  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.180601  372046 round_trippers.go:580]     Audit-Id: a4497d34-593c-46a9-8dd2-b3fa45eddcd7
I0918 11:35:35.182304  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.180728  372046 round_trippers.go:580]     Content-Length: 343
I0918 11:35:35.182370  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:35 GMT
I0918 11:35:35.182381  372046 round_trippers.go:580]     Audit-Id: 02f0e009-651e-4fb1-9301-4d17fe94bda7
I0918 11:35:35.182393  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.182423  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"flowcontrol.apiserver.k8s.io/v1","resources":[{"name":"flowschemas","singularName":"flowschema","namespaced":false,"kind":"FlowSchema","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"GJVAJZSZBIw="},{"name":"flowschemas/status","singularName":"","namespaced":false,"kind":"FlowSchema","verbs":["get","patch","update"]},{"name":"prioritylevelconfigurations","singularName":"prioritylevelconfiguration","namespaced":false,"kind":"PriorityLevelConfiguration","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"Kir5PVfvNeI="},{"name":"prioritylevelconfigurations/status","singularName":"","namespaced":false,"kind":"PriorityLevelConfiguration","verbs":["get","patch","update"]}]}
I0918 11:35:35.181048  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.182486  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.182501  372046 round_trippers.go:580]     Content-Length: 315
I0918 11:35:35.182512  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:34 GMT
I0918 11:35:35.179365  372046 round_trippers.go:574] Response Status: 200 OK in 610 milliseconds
I0918 11:35:35.182595  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.181442  372046 round_trippers.go:580]     Audit-Id: b13089f5-badf-4a74-ae8a-a34227816d32
I0918 11:35:35.182616  372046 round_trippers.go:580]     Audit-Id: f3d77425-bb2d-4ef5-aea0-d6a5f40213ce
I0918 11:35:35.182627  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.182632  372046 round_trippers.go:580]     Audit-Id: f3d77425-bb2d-4ef5-aea0-d6a5f40213ce
I0918 11:35:35.182654  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:34 GMT
I0918 11:35:35.181629  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.182683  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.182713  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.182714  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.179991  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.182741  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.182751  372046 round_trippers.go:580]     Content-Length: 959
I0918 11:35:35.182765  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.181660  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.182796  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.182804  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.182816  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.182825  372046 round_trippers.go:580]     Content-Length: 527
I0918 11:35:35.182832  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:34 GMT
I0918 11:35:35.182843  372046 round_trippers.go:580]     Audit-Id: 6a4be1dd-c882-4eb0-8b4a-cf28dca231b4
I0918 11:35:35.182774  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:35 GMT
I0918 11:35:35.182855  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.182864  372046 round_trippers.go:580]     Audit-Id: 4d68172d-c3ef-434f-a3f8-f1245f5edc29
I0918 11:35:35.182887  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.182927  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"authentication.k8s.io/v1","resources":[{"name":"selfsubjectreviews","singularName":"selfsubjectreview","namespaced":false,"kind":"SelfSubjectReview","verbs":["create"]},{"name":"tokenreviews","singularName":"tokenreview","namespaced":false,"kind":"TokenReview","verbs":["create"]}]}
I0918 11:35:35.179997  372046 round_trippers.go:574] Response Status: 200 OK in 609 milliseconds
I0918 11:35:35.182990  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.183007  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.183019  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.183030  372046 round_trippers.go:580]     Content-Length: 1117
I0918 11:35:35.181780  372046 round_trippers.go:580]     Audit-Id: 7bc24737-8b2c-4737-8315-c0836625c50b
I0918 11:35:35.183060  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.183072  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.183083  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.183091  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.183101  372046 round_trippers.go:580]     Content-Length: 309
I0918 11:35:35.183114  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:35 GMT
I0918 11:35:35.181868  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.182088  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"events.k8s.io/v1","resources":[{"name":"events","singularName":"event","namespaced":true,"kind":"Event","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"shortNames":["ev"],"storageVersionHash":"r2yiGXH7wu8="}]}
I0918 11:35:35.182158  372046 round_trippers.go:580]     Audit-Id: abd0b9ee-4262-455b-ad1b-dac4790caddf
I0918 11:35:35.183271  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.183286  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.182726  372046 round_trippers.go:580]     Content-Length: 678
I0918 11:35:35.183346  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:35 GMT
I0918 11:35:35.183360  372046 round_trippers.go:580]     Audit-Id: bc732cee-513f-49cc-aa2f-2c28c386ae0e
I0918 11:35:35.183369  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.183375  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.182783  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.189167  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.189175  372046 round_trippers.go:580]     Content-Length: 711
I0918 11:35:35.189201  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"certificates.k8s.io/v1","resources":[{"name":"certificatesigningrequests","singularName":"certificatesigningrequest","namespaced":false,"kind":"CertificateSigningRequest","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"shortNames":["csr"],"storageVersionHash":"95fRKMXA+00="},{"name":"certificatesigningrequests/approval","singularName":"","namespaced":false,"kind":"CertificateSigningRequest","verbs":["get","patch","update"]},{"name":"certificatesigningrequests/status","singularName":"","namespaced":false,"kind":"CertificateSigningRequest","verbs":["get","patch","update"]}]}
I0918 11:35:35.183041  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:35 GMT
I0918 11:35:35.189242  372046 round_trippers.go:580]     Audit-Id: 7267ee38-dde4-4f63-a919-c2ba98706f81
I0918 11:35:35.189251  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.189256  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:35.183393  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"rbac.authorization.k8s.io/v1","resources":[{"name":"clusterrolebindings","singularName":"clusterrolebinding","namespaced":false,"kind":"ClusterRoleBinding","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"48tpQ8gZHFc="},{"name":"clusterroles","singularName":"clusterrole","namespaced":false,"kind":"ClusterRole","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"bYE5ZWDrJ44="},{"name":"rolebindings","singularName":"rolebinding","namespaced":true,"kind":"RoleBinding","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"eGsCzGH6b1g="},{"name":"roles","singularName":"role","namespaced":true,"kind":"Role","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"7FuwZcIIItM="}]}
I0918 11:35:35.184220  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"networking.k8s.io/v1","resources":[{"name":"ingressclasses","singularName":"ingressclass","namespaced":false,"kind":"IngressClass","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"l/iqIbDgFyQ="},{"name":"ingresses","singularName":"ingress","namespaced":true,"kind":"Ingress","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"shortNames":["ing"],"storageVersionHash":"39NQlfNR+bo="},{"name":"ingresses/status","singularName":"","namespaced":true,"kind":"Ingress","verbs":["get","patch","update"]},{"name":"ipaddresses","singularName":"ipaddress","namespaced":false,"kind":"IPAddress","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"shortNames":["ip"],"storageVersionHash":"3f/plJFChNE="},{"name":"networkpolicies","singularName":"networkpolicy","namespaced":true,"kind":"NetworkPolicy","verbs":["create","delete","deletecollection"," [truncated 437 chars]
I0918 11:35:35.184520  372046 request.go:1411] body was not decodable (unable to check for Status): couldn't get version/kind; json parse error: json: cannot unmarshal string into Go value of type struct { APIVersion string "json:\"apiVersion,omitempty\""; Kind string "json:\"kind,omitempty\"" }
E0918 11:35:35.189379  372046 memcache.go:287] couldn't get resource list for metrics.k8s.io/v1beta1: the server is currently unable to handle the request
I0918 11:35:35.184607  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"admissionregistration.k8s.io/v1","resources":[{"name":"mutatingadmissionpolicies","singularName":"mutatingadmissionpolicy","namespaced":false,"kind":"MutatingAdmissionPolicy","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"categories":["api-extensions"],"storageVersionHash":"LYmCf+UMVdg="},{"name":"mutatingadmissionpolicybindings","singularName":"mutatingadmissionpolicybinding","namespaced":false,"kind":"MutatingAdmissionPolicyBinding","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"categories":["api-extensions"],"storageVersionHash":"90V5FRZZ3Zg="},{"name":"mutatingwebhookconfigurations","singularName":"mutatingwebhookconfiguration","namespaced":false,"kind":"MutatingWebhookConfiguration","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"categories":["api-extensions"],"storageVersionHash":"Sqi0GUgDaX0="},{"name":"validatingadmissionpolicie [truncated 1019 chars]
I0918 11:35:35.184957  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"storage.k8s.io/v1","resources":[{"name":"csidrivers","singularName":"csidriver","namespaced":false,"kind":"CSIDriver","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"hL6j/rwBV5w="},{"name":"csinodes","singularName":"csinode","namespaced":false,"kind":"CSINode","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"Pe62DkZtjuo="},{"name":"csistoragecapacities","singularName":"csistoragecapacity","namespaced":true,"kind":"CSIStorageCapacity","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"xeVl+2Ly1kE="},{"name":"storageclasses","singularName":"storageclass","namespaced":false,"kind":"StorageClass","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"shortNames":["sc"],"storageVersionHash":"K+m6uJwbjGY="},{"name":"volumeattachments","singularName":"volum [truncated 580 chars]
I0918 11:35:35.189446  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"resource.k8s.io/v1","resources":[{"name":"deviceclasses","singularName":"deviceclass","namespaced":false,"kind":"DeviceClass","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"Yk2PTc1Ybxk="},{"name":"resourceclaims","singularName":"resourceclaim","namespaced":true,"kind":"ResourceClaim","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"wgAZaHcZxUg="},{"name":"resourceclaims/status","singularName":"","namespaced":true,"kind":"ResourceClaim","verbs":["get","patch","update"]},{"name":"resourceclaimtemplates","singularName":"resourceclaimtemplate","namespaced":true,"kind":"ResourceClaimTemplate","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"TuzjC49aUfM="},{"name":"resourceslices","singularName":"resourceslice","namespaced":false,"kind":"ResourceSlice","verbs":["create","delete","del [truncated 93 chars]
I0918 11:35:35.185092  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"eks.amazonaws.com/v1alpha1","resources":[{"name":"cninodes","singularName":"cninode","namespaced":false,"kind":"CNINode","verbs":["delete","deletecollection","get","list","patch","create","update","watch"],"shortNames":["cni","cnis"],"storageVersionHash":"xO4osxL/jOs="},{"name":"cninodes/status","singularName":"","namespaced":false,"kind":"CNINode","verbs":["get","patch","update"]},{"name":"nodediagnostics","singularName":"nodediagnostic","namespaced":false,"kind":"NodeDiagnostic","verbs":["delete","deletecollection","get","list","patch","create","update","watch"],"storageVersionHash":"J/CQx7OV2Hw="},{"name":"nodediagnostics/status","singularName":"","namespaced":false,"kind":"NodeDiagnostic","verbs":["get","patch","update"]}]}
I0918 11:35:35.185195  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"policy/v1","resources":[{"name":"poddisruptionbudgets","singularName":"poddisruptionbudget","namespaced":true,"kind":"PodDisruptionBudget","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"shortNames":["pdb"],"storageVersionHash":"EVWiDmWqyJw="},{"name":"poddisruptionbudgets/status","singularName":"","namespaced":true,"kind":"PodDisruptionBudget","verbs":["get","patch","update"]}]}
I0918 11:35:35.185295  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"resource.k8s.io/v1beta1","resources":[{"name":"deviceclasses","singularName":"deviceclass","namespaced":false,"kind":"DeviceClass","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"Yk2PTc1Ybxk="},{"name":"resourceclaims","singularName":"resourceclaim","namespaced":true,"kind":"ResourceClaim","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"wgAZaHcZxUg="},{"name":"resourceclaims/status","singularName":"","namespaced":true,"kind":"ResourceClaim","verbs":["get","patch","update"]},{"name":"resourceclaimtemplates","singularName":"resourceclaimtemplate","namespaced":true,"kind":"ResourceClaimTemplate","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"TuzjC49aUfM="},{"name":"resourceslices","singularName":"resourceslice","namespaced":false,"kind":"ResourceSlice","verbs":["create","delete" [truncated 98 chars]
I0918 11:35:35.185395  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"batch/v1","resources":[{"name":"cronjobs","singularName":"cronjob","namespaced":true,"kind":"CronJob","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"shortNames":["cj"],"categories":["all"],"storageVersionHash":"sd5LIXh4Fjs="},{"name":"cronjobs/status","singularName":"","namespaced":true,"kind":"CronJob","verbs":["get","patch","update"]},{"name":"jobs","singularName":"job","namespaced":true,"kind":"Job","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"categories":["all"],"storageVersionHash":"mudhfqk/qZY="},{"name":"jobs/status","singularName":"","namespaced":true,"kind":"Job","verbs":["get","patch","update"]}]}
I0918 11:35:35.185992  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"apiextensions.k8s.io/v1","resources":[{"name":"customresourcedefinitions","singularName":"customresourcedefinition","namespaced":false,"kind":"CustomResourceDefinition","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"shortNames":["crd","crds"],"categories":["api-extensions"],"storageVersionHash":"jfWCUB31mvA="},{"name":"customresourcedefinitions/status","singularName":"","namespaced":false,"kind":"CustomResourceDefinition","verbs":["get","patch","update"]}]}
I0918 11:35:35.186306  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"apps/v1","resources":[{"name":"controllerrevisions","singularName":"controllerrevision","namespaced":true,"kind":"ControllerRevision","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"85nkx63pcBU="},{"name":"daemonsets","singularName":"daemonset","namespaced":true,"kind":"DaemonSet","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"shortNames":["ds"],"categories":["all"],"storageVersionHash":"dd7pWHUlMKQ="},{"name":"daemonsets/status","singularName":"","namespaced":true,"kind":"DaemonSet","verbs":["get","patch","update"]},{"name":"deployments","singularName":"deployment","namespaced":true,"kind":"Deployment","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"shortNames":["deploy"],"categories":["all"],"storageVersionHash":"8aSe+NMegvE="},{"name":"deployments/scale","singularName":"","namespaced":true,"group":"autoscaling","v [truncated 1230 chars]
I0918 11:35:35.186554  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"vpcresources.k8s.aws/v1beta1","resources":[{"name":"securitygrouppolicies","singularName":"securitygrouppolicy","namespaced":true,"kind":"SecurityGroupPolicy","verbs":["delete","deletecollection","get","list","patch","create","update","watch"],"shortNames":["sgp"],"storageVersionHash":"K7924G3Qm8E="}]}
I0918 11:35:35.186808  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"authorization.k8s.io/v1","resources":[{"name":"localsubjectaccessreviews","singularName":"localsubjectaccessreview","namespaced":true,"kind":"LocalSubjectAccessReview","verbs":["create"]},{"name":"selfsubjectaccessreviews","singularName":"selfsubjectaccessreview","namespaced":false,"kind":"SelfSubjectAccessReview","verbs":["create"]},{"name":"selfsubjectrulesreviews","singularName":"selfsubjectrulesreview","namespaced":false,"kind":"SelfSubjectRulesReview","verbs":["create"]},{"name":"subjectaccessreviews","singularName":"subjectaccessreview","namespaced":false,"kind":"SubjectAccessReview","verbs":["create"]}]}
I0918 11:35:35.187061  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"networking.k8s.aws/v1alpha1","resources":[{"name":"policyendpoints","singularName":"policyendpoint","namespaced":true,"kind":"PolicyEndpoint","verbs":["delete","deletecollection","get","list","patch","create","update","watch"],"storageVersionHash":"x9WLGHGKClk="},{"name":"policyendpoints/status","singularName":"","namespaced":true,"kind":"PolicyEndpoint","verbs":["get","patch","update"]},{"name":"applicationnetworkpolicies","singularName":"applicationnetworkpolicy","namespaced":true,"kind":"ApplicationNetworkPolicy","verbs":["delete","deletecollection","get","list","patch","create","update","watch"],"shortNames":["anp"],"storageVersionHash":"ZJgHvIDUmAM="},{"name":"applicationnetworkpolicies/status","singularName":"","namespaced":true,"kind":"ApplicationNetworkPolicy","verbs":["get","patch","update"]},{"name":"clusterpolicyendpoints","singularName":"clusterpolicyendpoint","namespaced":false,"kind":"ClusterPolicyEndpoint","verbs":["delete","deletecoll [truncated 662 chars]
I0918 11:35:35.187293  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"discovery.k8s.io/v1","resources":[{"name":"endpointslices","singularName":"endpointslice","namespaced":true,"kind":"EndpointSlice","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"qgS0xkrxYAI="}]}
I0918 11:35:35.187493  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"eks.amazonaws.com/v1","resources":[{"name":"targetgroupbindings","singularName":"targetgroupbinding","namespaced":true,"kind":"TargetGroupBinding","verbs":["delete","deletecollection","get","list","patch","create","update","watch"],"storageVersionHash":"IlWl5LeeEKQ="},{"name":"targetgroupbindings/status","singularName":"","namespaced":true,"kind":"TargetGroupBinding","verbs":["get","patch","update"]},{"name":"nodeclasses","singularName":"nodeclass","namespaced":false,"kind":"NodeClass","verbs":["delete","deletecollection","get","list","patch","create","update","watch"],"storageVersionHash":"EIGjKBuCTYM="},{"name":"nodeclasses/status","singularName":"","namespaced":false,"kind":"NodeClass","verbs":["get","patch","update"]},{"name":"ingressclassparams","singularName":"ingressclassparams","namespaced":false,"kind":"IngressClassParams","verbs":["delete","deletecollection","get","list","patch","create","update","watch"],"storageVersionHash":"f4vP6lQFnnM=" [truncated 4 chars]
I0918 11:35:35.187633  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"autoscaling/v1","resources":[{"name":"horizontalpodautoscalers","singularName":"horizontalpodautoscaler","namespaced":true,"kind":"HorizontalPodAutoscaler","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"shortNames":["hpa"],"categories":["all"],"storageVersionHash":"qwQve8ut294="},{"name":"horizontalpodautoscalers/status","singularName":"","namespaced":true,"kind":"HorizontalPodAutoscaler","verbs":["get","patch","update"]}]}
I0918 11:35:35.187744  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"node.k8s.io/v1","resources":[{"name":"runtimeclasses","singularName":"runtimeclass","namespaced":false,"kind":"RuntimeClass","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"storageVersionHash":"WQTu1GL3T2Q="}]}
I0918 11:35:35.188035  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"karpenter.sh/v1","resources":[{"name":"nodeclaims","singularName":"nodeclaim","namespaced":false,"kind":"NodeClaim","verbs":["delete","deletecollection","get","list","patch","create","update","watch"],"categories":["karpenter"],"storageVersionHash":"QTizURWjI3E="},{"name":"nodeclaims/status","singularName":"","namespaced":false,"kind":"NodeClaim","verbs":["get","patch","update"]},{"name":"nodepools","singularName":"nodepool","namespaced":false,"kind":"NodePool","verbs":["delete","deletecollection","get","list","patch","create","update","watch"],"categories":["karpenter"],"storageVersionHash":"Vc6J1THIlNI="},{"name":"nodepools/status","singularName":"","namespaced":false,"kind":"NodePool","verbs":["get","patch","update"]},{"name":"nodepools/scale","singularName":"","namespaced":false,"group":"autoscaling","version":"v1","kind":"Scale","verbs":["get","patch","update"]}]}
I0918 11:35:35.188135  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"autoscaling/v2","resources":[{"name":"horizontalpodautoscalers","singularName":"horizontalpodautoscaler","namespaced":true,"kind":"HorizontalPodAutoscaler","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"shortNames":["hpa"],"categories":["all"],"storageVersionHash":"qwQve8ut294="},{"name":"horizontalpodautoscalers/status","singularName":"","namespaced":true,"kind":"HorizontalPodAutoscaler","verbs":["get","patch","update"]}]}
I0918 11:35:35.190524  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"metrics.eks.amazonaws.com/v1","resources":[{"name":"etcd","singularName":"etcd","namespaced":false,"kind":"ETCD","verbs":[]},{"name":"etcd/metrics","singularName":"","namespaced":false,"kind":"ETCD","verbs":["get"]},{"name":"kcm","singularName":"kcm","namespaced":false,"kind":"KCM","verbs":[]},{"name":"kcm/metrics","singularName":"","namespaced":false,"kind":"KCM","verbs":["get"]},{"name":"ksh","singularName":"ksh","namespaced":false,"kind":"KSH","verbs":[]},{"name":"ksh/metrics","singularName":"","namespaced":false,"kind":"KSH","verbs":["get"]},{"name":"ksh/resourcemetrics","singularName":"","namespaced":false,"kind":"KSH","verbs":["get"]}]}
I0918 11:35:35.486198  372046 request.go:1212] Response Body: {"kind":"APIResourceList","apiVersion":"v1","groupVersion":"scheduling.k8s.io/v1","resources":[{"name":"priorityclasses","singularName":"priorityclass","namespaced":false,"kind":"PriorityClass","verbs":["create","delete","deletecollection","get","list","patch","update","watch"],"shortNames":["pc"],"storageVersionHash":"1QwjyaZjj3Y="}]}
I0918 11:35:35.488191  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/metrics.k8s.io/v1beta1?timeout=32s
I0918 11:35:35.488239  372046 round_trippers.go:469] Request Headers:
I0918 11:35:35.488268  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:35.488292  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:35.793261  372046 round_trippers.go:574] Response Status: 503 Service Unavailable in 304 milliseconds
I0918 11:35:35.793326  372046 round_trippers.go:577] Response Headers:
I0918 11:35:35.793353  372046 round_trippers.go:580]     Content-Type: text/plain; charset=utf-8
I0918 11:35:35.793377  372046 round_trippers.go:580]     X-Content-Type-Options: nosniff
I0918 11:35:35.793392  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:35.793412  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:35.793440  372046 round_trippers.go:580]     Content-Length: 20
I0918 11:35:35.793451  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:35 GMT
I0918 11:35:35.793464  372046 round_trippers.go:580]     Audit-Id: 10641cf7-8471-4d1d-b700-d4e73e5562e4
I0918 11:35:35.793482  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:35.794042  372046 request.go:1212] Response Body: service unavailable
I0918 11:35:35.794785  372046 request.go:1411] body was not decodable (unable to check for Status): couldn't get version/kind; json parse error: json: cannot unmarshal string into Go value of type struct { APIVersion string "json:\"apiVersion,omitempty\""; Kind string "json:\"kind,omitempty\"" }
E0918 11:35:35.794840  372046 memcache.go:121] couldn't get resource list for metrics.k8s.io/v1beta1: the server is currently unable to handle the request
I0918 11:35:35.794903  372046 cached_discovery.go:84] skipped caching discovery info due to the server is currently unable to handle the request
I0918 11:35:35.796026  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/metrics.k8s.io/v1beta1?timeout=32s
I0918 11:35:35.796057  372046 round_trippers.go:469] Request Headers:
I0918 11:35:35.796081  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:35.796099  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:36.099679  372046 round_trippers.go:574] Response Status: 503 Service Unavailable in 303 milliseconds
I0918 11:35:36.099718  372046 round_trippers.go:577] Response Headers:
I0918 11:35:36.099732  372046 round_trippers.go:580]     Content-Length: 20
I0918 11:35:36.099739  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:35 GMT
I0918 11:35:36.099745  372046 round_trippers.go:580]     Audit-Id: 95074c42-80c0-4b8e-a683-c308702ab137
I0918 11:35:36.099750  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:36.099755  372046 round_trippers.go:580]     Content-Type: text/plain; charset=utf-8
I0918 11:35:36.099760  372046 round_trippers.go:580]     X-Content-Type-Options: nosniff
I0918 11:35:36.099764  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:36.099769  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:36.100008  372046 request.go:1212] Response Body: service unavailable
I0918 11:35:36.100335  372046 request.go:1411] body was not decodable (unable to check for Status): couldn't get version/kind; json parse error: json: cannot unmarshal string into Go value of type struct { APIVersion string "json:\"apiVersion,omitempty\""; Kind string "json:\"kind,omitempty\"" }
E0918 11:35:36.100358  372046 memcache.go:121] couldn't get resource list for metrics.k8s.io/v1beta1: the server is currently unable to handle the request
I0918 11:35:36.100371  372046 cached_discovery.go:84] skipped caching discovery info due to the server is currently unable to handle the request
I0918 11:35:36.100397  372046 shortcut.go:100] Error loading discovery information: unable to retrieve the complete list of server APIs: metrics.k8s.io/v1beta1: the server is currently unable to handle the request
I0918 11:35:36.100887  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/apis/metrics.k8s.io/v1beta1?timeout=32s
I0918 11:35:36.100903  372046 round_trippers.go:469] Request Headers:
I0918 11:35:36.100917  372046 round_trippers.go:473]     Accept: application/json, */*
I0918 11:35:36.100929  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:36.408729  372046 round_trippers.go:574] Response Status: 503 Service Unavailable in 307 milliseconds
I0918 11:35:36.408782  372046 round_trippers.go:577] Response Headers:
I0918 11:35:36.408805  372046 round_trippers.go:580]     Audit-Id: b9731c41-64f5-4f0b-bfc5-64319a44481f
I0918 11:35:36.408820  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:36.408832  372046 round_trippers.go:580]     Content-Type: text/plain; charset=utf-8
I0918 11:35:36.408847  372046 round_trippers.go:580]     X-Content-Type-Options: nosniff
I0918 11:35:36.408858  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:36.408866  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:36.408876  372046 round_trippers.go:580]     Content-Length: 20
I0918 11:35:36.408887  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:36 GMT
I0918 11:35:36.409330  372046 request.go:1212] Response Body: service unavailable
I0918 11:35:36.409909  372046 request.go:1411] body was not decodable (unable to check for Status): couldn't get version/kind; json parse error: json: cannot unmarshal string into Go value of type struct { APIVersion string "json:\"apiVersion,omitempty\""; Kind string "json:\"kind,omitempty\"" }
E0918 11:35:36.409954  372046 memcache.go:121] couldn't get resource list for metrics.k8s.io/v1beta1: the server is currently unable to handle the request
I0918 11:35:36.409978  372046 cached_discovery.go:84] skipped caching discovery info due to the server is currently unable to handle the request
I0918 11:35:36.411879  372046 round_trippers.go:463] GET https://AD65559222FB956A296ED8FD9E7A3C65.gr7.us-east-1.eks.amazonaws.com/api/v1/namespaces/developers-team/pods?limit=500
I0918 11:35:36.411902  372046 round_trippers.go:469] Request Headers:
I0918 11:35:36.411920  372046 round_trippers.go:473]     Accept: application/json;as=Table;v=v1;g=meta.k8s.io,application/json;as=Table;v=v1beta1;g=meta.k8s.io,application/json
I0918 11:35:36.411933  372046 round_trippers.go:473]     User-Agent: kubectl/v1.28.15 (linux/amd64) kubernetes/8418565
I0918 11:35:36.715586  372046 round_trippers.go:574] Response Status: 200 OK in 303 milliseconds
I0918 11:35:36.715660  372046 round_trippers.go:577] Response Headers:
I0918 11:35:36.715719  372046 round_trippers.go:580]     X-Kubernetes-Pf-Prioritylevel-Uid: ac2ab52c-064b-4e77-a3ab-345d3949efdc
I0918 11:35:36.715749  372046 round_trippers.go:580]     Content-Length: 3203
I0918 11:35:36.715766  372046 round_trippers.go:580]     Date: Fri, 18 Sep 2026 07:35:36 GMT
I0918 11:35:36.715781  372046 round_trippers.go:580]     Audit-Id: 1c07fb26-eb28-4d0a-a474-f24db161bf1d
I0918 11:35:36.715795  372046 round_trippers.go:580]     Cache-Control: no-cache, private
I0918 11:35:36.715807  372046 round_trippers.go:580]     Content-Type: application/json
I0918 11:35:36.715818  372046 round_trippers.go:580]     X-Kubernetes-Pf-Flowschema-Uid: 6ef5c024-ac21-4c40-8a3b-c5e8ec318f3b
I0918 11:35:36.716333  372046 request.go:1212] Response Body: {"kind":"Table","apiVersion":"meta.k8s.io/v1","metadata":{"resourceVersion":"56837"},"columnDefinitions":[{"name":"Name","type":"string","format":"name","description":"Name must be unique within a namespace. Is required when creating resources, although some resources may allow a client to request the generation of an appropriate name automatically. Name is primarily intended for creation idempotence and configuration definition. Cannot be updated. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names#names","priority":0},{"name":"Ready","type":"string","format":"","description":"The aggregate readiness state of this pod for accepting traffic.","priority":0},{"name":"Status","type":"string","format":"","description":"The aggregate status of the containers in this pod.","priority":0},{"name":"Restarts","type":"string","format":"","description":"The number of times the containers in this pod have been restarted and when the last container in this pod has restarted.","priority":0},{" [truncated 2179 chars]
No resources found in developers-team namespace.
test@test:~$