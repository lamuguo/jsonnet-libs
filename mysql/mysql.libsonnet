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
  local configmapName = $._config.name + 'config',

  local envs = [
    {
      name: 'MYSQL_ROOT_PASSWORD',
      value: $._config.MYSQL_ROOT_PASSWORD,
    },
  ],

  local volumeMounts = [
    volumeMount.new('data', '/var/lib/mysql') + volumeMount.withSubPath('mysql'),
    volumeMount.new('config', '/etc/mysql'),
  ],

  local volumes = [
    {
      name: 'data',
      persistentVolumeClaim: {
        claimName: pvcName,
      },
    },
  ],


  mysql_deployment: deployment.new(
                      name=$._config.name,
                      replicas=1,
                      containers=[
                        container.new($._config.name, $._config.image) +
                        container.withPorts([port.new('mysql', $._config.port)]) +
                        container.withEnv(envs) +
                        container.withVolumeMounts(volumeMounts) +
                        $.util.resourcesRequests($._config.cpuRequest, $._config.memoryRequest) +
                        $.util.resourcesLimits($._config.cpuLimit, $._config.memoryLimit),
                      ],
                    ) +
                    deployment.mixin.metadata.withNamespace($._config.namespace) +
                    deployment.mixin.spec.template.spec.withVolumesMixin([
                      volume.fromPersistentVolumeClaim('data', pvcName),
                      volume.fromConfigMap('config', configmapName),
                    ]) +
                    deployment.spec.template.spec.withInitContainers(
                      [
                        container.new('init', 'alpine:3.6') +
                        container.withCommand([
                          'sh',
                          '-c',
                          'chown -R 1001:1001 /var/lib/mysql',
                        ]) +
                        container.withVolumeMounts(volumeMounts),
                      ]
                    ),
  mysql_service: $.util.serviceFor(self.mysql_deployment) +
                 service.mixin.metadata.withNamespace($._config.namespace),

  mysql_storage: pvc.new() + pvc.mixin.metadata.withNamespace($._config.namespace) +
                 pvc.mixin.metadata.withName(pvcName) +
                 pvc.mixin.spec.withStorageClassName('ebs-sc') +
                 pvc.mixin.spec.withAccessModes('ReadWriteOnce') +
                 pvc.mixin.spec.resources.withRequests({ storage: $._config.storage }),
  mysql_config: configMap.new(configmapName) +
                configMap.mixin.metadata.withNamespace($._config.namespace) +
                configMap.withData({ 'my.cnf': (importstr 'my.cnf') }),

}
