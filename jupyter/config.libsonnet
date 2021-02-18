{
  _config+:: {
    port: 8888,
    name: 'jupyter',
    namespace: 'default',
    image: 'ihealthlabs/jupyter:utc',
    storage: '100Gi',
    cpuRequest: '0.2',
    cpuLimit: '1',
    memoryRequest: '500Mi',
    memoryLimit: '2Gi',
  },
}
