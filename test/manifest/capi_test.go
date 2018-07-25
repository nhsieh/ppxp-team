package manifest_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/pivotal-cf/planitest"
)

var _ = Describe("CAPI", func() {
	type Job struct {
		InstanceGroup string
		Name          string
	}

	var (
		ccJobs   []Job
		manifest planitest.Manifest
	)

	Describe("common properties", func() {
		BeforeEach(func() {
			if productName == "srt" {
				ccJobs = []Job{
					{
						InstanceGroup: "control",
						Name:          "cloud_controller_ng",
					},
					{
						InstanceGroup: "control",
						Name:          "cloud_controller_worker",
					},
					{
						InstanceGroup: "control",
						Name:          "cloud_controller_clock",
					},
				}
			} else {
				ccJobs = []Job{
					{
						InstanceGroup: "cloud_controller",
						Name:          "cloud_controller_ng",
					},
					{
						InstanceGroup: "cloud_controller_worker",
						Name:          "cloud_controller_worker",
					},
					{
						InstanceGroup: "clock_global",
						Name:          "cloud_controller_clock",
					},
				}
			}
		})

		Context("when the Operator accepts the default values", func() {
			BeforeEach(func() {
				var err error
				manifest, err = product.RenderService.RenderManifest(nil)
				Expect(err).NotTo(HaveOccurred())
			})

			It("defaults logging level to info", func() {
				for _, job := range ccJobs {
					manifestJob, err := manifest.FindInstanceGroupJob(job.InstanceGroup, job.Name)
					Expect(err).NotTo(HaveOccurred())

					loggingLevel, err := manifestJob.Property("cc/logging_level")
					Expect(err).NotTo(HaveOccurred())
					Expect(loggingLevel).To(Equal(string("info")))
				}
			})

			It("configures a default health check timeout", func() {
				for _, job := range ccJobs {
					manifestJob, err := manifest.FindInstanceGroupJob(job.InstanceGroup, job.Name)
					Expect(err).NotTo(HaveOccurred())

					healthCheck, err := manifestJob.Property("cc/default_health_check_timeout")
					Expect(err).NotTo(HaveOccurred())

					Expect(healthCheck).To(Equal(60))
				}
			})
		})

		Context("when the Operator sets CC logging level to debug", func() {
			BeforeEach(func() {
				var err error
				manifest, err = product.RenderService.RenderManifest(map[string]interface{}{
					".properties.cc_logging_level": "debug",
				})
				Expect(err).NotTo(HaveOccurred())
			})

			It("configures logging level to debug", func() {
				for _, job := range ccJobs {
					manifestJob, err := manifest.FindInstanceGroupJob(job.InstanceGroup, job.Name)
					Expect(err).NotTo(HaveOccurred())

					loggingLevel, err := manifestJob.Property("cc/logging_level")
					Expect(err).NotTo(HaveOccurred())
					Expect(loggingLevel).To(Equal(string("debug")))
				}
			})
		})

		Context("when the Operator sets the Default Health Check Timeout", func() {
			BeforeEach(func() {
				var err error
				manifest, err = product.RenderService.RenderManifest(map[string]interface{}{
					".properties.cloud_controller_default_health_check_timeout": 120,
				})
				Expect(err).NotTo(HaveOccurred())
			})

			It("passes the value to CC jobs", func() {
				for _, job := range ccJobs {
					manifestJob, err := manifest.FindInstanceGroupJob(job.InstanceGroup, job.Name)
					Expect(err).NotTo(HaveOccurred())

					healthCheck, err := manifestJob.Property("cc/default_health_check_timeout")
					Expect(err).NotTo(HaveOccurred())

					Expect(healthCheck).To(Equal(120))
				}
			})
		})

		Context("when the Operator sets an Insecure Registry list", func() {
			BeforeEach(func() {
				var err error
				manifest, err = product.RenderService.RenderManifest(map[string]interface{}{
					".diego_cell.insecure_docker_registry_list": "item1,item2,item3",
				})
				Expect(err).NotTo(HaveOccurred())
			})

			It("passes the value to CC jobs", func() {
				for _, job := range ccJobs {
					manifestJob, err := manifest.FindInstanceGroupJob(job.InstanceGroup, job.Name)
					Expect(err).NotTo(HaveOccurred())

					insecureDockerRegistryList, err := manifestJob.Property("cc/diego/insecure_docker_registry_list")
					Expect(err).NotTo(HaveOccurred())

					Expect(insecureDockerRegistryList).To(Equal([]interface{}{"item1", "item2", "item3"}))
				}
			})
		})
	})
})
