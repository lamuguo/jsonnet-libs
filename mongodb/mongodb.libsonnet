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

  local envs = [
    {
      name: 'MONGO_INITDB_ROOT_USERNAME',
      value: $._config.MONGO_INITDB_ROOT_USERNAME,
    },
    {
      name: 'MONGO_INITDB_ROOT_PASSWORD',
      value: $._config.MONGO_INITDB_ROOT_PASSWORD,
    },
  ],


  local volumeMounts = [
    volumeMount.new('data', '/data/db'),

  ],
  local volumes = [
    {
      name: 'data',
      persistentVolumeClaim: {
        claimName: pvcName,
      },
    },
  ],

  mongodb_deployment: deployment.new(
                        name=$._config.name,
                        replicas=1,
                        containers=[
                          container.new($._config.name, $._config.image) +
                          container.withPorts([port.new('mongodb', $._config.port)]) +
                          container.withEnv(envs) +
                          container.withVolumeMounts(volumeMounts) +
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
                            'chown -R 1001:1001 /data/db',
                          ]) +
                          container.withVolumeMounts(volumeMounts),
                        ]
                      ),
  mongodb_service: $.util.serviceFor(self.mongodb_deployment) +
                   service.mixin.metadata.withNamespace($._config.namespace),

  mongodb_storage: pvc.new() + pvc.mixin.metadata.withNamespace($._config.namespace) +
                   pvc.mixin.metadata.withName(pvcName) +
                   pvc.mixin.spec.withStorageClassName('ebs-sc') +
                   pvc.mixin.spec.withAccessModes('ReadWriteOnce') +
                   pvc.mixin.spec.resources.withRequests({ storage: $._config.storage }),


}
