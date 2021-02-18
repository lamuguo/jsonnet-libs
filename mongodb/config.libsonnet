{
  _config+:: {
    port: 27017,
    name: 'mongodb',
    namespace: 'default',
    image: 'percona/percona-server-mongodb:3.6.3',
    MONGO_INITDB_ROOT_USERNAME: 'root',
    MONGO_INITDB_ROOT_PASSWORD: 'root',
    storage: '200Mi',
    cpuRequest: '0.2',
    cpuLimit: '1',
    memoryRequest: '500Mi',
    memoryLimit: '4Gi',
  },
}
