.PHONY: echo-vars pull-images save-images pull-resources pull-configs pull-dashboards pull-rules package clean

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
	mkdir -p prometheus/resources/images
	docker save -o prometheus/resources/images/prometheus-$(PROMETHEUS_VERSION)-$(PLATFORM).tar prom/prometheus:$(PROMETHEUS_VERSION)

	mkdir -p grafana/resources/images
	docker save -o grafana/resources/images/grafana-$(GRAFANA_VERSION)-$(PLATFORM).tar grafana/grafana-oss:$(GRAFANA_VERSION)

	mkdir -p node-exporter/resources/images
	docker save -o node-exporter/resources/images/node-exporter-$(NODE_EXPORTER_VERSION)-$(PLATFORM).tar prom/node-exporter:$(NODE_EXPORTER_VERSION)

pull-resources: pull-configs pull-dashboards pull-rules

pull-configs: echo-vars
	mkdir -p prometheus/resources/configs
	wget https://raw.githubusercontent.com/prometheus/prometheus/$(PROMETHEUS_VERSION)/documentation/examples/prometheus.yml -O prometheus/resources/configs/prometheus.yml

	mkdir -p grafana/resources/configs
	wget https://raw.githubusercontent.com/grafana/grafana/v$(GRAFANA_VERSION)/conf/sample.ini -O grafana/resources/configs/sample.ini

pull-dashboards:
	mkdir -p grafana/resources/dashboards
	wget https://grafana.com/api/dashboards/3662/revisions/2/download -O grafana/resources/dashboards/prometheus.json
	wget https://grafana.com/api/dashboards/3590/revisions/3/download -O grafana/resources/dashboards/grafana.json
	wget https://grafana.com/api/dashboards/1860/revisions/36/download -O grafana/resources/dashboards/node-exporter.json

pull-rules:
	mkdir -p prometheus/resources/rules
	wget https://raw.githubusercontent.com/rea1shane/monitor/main/rules/prometheus.yml -O prometheus/resources/rules/prometheus.yml
	wget https://raw.githubusercontent.com/rea1shane/monitor/main/rules/node.yml -O prometheus/resources/rules/node.yml

package: clean save-images pull-resources
	mkdir -p monitor
	rsync -av --exclude='.git*' --exclude='Makefile' --exclude='monitor' --exclude='.DS_Store' . monitor
	zip -r monitor.zip monitor

clean:
	rm -rf */resources
	rm -rf monitor*
