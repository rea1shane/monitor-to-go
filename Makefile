.PHONY: echo-vars pull-images save-images pull-resources pull-configs pull-dashboards

PLATFORM = amd64

PROMETHEUS_VERSION = $(shell cat prometheus/.env | grep -oE 'PROMETHEUS_VERSION=[^ ]+' | cut -d= -f2)
PROMETHEUS_PORT = $(shell cat prometheus/.env | grep -oE 'PROMETHEUS_PORT=[^ ]+' | cut -d= -f2)

GRAFANA_VERSION = $(shell cat grafana/.env | grep -oE 'GRAFANA_VERSION=[^ ]+' | cut -d= -f2)
GRAFANA_PORT = $(shell cat grafana/.env | grep -oE 'GRAFANA_PORT=[^ ]+' | cut -d= -f2)

NODE_EXPORTER_VERSION = $(shell cat node-exporter/.env | grep -oE 'NODE_EXPORTER_VERSION=[^ ]+' | cut -d= -f2)
NODE_EXPORTER_PORT = $(shell cat node-exporter/.env | grep -oE 'NODE_EXPORTER_PORT=[^ ]+' | cut -d= -f2)

echo-vars:
	@echo Platform:              $(PLATFORM)
	@echo Prometheus version:    $(PROMETHEUS_VERSION)
	@echo Prometheus port:       $(PROMETHEUS_PORT)
	@echo Grafana version:       $(GRAFANA_VERSION)
	@echo Grafana port:          $(GRAFANA_PORT)
	@echo Node exporter version: $(NODE_EXPORTER_VERSION)
	@echo Node exporter port:    $(NODE_EXPORTER_PORT)

pull-images: echo-vars
	docker pull --platform $(PLATFORM) prom/prometheus:$(PROMETHEUS_VERSION)
	docker pull --platform $(PLATFORM) grafana/grafana-oss:$(GRAFANA_VERSION)
	docker pull --platform $(PLATFORM) prom/node-exporter:$(NODE_EXPORTER_VERSION)

save-images: pull-images
	docker save -o images-$(PLATFORM)+prometheus:$(PROMETHEUS_VERSION)+grafana-oss:$(GRAFANA_VERSION)+node-exporter:$(NODE_EXPORTER_VERSION).tar \
		prom/prometheus:$(PROMETHEUS_VERSION) \
		grafana/grafana-oss:$(GRAFANA_VERSION) \
		prom/node-exporter:$(NODE_EXPORTER_VERSION)

pull-resources: pull-configs pull-dashboards

pull-configs: echo-vars
	wget https://raw.githubusercontent.com/prometheus/prometheus/$(PROMETHEUS_VERSION)/documentation/examples/prometheus.yml -O prometheus/prometheus.yml
	wget https://raw.githubusercontent.com/grafana/grafana/v$(GRAFANA_VERSION)/conf/sample.ini -O grafana/sample.ini

pull-dashboards:
	mkdir -p dashboards
	wget https://grafana.com/api/dashboards/3662/revisions/2/download -O dashboards/prometheus.json
	wget https://grafana.com/api/dashboards/3590/revisions/3/download -O dashboards/grafana.json
	wget https://grafana.com/api/dashboards/1860/revisions/36/download -O dashboards/node-exporter.json