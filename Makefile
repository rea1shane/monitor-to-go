.PHONY: echo-vars pull-images save-images pull-configs

PLATFORM = amd64

PROMETHEUS_VERSION = $(shell cat prometheus/.env | grep -oE 'PROMETHEUS_VERSION=[^ ]+' | cut -d= -f2)
GRAFANA_VERSION = $(shell cat grafana/.env | grep -oE 'GRAFANA_VERSION=[^ ]+' | cut -d= -f2)
NODE_EXPORTER_VERSION = $(shell cat node-exporter/.env | grep -oE 'NODE_EXPORTER_VERSION=[^ ]+' | cut -d= -f2)

echo-vars:
	@echo Platform:              $(PLATFORM)
	@echo Prometheus version:    $(PROMETHEUS_VERSION)
	@echo Grafana version:       $(GRAFANA_VERSION)
	@echo Node exporter version: $(NODE_EXPORTER_VERSION)

pull-images: echo-vars
	docker pull --platform $(PLATFORM) prom/prometheus:$(PROMETHEUS_VERSION)
	docker pull --platform $(PLATFORM) grafana/grafana-oss:$(GRAFANA_VERSION)
	docker pull --platform $(PLATFORM) prom/node-exporter:$(NODE_EXPORTER_VERSION)

save-images: pull-images
	docker save -o images-$(PLATFORM)+prometheus:$(PROMETHEUS_VERSION)+grafana-oss:$(GRAFANA_VERSION)+node-exporter:$(NODE_EXPORTER_VERSION).tar \
		prom/prometheus:$(PROMETHEUS_VERSION) \
		grafana/grafana-oss:$(GRAFANA_VERSION) \
		prom/node-exporter:$(NODE_EXPORTER_VERSION)

pull-configs: echo-vars
	wget https://raw.githubusercontent.com/prometheus/prometheus/$(PROMETHEUS_VERSION)/documentation/examples/prometheus.yml -O prometheus/prometheus.yml
	wget https://raw.githubusercontent.com/grafana/grafana/v$(GRAFANA_VERSION)/conf/sample.ini -O grafana/sample.ini
