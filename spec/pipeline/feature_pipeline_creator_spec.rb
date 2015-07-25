require 'spec_helper'
require 'pipeline/feature_pipeline_creator'

describe Pipeline::FeaturePipelineCreator do
  subject(:pipeline_creator) do
    Pipeline::FeaturePipelineCreator.new(
      branch_name: 'features/branch',
      iaas_type: 'some-iaas',
    )
  end

  subject(:aws_pipeline_creator) do
    Pipeline::FeaturePipelineCreator.new(
      branch_name: 'features/branch',
      iaas_type: 'aws',
    )
  end

  subject(:vcloud_pipeline_creator) do
    Pipeline::FeaturePipelineCreator.new(
      branch_name: 'features/branch',
      iaas_type: 'vcloud',
    )
  end

  let(:file) { instance_double(File) }
  let(:handcraft) do
    <<YAML
---
metadata_version: '1.5'
provides_product_versions:
- name: cf
  version: 1.5.0.0
product_version: &product_version "1.5.0.0$PRERELEASE_VERSION$"
label: Pivotal Elastic Runtime
YAML
  end

  before do
    allow(File).to receive(:open).and_yield(file)
    allow(file).to receive(:write)
    allow(FileUtils).to receive(:mkdir_p)
    allow(File).to receive(:read).and_return('')
    allow(File).to receive(:read).and_return(handcraft)
  end

  it 'has a constructor that takes two arguments' do
    expect(pipeline_creator).to be_a(Pipeline::FeaturePipelineCreator)
  end

  context 'clean install pipeline' do
    before do
      allow(pipeline_creator).to receive(:add_vcloud_delete_installation_tasks)
    end

    it 'puts the rendered content from the template into the configuration file' do
      expect(File).to(
        receive(:read)
          .with('ci/pipelines/feature-pipeline-template.yml')
          .and_return('key: "{{branch_name}} {{iaas_type}} {{om_version}} {{ert_version}}"')
      )
      expect(file).to receive(:write).with("---\nkey: features/branch some-iaas 1.5 1.5\n")

      pipeline_creator.create_pipeline
    end

    it 'creates the directory for the pipeline config file' do
      expect(FileUtils).to receive(:mkdir_p).with('ci/pipelines/features/branch')

      pipeline_creator.create_pipeline
    end

    it 'creates the pipeline configuration file with the correct name' do
      expect(File).to receive(:open).with('ci/pipelines/features/branch/pipeline.yml', 'w')

      pipeline_creator.create_pipeline
    end

    it 'will not add aws specific tasks' do
      allow(File).to receive(:read).with('ci/pipelines/feature-pipeline-template.yml')
                       .and_return("---\n key: value")
      expect(pipeline_creator).to_not receive(:add_aws_configure_tasks)
      pipeline_creator.create_pipeline
    end

    it 'will not add vcloud specific tasks' do
      allow(File).to receive(:read).with('ci/pipelines/feature-pipeline-template.yml')
                       .and_return("---\n key: value")
      expect(pipeline_creator).to_not receive(:add_vcloud_delete_installation_tasks)
      pipeline_creator.create_pipeline
    end

    context 'aws iaas pipeline' do
      it 'adds aws specific tasks' do
        allow(File).to receive(:read).with('ci/pipelines/feature-pipeline-template.yml')
                         .and_return("---\n key: value")
        expect(aws_pipeline_creator).to receive(:add_aws_configure_tasks).with(
          {'key' => 'value'},
          'aws-external-config.yml'
        )
        aws_pipeline_creator.create_pipeline
      end
    end

    context 'vcloud iaas pipeline' do
      it 'adds vcloud specific tasks' do
        allow(File).to receive(:read).with('ci/pipelines/feature-pipeline-template.yml')
                         .and_return("---\n key: value")
        expect(vcloud_pipeline_creator).to receive(:add_vcloud_delete_installation_tasks).with(
            {'key' => 'value'},

          )
        vcloud_pipeline_creator.create_pipeline
      end
    end
  end

  context 'upgrade pipeline' do
    let(:ert_initial_full_version) { '1.4.2.0' }
    let(:om_initial_full_version) { '1.4.2.0' }
    before do
      allow(pipeline_creator).to receive(:add_aws_configure_tasks)
      allow(pipeline_creator).to receive(:add_vcloud_delete_installation_tasks)
    end

    it 'puts the rendered content from the upgrade template into the configuration file' do
      expect(File).to(
        receive(:read)
          .with('ci/pipelines/feature-upgrade-template.yml')
          .and_return('key: "{{branch_name}} {{iaas_type}} {{om_version}} {{ert_version}}' \
              ' {{om_initial_full_version}} {{ert_initial_full_version}}' \
              ' {{om_initial_version}} {{ert_initial_version}}"')
      )
      expect(file).to receive(:write).with("---\nkey: features/branch some-iaas 1.5 1.5 1.4.2.0 1.4.2.0 1.4 1.4\n")

      pipeline_creator.create_upgrade_pipeline(
        ert_initial_full_version: ert_initial_full_version,
        om_initial_full_version: om_initial_full_version
      )
    end

    it 'creates the directory for the pipeline config file' do
      expect(FileUtils).to receive(:mkdir_p).with('ci/pipelines/features/branch')

      pipeline_creator.create_upgrade_pipeline(
        ert_initial_full_version: ert_initial_full_version,
        om_initial_full_version: om_initial_full_version
      )
    end

    it 'creates the pipeline configuration file with the correct name' do
      expect(File).to receive(:open).with('ci/pipelines/features/branch/pipeline.yml', 'w')

      pipeline_creator.create_upgrade_pipeline(
        ert_initial_full_version: ert_initial_full_version,
        om_initial_full_version: om_initial_full_version
      )
    end

    it 'will not add aws specific tasks' do
      allow(File).to receive(:read).with('ci/pipelines/feature-upgrade-template.yml')
                       .and_return("---\n key: value")
      expect(pipeline_creator).to_not receive(:add_aws_configure_tasks)
      pipeline_creator.create_upgrade_pipeline(
        ert_initial_full_version: ert_initial_full_version,
        om_initial_full_version: om_initial_full_version
      )
    end

    it 'will not add vcloud specific tasks' do
      allow(File).to receive(:read).with('ci/pipelines/feature-upgrade-template.yml')
                       .and_return("---\n key: value")
      expect(pipeline_creator).to_not receive(:add_vcloud_delete_installation_tasks)
      pipeline_creator.create_upgrade_pipeline(
        ert_initial_full_version: ert_initial_full_version,
        om_initial_full_version: om_initial_full_version
      )
    end

    context 'aws iaas pipeline' do
      it 'adds aws specific tasks' do
        allow(File).to receive(:read).with('ci/pipelines/feature-upgrade-template.yml')
                         .and_return("---\n key: value")
        expect(aws_pipeline_creator).to receive(:add_aws_configure_tasks).with(
            {'key' => 'value'},
            'aws-external-config-upgrade.yml'
          )
        aws_pipeline_creator.create_upgrade_pipeline(
          ert_initial_full_version: ert_initial_full_version,
          om_initial_full_version: om_initial_full_version
        )
      end
    end

    context 'vcloud iaas pipeline' do
      it 'adds vcloud specific tasks' do
        allow(File).to receive(:read).with('ci/pipelines/feature-upgrade-template.yml')
                         .and_return("---\n key: value")
        expect(vcloud_pipeline_creator).to receive(:add_vcloud_delete_installation_tasks).with(
            {'key' => 'value'},

          )
        vcloud_pipeline_creator.create_upgrade_pipeline(
          ert_initial_full_version: ert_initial_full_version,
          om_initial_full_version: om_initial_full_version
        )
      end
    end
  end

  it 'returns the product version from the handcraft.yml file' do
    expect(File).to receive(:read).with('metadata_parts/handcraft.yml').and_return(handcraft)
    expect(pipeline_creator.product_version).to eq('1.5')
  end

  context 'when the first product is not cf' do
    let(:handcraft) do
      <<YAML
---
metadata_version: '1.5'
provides_product_versions:
- name: foo
  version: 1.5.0.0
product_version: &product_version "1.5.0.0$PRERELEASE_VERSION$"
label: Pivotal Elastic Runtime
YAML
    end

    it 'raises' do
      expect { pipeline_creator.product_version }.to raise_error('unknown product')
    end
  end
end
