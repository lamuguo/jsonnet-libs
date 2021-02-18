(import 'ksonnet-util/kausal.libsonnet') + (import 'config.libsonnet') +
{
  local deployment = $.apps.v1.deployment,
  local container = $.core.v1.container,
  local port = $.core.v1.containerPort,
  local service = $.core.v1.service,
  local pvc = $.core.v1.persistentVolumeClaim,
  local volumeMount = $.core.v1.volumeMount,
  local configMap = $.core.v1.configMap,
  local volume = $.core.v1.volume,

  local pvcName = $._config.name + '-pvc',

  local volumeMounts = [
    volumeMount.new('data', '/tf'),

  ],

  local volumes = [
    {
      name: 'data',
      persistentVolumeClaim: {
        claimName: pvcName,
      },
    },
  ],

  jupyter_deployment: deployment.new(
                        name=$._config.name,
                        replicas=1,
                        containers=[
                          container.new($._config.name, $._config.image) +
                          container.withPorts([port.new('jupyter', $._config.port)]) +
                          container.withVolumeMounts(volumeMounts) +
                          $.util.resourcesRequests($._config.cpuRequest, $._config.memoryRequest) +
                          $.util.resourcesLimits($._config.cpuLimit, $._config.memoryLimit),
                        ],
                      ) +
                      deployment.mixin.metadata.withNamespace($._config.namespace) +
                      deployment.mixin.spec.template.spec.withVolumesMixin([
                        volume.fromPersistentVolumeClaim('data', pvcName),
                      ]),
  jupyter_service: $.util.serviceFor(self.jupyter_deployment) +
                   service.mixin.metadata.withNamespace($._config.namespace),

  jupyter_storage: pvc.new() + pvc.mixin.metadata.withNamespace($._config.namespace) +
                   pvc.mixin.metadata.withName(pvcName) +
                   pvc.mixin.spec.withStorageClassName('ebs-sc') +
                   pvc.mixin.spec.withAccessModes('ReadWriteOnce') +
                   pvc.mixin.spec.resources.withRequests({ storage: $._config.storage }),

}
