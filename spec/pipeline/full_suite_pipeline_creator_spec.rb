require 'spec_helper'
require 'pipeline/full_suite_pipeline_creator'

describe Pipeline::FullSuitePipelineCreator do
  subject(:pipeline_creator) do
    Pipeline::FullSuitePipelineCreator.new
  end
  let(:file) { instance_double(File) }

  let(:ert_general) do
    <<YAML
---
resources:
  - name: some-resource
    type: git
  - name: another-resource
    type: s3
    source:
      some_key: just-a-key
jobs:
  - name: a-generic-job
    plan:
      - get: a-get-task
        resource: some-resource
      - task: a-generic-task
YAML
  end

  let(:template) do
    <<YAML
---
jobs:
  - name: destroy-environment-{{pipeline_name}}
    plan:
      - get: environment
        resource: environment-{{environment_pool}}
        trigger: true
        passed: [claim-environment-{{pipeline_name}}]
      - task: destroy
        tags: [{{iaas_type}}]
        file: p-runtime/ci/jobs/destroy-environment.yml
  - name: configure-ert-{{pipeline_name}}
    plan:
      - task: some-task
        tags: [{{iaas_type}}]
        resource: environment-{{environment_pool}}
  - name: another-job-{{pipeline_name}}
    plan:
      - task: another-task
        tags: [{{iaas_type}}]
        resource: environment-{{environment_pool}}
YAML
  end

  let(:aws_extra_config) do
    <<YAML
- task: some-aws-task
  tags: aws
YAML
  end

  let(:aws_extra_config_upgrade) do
    <<YAML
- task: some-aws-upgrade-task
  tags: aws
YAML
  end

  let(:vcloud_extra_config) do
    <<YAML
- task: some-vcloud-task
  tags: vcloud
- task: another-vcloud-task
  tags: vcloud
YAML
  end

  before do
    allow(File).to receive(:read).and_return(template)
    allow(File).to receive(:read).with('ci/pipelines/release/template/ert.yml')
      .and_return(ert_general)
    allow(File).to receive(:read).with('ci/pipelines/release/template/aws-external-config.yml')
      .and_return(aws_extra_config)
    allow(File).to receive(:read).with('ci/pipelines/release/template/aws-external-config-upgrade.yml')
      .and_return(aws_extra_config_upgrade)
    allow(File).to receive(:read).with('ci/pipelines/release/template/vcloud-delete-installation.yml')
      .and_return(vcloud_extra_config)
  end

  it 'has a constructor that takes no arguments' do
    expect(pipeline_creator).to be_a(Pipeline::FullSuitePipelineCreator)
  end

  describe '#clean_pipeline_jobs' do
    it 'returns vsphere clean pipeline jobs using template/clean.yml' do
      expect(File).to receive(:read).with('ci/pipelines/release/template/clean.yml')
      vsphere_clean_pipeline_jobs = pipeline_creator.clean_pipeline_jobs(
        pipeline_name: 'vsphere-clean',
        iaas_type: 'vsphere'
      )['jobs']

      expect(vsphere_clean_pipeline_jobs[1]['name']).to eq('configure-ert-vsphere-clean')
      expect(vsphere_clean_pipeline_jobs[1]['plan'].first['tags']).to eq(['vsphere'])
      expect(vsphere_clean_pipeline_jobs[1]['plan'].first['resource']).to eq('environment-vsphere')
    end

    it 'returns aws clean pipeline jobs using template/clean.yml' do
      expect(File).to receive(:read).with('ci/pipelines/release/template/clean.yml')
      aws_clean_pipeline_jobs = pipeline_creator.clean_pipeline_jobs(
        pipeline_name: 'aws-clean',
        iaas_type: 'aws'
      )['jobs']

      expect(aws_clean_pipeline_jobs[1]['name']).to eq('configure-ert-aws-clean')
      expect(aws_clean_pipeline_jobs[1]['plan'].first['tags']).to eq(['aws'])
      expect(aws_clean_pipeline_jobs[1]['plan'].first['resource']).to eq('environment-aws')

      expect(aws_clean_pipeline_jobs[1]['plan'][1]).to eq('task' => 'some-aws-task', 'tags' => 'aws')
    end

    it 'returns internetless clean pipeline jobs using template/clean.yml' do
      expect(File).to receive(:read).with('ci/pipelines/release/template/clean.yml')
      internetless_pipeline_jobs = pipeline_creator.clean_pipeline_jobs(
        pipeline_name: 'internetless',
        iaas_type: 'vsphere'
      )['jobs']

      expect(internetless_pipeline_jobs[1]['name']).to eq('configure-ert-internetless')
      expect(internetless_pipeline_jobs[1]['plan'].first['tags']).to eq(['vsphere'])
      expect(internetless_pipeline_jobs[1]['plan'].first['resource']).to eq('environment-internetless')
    end

    it 'returns vcloud clean pipeline jobs using template/clean.yml' do
      expect(File).to receive(:read).with('ci/pipelines/release/template/clean.yml')
      vcloud_clean_pipeline_jobs = pipeline_creator.clean_pipeline_jobs(
        pipeline_name: 'vcloud',
        iaas_type: 'vcloud'
      )['jobs']

      expect(vcloud_clean_pipeline_jobs[1]['name']).to eq('configure-ert-vcloud')
      expect(vcloud_clean_pipeline_jobs[1]['plan'].first['tags']).to eq(['vcloud'])
      expect(vcloud_clean_pipeline_jobs[1]['plan'].first['resource']).to eq('environment-vcloud')

      expect(vcloud_clean_pipeline_jobs.first['plan'][1]).to eq('task' => 'some-vcloud-task', 'tags' => 'vcloud')
      expect(vcloud_clean_pipeline_jobs.first['plan'][2]).to eq('task' => 'another-vcloud-task', 'tags' => 'vcloud')
    end
  end

  describe '#upgrade_pipeline_jobs' do
    it 'returns vsphere upgrade pipeline jobs using template/upgrade.yml' do
      expect(File).to receive(:read).with('ci/pipelines/release/template/upgrade.yml')
      vsphere_upgrade_pipeline_jobs = pipeline_creator.upgrade_pipeline_jobs(
        pipeline_name: 'vsphere-upgrade',
        iaas_type: 'vsphere'
      )['jobs']

      expect(vsphere_upgrade_pipeline_jobs[1]['name']).to eq('configure-ert-vsphere-upgrade')
      expect(vsphere_upgrade_pipeline_jobs[1]['plan'].first['tags']).to eq(['vsphere'])
      expect(vsphere_upgrade_pipeline_jobs[1]['plan'].first['resource']).to eq('environment-vsphere')
    end

    it 'returns aws upgrade pipeline jobs using template/upgrade.yml' do
      expect(File).to receive(:read).with('ci/pipelines/release/template/upgrade.yml')
      aws_upgrade_pipeline_jobs = pipeline_creator.upgrade_pipeline_jobs(
        pipeline_name: 'aws-upgrade',
        iaas_type: 'aws'
      )['jobs']

      expect(aws_upgrade_pipeline_jobs[1]['name']).to eq('configure-ert-aws-upgrade')
      expect(aws_upgrade_pipeline_jobs[1]['plan'].first['tags']).to eq(['aws'])
      expect(aws_upgrade_pipeline_jobs[1]['plan'].first['resource']).to eq('environment-aws-east')

      expect(aws_upgrade_pipeline_jobs[1]['plan'][1]).to eq('task' => 'some-aws-upgrade-task', 'tags' => 'aws')
    end

    it 'returns vcloud upgrade pipeline jobs using template/upgrade.yml' do
      expect(File).to receive(:read).with('ci/pipelines/release/template/upgrade.yml')
      vcloud_upgrade_pipeline_jobs = pipeline_creator.upgrade_pipeline_jobs(
        pipeline_name: 'vcloud',
        iaas_type: 'vcloud'
      )['jobs']

      expect(vcloud_upgrade_pipeline_jobs[1]['name']).to eq('configure-ert-vcloud')
      expect(vcloud_upgrade_pipeline_jobs[1]['plan'].first['tags']).to eq(['vcloud'])
      expect(vcloud_upgrade_pipeline_jobs[1]['plan'].first['resource']).to eq('environment-vcloud')

      expect(vcloud_upgrade_pipeline_jobs.first['plan'][1]).to eq('task' => 'some-vcloud-task', 'tags' => 'vcloud')
      expect(vcloud_upgrade_pipeline_jobs.first['plan'][2]).to eq('task' => 'another-vcloud-task', 'tags' => 'vcloud')
    end
  end

  describe '#environment_pool' do
    it 'returns the pipeline name when internetless' do
      pipeline_creator.clean_pipeline_jobs(pipeline_name: 'internetless', iaas_type: 'some-iaas-type')

      expect(pipeline_creator.environment_pool).to eq('internetless')
    end

    it 'returns the iaas_type by default' do
      pipeline_creator.clean_pipeline_jobs(pipeline_name: 'blah', iaas_type: 'some-iaas-type')

      expect(pipeline_creator.environment_pool).to eq('some-iaas-type')
    end

    it 'returns aws-east when the pipeline is an aws-upgrade' do
      pipeline_creator.clean_pipeline_jobs(pipeline_name: 'aws-upgrade', iaas_type: 'some-iaas-type')

      expect(pipeline_creator.environment_pool).to eq('aws-east')
    end
  end

  describe '#full_suite_pipeline' do
    it 'makes the full suite' do
      full_pipeline_fixture = File.join(fixture_path, 'full-pipeline.yml')
      allow(File).to receive(:read).with(full_pipeline_fixture).and_call_original

      expect(File).to receive(:write).with('ci/pipelines/release/ert-1.5.yml', File.read(full_pipeline_fixture))

      pipeline_creator.full_suite_pipeline
    end
  end
end
