(import 'ksonnet-util/kausal.libsonnet') + (import 'config.libsonnet') +
{
  local deployment = $.apps.v1.deployment,
  local container = $.core.v1.container,
  local port = $.core.v1.containerPort,
  local service = $.core.v1.service,
  local pvc = $.core.v1.persistentVolumeClaim,
  local volumeMount = $.core.v1.volumeMount,
  local volume = $.core.v1.volume,
  local secret = $.core.v1.secret,
  local envFrom = container.envFromType,
  local pvcName = $._config.name + '-pvc',

  local volumeMounts = [
    volumeMount.new('data', '/data'),
  ],


  local envs = [
    {
      name: 'DRONE_SERVER_HOST',
      value: $._config.DRONE_SERVER_HOST,
    },
    {
      name: 'DRONE_GITHUB_CLIENT_ID',
      value: $._config.DRONE_GITHUB_CLIENT_ID,
    },
    {
      name: 'DRONE_GITHUB_CLIENT_SECRET',
      value: $._config.DRONE_GITHUB_CLIENT_SECRET,
    },
    {
      name: 'DRONE_RPC_SECRET',
      value: $._config.DRONE_RPC_SECRET,
    },
    {
      name: 'DRONE_SERVER_PROTO',
      value: $._config.DRONE_SERVER_PROTO,
    },
    {
      name: 'DRONE_SERVER_PORT',
      value: $._config.DRONE_SERVER_PORT,
    },
    {
      name: 'DRONE_LOGS_DEBUG',
      value: $._config.DRONE_LOGS_DEBUG,
    },
    {
      name: 'DRONE_LOGS_PRETTY',
      value: $._config.DRONE_LOGS_PRETTY,
    },
    {
      name: 'DRONE_LOGS_COLOR',
      value: $._config.DRONE_LOGS_COLOR,
    },
    {
      name: 'DRONE_AGENTS_ENABLED',
      value: $._config.DRONE_AGENTS_ENABLED,
    },
    {
      name: 'DRONE_GITHUB_SERVER',
      value: $._config.DRONE_GITHUB_SERVER,
    },
    {
      name: 'DRONE_USER_FILTER',
      value: $._config.DRONE_USER_FILTER,
    },
  ],

  local volumes = [
    {
      name: 'data',
      persistentVolumeClaim: {
        claimName: pvcName,
      },
    },
  ],

  drone_server_deployment: deployment.new(
                             name=$._config.name,
                             replicas=1,
                             containers=[
                               container.new($._config.name, $._config.image) +
                               container.withPorts([port.new('http', $._config.port)]) +
                               container.withVolumeMounts(volumeMounts) +
                               container.withEnv(envs) +
                               $.util.resourcesRequests($._config.cpuRequest, $._config.memoryRequest) +
                               $.util.resourcesLimits($._config.cpuLimit, $._config.memoryLimit),
                             ],
                           ) +
                           deployment.mixin.metadata.withNamespace($._config.namespace) +
                           deployment.mixin.spec.template.spec.withVolumesMixin([
                             volume.fromPersistentVolumeClaim('data', pvcName),
                           ]) +
                           deployment.mixin.spec.template.metadata.withAnnotationsMixin(
                             {
                               'vault.security.banzaicloud.io/vault-addr': $._config.VAULT_SERVICE_ADDR,
                               'vault.security.banzaicloud.io/vault-tls-secret': $._config.VAULT_TLS_SECRET,
                             }
                           ),
  drone_server_service: $.util.serviceFor(self.drone_server_deployment) +
                        service.mixin.metadata.withNamespace($._config.namespace),

  drone_server_storage: pvc.new() + pvc.mixin.metadata.withNamespace($._config.namespace) +
                        pvc.mixin.metadata.withName(pvcName) +
                        pvc.mixin.spec.withStorageClassName('ebs-sc') +
                        pvc.mixin.spec.withAccessModes('ReadWriteOnce') +
                        pvc.mixin.spec.resources.withRequests({ storage: $._config.storage }),

}
