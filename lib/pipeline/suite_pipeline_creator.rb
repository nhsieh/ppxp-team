require 'mustache'
require 'yaml'
require 'pipeline/iaas_specific_task_adder'

module Pipeline
  class SuitePipelineCreator < Mustache
    include IaasSpecificTaskAdder

    def environment_pool
      case pipeline_name
      when 'internetless'
        pipeline_name
      when 'aws-upgrade'
        'aws-east'
      else
        iaas_type
      end
    end

    def upgrade_pipeline_jobs(pipeline_name:, iaas_type:)
      pipeline_yaml = pipeline_jobs(
        pipeline_name: pipeline_name,
        iaas_type: iaas_type,
        template_path: File.join(template_directory, 'upgrade.yml')
      )

      add_aws_configure_tasks(pipeline_yaml, 'aws-external-config-upgrade.yml') if iaas_type == 'aws'

      pipeline_yaml
    end

    def clean_pipeline_jobs(pipeline_name:, iaas_type:)
      pipeline_yaml = pipeline_jobs(
        pipeline_name: pipeline_name,
        iaas_type: iaas_type,
        template_path: File.join(template_directory, 'clean.yml')
      )

      add_aws_configure_tasks(pipeline_yaml, 'aws-external-config.yml') if iaas_type == 'aws'
      add_verify_internetless_job(pipeline_yaml) if pipeline_name == 'internetless'

      pipeline_yaml
    end

    attr_reader :pipeline_name, :iaas_type

    private

    def pipeline_jobs(pipeline_name:, iaas_type:, template_path:)
      @pipeline_name = pipeline_name
      @iaas_type = iaas_type

      pipeline_yaml = YAML.load(render(File.read(template_path)))

      add_vcloud_delete_installation_tasks(pipeline_yaml) if iaas_type == 'vcloud'
      pipeline_yaml
    end
  end
end
