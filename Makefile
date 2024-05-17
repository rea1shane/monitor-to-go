.PHONY: echo-vars pull-images save-images pull-resources pull-configs pull-dashboards pull-rules package clean

PLATFORM = amd64

PROMETHEUS__VERSION = $(shell cat prometheus/.env | grep -oE 'PROMETHEUS__VERSION=[^ ]+' | cut -d= -f2)
PROMETHEUS__PORT = $(shell cat prometheus/.env | grep -oE 'PROMETHEUS__PORT=[^ ]+' | cut -d= -f2)

GRAFANA__VERSION = $(shell cat grafana/.env | grep -oE 'GRAFANA__VERSION=[^ ]+' | cut -d= -f2)
GRAFANA__PORT = $(shell cat grafana/.env | grep -oE 'GRAFANA__PORT=[^ ]+' | cut -d= -f2)

NODE_EXPORTER__VERSION = $(shell cat node_exporter/.env | grep -oE 'NODE_EXPORTER__VERSION=[^ ]+' | cut -d= -f2)
NODE_EXPORTER__PORT = $(shell cat node_exporter/.env | grep -oE 'NODE_EXPORTER__PORT=[^ ]+' | cut -d= -f2)

echo-vars:
	@echo Platform:              $(PLATFORM)
	@echo Prometheus version:    $(PROMETHEUS__VERSION)
	@echo Prometheus port:       $(PROMETHEUS__PORT)
	@echo Grafana version:       $(GRAFANA__VERSION)
	@echo Grafana port:          $(GRAFANA__PORT)
	@echo Node exporter version: $(NODE_EXPORTER__VERSION)
	@echo Node exporter port:    $(NODE_EXPORTER__PORT)

pull-images: echo-vars
	docker pull --platform $(PLATFORM) prom/prometheus:$(PROMETHEUS__VERSION)
	docker pull --platform $(PLATFORM) grafana/grafana-oss:$(GRAFANA__VERSION)
	docker pull --platform $(PLATFORM) prom/node-exporter:$(NODE_EXPORTER__VERSION)

save-images: pull-images
	mkdir -p prometheus/resources/images
	docker save -o prometheus/resources/images/prometheus-$(PROMETHEUS__VERSION)-$(PLATFORM).tar prom/prometheus:$(PROMETHEUS__VERSION)

	mkdir -p grafana/resources/images
	docker save -o grafana/resources/images/grafana-$(GRAFANA__VERSION)-$(PLATFORM).tar grafana/grafana-oss:$(GRAFANA__VERSION)

	mkdir -p node_exporter/resources/images
	docker save -o node_exporter/resources/images/node_exporter-$(NODE_EXPORTER__VERSION)-$(PLATFORM).tar prom/node-exporter:$(NODE_EXPORTER__VERSION)

pull-resources: pull-configs pull-dashboards pull-rules

pull-configs: echo-vars
	mkdir -p prometheus/resources/configs
	wget https://raw.githubusercontent.com/prometheus/prometheus/$(PROMETHEUS__VERSION)/documentation/examples/prometheus.yml -O prometheus/resources/configs/prometheus.yml

	mkdir -p grafana/resources/configs
	wget https://raw.githubusercontent.com/grafana/grafana/v$(GRAFANA__VERSION)/conf/sample.ini -O grafana/resources/configs/sample.ini

pull-dashboards:
	mkdir -p grafana/resources/dashboards
	wget https://grafana.com/api/dashboards/3662/revisions/2/download -O grafana/resources/dashboards/prometheus.json
	wget https://grafana.com/api/dashboards/3590/revisions/3/download -O grafana/resources/dashboards/grafana.json
	wget https://grafana.com/api/dashboards/1860/revisions/36/download -O grafana/resources/dashboards/node_exporter.json

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
