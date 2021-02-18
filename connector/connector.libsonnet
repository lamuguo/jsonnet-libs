(import 'ksonnet-util/kausal.libsonnet') + (import 'config.libsonnet') +
{
  local deployment = $.apps.v1.deployment,
  local container = $.core.v1.container,
  local port = $.core.v1.containerPort,
  local service = $.core.v1.service,
  local pvc = $.core.v1.persistentVolumeClaim,
  local volumeMount = $.core.v1.volumeMount,
  local volume = $.core.v1.volume,

  local pvcName = $._config.name + '-pvc',

  local volumeMounts = [
    volumeMount.new('data', '/kafka/connect'),

  ],
  local envs = [
    {
      name: 'BOOTSTRAP_SERVERS',
      value: $._config.BOOTSTRAP_SERVERS,
    },
    {
      name: 'GROUP_ID',
      value: $._config.GROUP_ID,
    },
    {
      name: 'OFFSET_FLUSH_TIMEOUT_MS',
      value: $._config.OFFSET_FLUSH_TIMEOUT_MS,
    },
    {
      name: 'OFFSET_FLUSH_INTERVAL_MS',
      value: $._config.OFFSET_FLUSH_INTERVAL_MS,
    }
    {
      name: 'KAFKA_HEAP_OPTS',
      value: $._config.KAFKA_HEAP_OPTS,
    },
    {
      name: 'CONFIG_STORAGE_TOPIC',
      value: $._config.CONFIG_STORAGE_TOPIC,
    },
    {
      name: 'OFFSET_STORAGE_TOPIC',
      value: $._config.OFFSET_STORAGE_TOPIC,
    },
    {
      name: 'STATUS_STORAGE_TOPIC',
      value: $._config.STATUS_STORAGE_TOPIC,
    },
    {
      name: 'CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR',
      value: $._config.CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR,
    },
    {
      name: 'CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR',
      value: $._config.CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR,
    },
    {
      name: 'CONNECT_STATUS_STORAGE_REPLICATION_FACTOR',
      value: $._config.CONNECT_STATUS_STORAGE_REPLICATION_FACTOR,
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

  connector_deployment: deployment.new(
                          name=$._config.name,
                          replicas=1,
                          containers=[
                            container.new($._config.name, $._config.image) +
                            container.withPorts([port.new('connector', $._config.port)]) +
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
                        deployment.spec.template.spec.withInitContainers(
                          [
                            container.new('init', 'alpine:3.6') +
                            container.withCommand([
                              'sh',
                              '-c',
                              'chown -R 1001:1001 /kafka/connect',
                            ]) +
                            container.withVolumeMounts(volumeMounts),
                          ]
                        ),
  connector_service: $.util.serviceFor(self.connector_deployment) +
                     service.mixin.metadata.withNamespace($._config.namespace),

  connector_storage: pvc.new() + pvc.mixin.metadata.withNamespace($._config.namespace) +
                     pvc.mixin.metadata.withName(pvcName) +
                     pvc.mixin.spec.withStorageClassName('ebs-sc') +
                     pvc.mixin.spec.withAccessModes('ReadWriteOnce') +
                     pvc.mixin.spec.resources.withRequests({ storage: $._config.storage }),

}
